import 'dart:math';
import 'dart:async';
import 'dart:convert';
import 'package:media_core/media_core.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/player/models/player_engine.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/modules/vod/domain/providers/vod_providers.dart';
import 'package:pure_live/modules/vod/domain/repositories/music_vod_repository.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';
import 'package:pure_live/modules/vod/controllers/vod_playback_core.dart';
import 'package:pure_live/modules/vod/controllers/video_player_controller.dart';

part 'music_player_controller.g.dart';

/// What the queue UI reads. Playback position and buffering live on the
/// [PlayerHandle] streams instead — they change many times a second and must
/// not rebuild every queue tile.
class MusicPlayerState {
  const MusicPlayerState({
    this.queue = const [],
    this.index = -1,
    this.mode = MusicPlayMode.sequence,
    // Music listens (cover art only) by default; the MV mode turns the picture
    // on through [MusicPlayerController.toggleAudioOnly].
    this.audioOnly = true,
    this.resolving = false,
    this.quality = 0,
    this.speed = 1.0,
    this.qualityOptions = const [],
    this.error = '',
    this.tempQueue = const [],
    this.sleepMinutes = 0,
  });

  final List<MusicTrack> queue;
  final int index;
  final MusicPlayMode mode;
  final bool audioOnly;
  final bool resolving;

  /// Quality id of the stream currently open (0 = none).
  final int quality;

  /// Playback rate of the current handle. Music has no rate UI, so this stays
  /// 1.0; it is carried only so the resume snapshot round-trips faithfully.
  final double speed;

  /// Quality tiers the current stream answer can serve, for the control bar's
  /// quality panel.
  final List<MusicStreamOption> qualityOptions;
  final String error;

  /// The "play later" strip (the lx tempPlayList): consumed by [next] ahead of
  /// the queue's own order, and never reordered by queue edits.
  final List<MusicTrack> tempQueue;

  /// Minutes left on the sleep timer, or 0 when none is armed. The number is
  /// the armed length, not a live countdown — the UI reads it for the tile
  /// subtitle only.
  final int sleepMinutes;

  MusicTrack? get current => index >= 0 && index < queue.length ? queue[index] : null;

  bool get hasQueue => queue.isNotEmpty;

  MusicPlayerState copyWith({
    List<MusicTrack>? queue,
    int? index,
    MusicPlayMode? mode,
    bool? audioOnly,
    bool? resolving,
    int? quality,
    double? speed,
    List<MusicStreamOption>? qualityOptions,
    String? error,
    List<MusicTrack>? tempQueue,
    int? sleepMinutes,
  }) {
    return MusicPlayerState(
      queue: queue ?? this.queue,
      index: index ?? this.index,
      mode: mode ?? this.mode,
      audioOnly: audioOnly ?? this.audioOnly,
      resolving: resolving ?? this.resolving,
      quality: quality ?? this.quality,
      speed: speed ?? this.speed,
      qualityOptions: qualityOptions ?? this.qualityOptions,
      error: error ?? this.error,
      tempQueue: tempQueue ?? this.tempQueue,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
    );
  }
}

/// The music-mode player: a track queue, the advance rules and the listening
/// extras (play-later strip, sleep timer, resume snapshot, recently played).
///
/// Playback runs on its OWN [PlayerHandle] through [VodPlaybackCore], separate
/// from the video player's handle, so a video never replaces the music queue
/// and never reads back as the current song. Deliberately not the live facade:
/// that path is tuned for non-seekable streams and lease renewal, while VOD
/// needs the seek, position and duration the raw handle already carries.
@Riverpod(keepAlive: true)
class MusicPlayerController extends _$MusicPlayerController {
  late final VodPlaybackCore _core = VodPlaybackCore(configName: 'music');

  /// Stops the auto-advance when every track fails in a row.
  int _consecutiveFailures = 0;

  final Random _random = Random();

  /// Track ids played since random mode was (re)armed, in play order.
  /// [next] appends the track it leaves; [previous] walks back through it.
  final List<String> _randomHistory = <String>[];

  // ------------------------------------------------------------------ sleep timer

  /// The armed countdown; null while no sleep timer runs.
  Timer? _sleepTimer;

  /// Set when the countdown expired under "finish the current track": the
  /// next completion pauses instead of advancing.
  bool _sleepAfterTrack = false;

  /// Hive switch read when the countdown expires.
  static const String _sleepFinishCurrentKey = 'musicSleepFinishCurrent';

  // ------------------------------------------------------------- last session

  /// Hive key of the queue snapshot the resume option restores.
  static const String _sessionKey = 'musicLastSession';

  /// The engine the music player asks the kernel for, persisted across
  /// sessions and switchable from the play page's dialog. The default is the
  /// same engine every music session has used.
  static String _preferredBackend = HivePrefUtil.getString('musicBackend') ?? BackendIds.mediaKit;
  static String get preferredBackend => _preferredBackend;

  /// Plays the current track through [backendId], from the position playing
  /// now. A track that is not open just records the choice for the next open.
  Future<void> switchBackend(String backendId) async {
    if (backendId == _preferredBackend) return;
    _preferredBackend = backendId;
    HivePrefUtil.setString('musicBackend', backendId);

    // The open below must build the new engine: the old handle belongs to the
    // old one. The position is read before it goes away.
    final position = _core.handle?.position ?? Duration.zero;
    final bvid = _core.currentBvid;
    await _core.releaseHandle();
    final track = state.current;
    if (track == null || bvid == null) return;

    // Re-resolve rather than replay the stored answer: its signed URL may be
    // near expiry, and the new backend wants a fresh stream anyway.
    try {
      final urls = await _api.getPlayUrls(bvid: bvid, cid: track.part.cid);
      await _core.openUrls(
        track: track,
        urls: urls,
        bvid: bvid,
        audioOnly: state.audioOnly,
        speed: state.speed,
        preferredBackend: backendId,
      );
      state = state.copyWith(quality: urls.quality, qualityOptions: urls.videoOptions);
    } catch (_) {
      return;
    }
    await _core.restorePosition(position);
  }

  /// The resume option fires once per app run, on the music pane's first build.
  bool _resumeAttempted = false;

  /// Keeps the saved position fresh while a track is playing: a force-kill
  /// then replays at most one heartbeat interval.
  Timer? _sessionHeartbeat;

  void _ensureSessionHeartbeat() {
    _sessionHeartbeat ??= Timer.periodic(const Duration(seconds: 10), (_) {
      final handle = _core.handle;
      if (handle != null && handle.isPlaying && state.hasQueue) _persistSession();
    });
  }

  /// Snapshots queue, current index, rate and position into Hive.
  ///
  /// Archives are stored deduped (a 20-part album is one archive entry) and the
  /// queue order as `bvid#page` refs, so restoring rebuilds every track from
  /// its archive's part list.
  void _persistSession() {
    try {
      final queue = state.queue;
      if (queue.isEmpty) return;
      final archives = <String, MusicArchive>{};
      final order = <String>[];
      for (final track in queue) {
        archives[track.archive.bvid] = track.archive;
        order.add('${track.archive.bvid}#${track.part.page}');
      }
      // The play-later strip rides along too: its tracks must survive an app
      // restart, and their archives may exist nowhere else.
      final tempOrder = <String>[];
      for (final track in state.tempQueue) {
        archives[track.archive.bvid] = track.archive;
        tempOrder.add('${track.archive.bvid}#${track.part.page}');
      }
      HivePrefUtil.setString(
        _sessionKey,
        jsonEncode({
          'archives': [for (final archive in archives.values) archive.toJson()],
          'order': order,
          'temp': tempOrder,
          'index': state.index < 0 ? 0 : state.index,
          'speed': state.speed,
          'positionMs': _core.handle?.position.inMilliseconds ?? 0,
        }),
      );
    } catch (_) {
      // A failed snapshot only costs the resume convenience.
    }
  }

  ({List<MusicTrack> tracks, List<MusicTrack> temp, int index, double speed, Duration position})? _loadSession() {
    try {
      final raw = HivePrefUtil.getString(_sessionKey);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final archives = <String, MusicArchive>{
        for (final entry in (json['archives'] as List?) ?? const <dynamic>[])
          if (entry is Map<String, dynamic>) entry['bvid']?.toString() ?? '': MusicArchive.fromJson(entry),
      };
      List<MusicTrack> decodeOrder(dynamic refs) {
        final tracks = <MusicTrack>[];
        for (final ref in (refs as List?) ?? const <dynamic>[]) {
          final parts = ref?.toString().split('#');
          if (parts == null || parts.length != 2) continue;
          final archive = archives[parts[0]];
          if (archive == null) continue;
          final page = int.tryParse(parts[1]) ?? 1;
          final part =
              archive.parts.where((p) => p.page == page).firstOrNull ??
              (archive.parts.isEmpty ? null : archive.parts.first);
          if (part == null) continue;
          tracks.add(MusicTrack(archive: archive, part: part));
        }
        return tracks;
      }
      final tracks = decodeOrder(json['order']);
      if (tracks.isEmpty) return null;
      final temp = decodeOrder(json['temp']);
      final index = (int.tryParse(json['index']?.toString() ?? '') ?? 0).clamp(0, tracks.length - 1);
      final speed = double.tryParse(json['speed']?.toString() ?? '') ?? 1.0;
      final position = Duration(milliseconds: int.tryParse(json['positionMs']?.toString() ?? '') ?? 0);
      return (tracks: tracks, temp: temp, index: index, speed: speed, position: position);
    } catch (_) {
      return null;
    }
  }

  /// Restores the last session when the music setting asks for it and nothing
  /// plays yet: rebuilds the saved queue, reopens the current track and seeks
  /// to the stored position.
  Future<void> maybeResumeLastSession() async {
    if (_resumeAttempted) return;
    _resumeAttempted = true;
    if (HivePrefUtil.getString('musicResumeOnOpen') != 'true') return;
    if (state.hasQueue || _core.handle != null) return;
    final session = _loadSession();
    if (session == null) return;
    state = state.copyWith(
      queue: List.unmodifiable(session.tracks),
      index: session.index,
      speed: session.speed,
      tempQueue: List.unmodifiable(session.temp),
      error: '',
    );
    await _openCurrent(session.position);
  }

  @override
  MusicPlayerState build() {
    _core.onAdapterEvent = _onAdapterEvent;
    ref.onDispose(() {
      _core.releaseHandle();
      _sleepTimer?.cancel();
      _sleepTimer = null;
    });
    // Music-mode defaults from the music settings section: the play mode and
    // the audio-only preference the user picked rule until they change them.
    final savedMode = MusicPlayMode.values
        .where((m) => m.name == HivePrefUtil.getString('musicDefaultPlayMode'))
        .firstOrNull;
    final savedAudioOnly = HivePrefUtil.getString('musicDefaultAudioOnly') != 'false';
    return MusicPlayerState(mode: savedMode ?? MusicPlayMode.sequence, audioOnly: savedAudioOnly);
  }

  MusicVodRepository get _api => ref.read(musicRepositoryProvider);

  /// The handle the player page renders; null while idle or resolving.
  PlayerHandle? get handle => _core.handle;

  /// Live playback state for the progress bar; null while idle.
  Stream<PlayerTransportState>? get playbackStream => _core.playbackStream;

  // ------------------------------------------------------------- queue input

  /// Replaces the queue and starts at [startIndex]. [audioOnly] seeds the
  /// listening style: music pages keep the default (cover-art listening).
  Future<void> playQueue(List<MusicTrack> tracks, {int startIndex = 0, bool? audioOnly}) async {
    if (tracks.isEmpty) return;
    final index = startIndex.clamp(0, tracks.length - 1);
    _randomHistory.clear();
    state = state.copyWith(
      queue: List.unmodifiable(tracks),
      index: index,
      error: '',
      audioOnly: audioOnly,
      qualityOptions: const [],
      tempQueue: const [],
    );
    await _openCurrent();
  }

  /// queue at all the track starts playing by itself. A track already sitting
  /// in the next slot reports and does nothing.
  Future<void> playNext(MusicTrack track) async {
    if (state.queue.isEmpty) {
      await playQueue([track]);
      return;
    }
    final queue = List<MusicTrack>.from(state.queue);
    final existing = queue.indexWhere((t) => t.id == track.id);
    if (existing >= 0) {
      if (existing == state.index + 1) {
        ToastUtil.show(i18n('music_already_next'));
        return;
      }
      queue.removeAt(existing);
      var insertAt = state.index + 1;
      if (existing < state.index) insertAt -= 1;
      queue.insert(insertAt.clamp(0, queue.length), track);
      state = state.copyWith(queue: List.unmodifiable(queue));
      ToastUtil.show(i18n('music_set_next'));
      return;
    }
    queue.insert((state.index + 1).clamp(0, queue.length), track);
    state = state.copyWith(queue: List.unmodifiable(queue));
    ToastUtil.show(i18n('music_set_next'));
  }

  /// Jumps within the current queue.
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= state.queue.length || index == state.index) return;
    state = state.copyWith(index: index, error: '');
    await _openCurrent();
  }

  /// Enqueues behind the current track (or starts the queue when idle).
  Future<void> enqueue(MusicTrack track) async {
    final queue = List<MusicTrack>.from(state.queue);
    final existing = queue.indexWhere((t) => t.id == track.id);
    if (existing >= 0) {
      ToastUtil.show(i18n('music_already_in_queue'));
      return;
    }
    queue.add(track);
    if (state.index < 0) {
      state = state.copyWith(queue: List.unmodifiable(queue), index: queue.length - 1, error: '');
      await _openCurrent();
    } else {
      state = state.copyWith(queue: List.unmodifiable(queue));
    }
  }

  Future<void> removeAt(int index) async {
    final queue = List<MusicTrack>.from(state.queue);
    if (index < 0 || index >= queue.length) return;
    final wasCurrent = index == state.index;
    queue.removeAt(index);
    var nextIndex = state.index;
    if (wasCurrent) {
      // Removing the playing track advances to the one that took its slot.
      nextIndex = queue.isEmpty ? -1 : index.clamp(0, queue.length - 1);
      state = state.copyWith(queue: List.unmodifiable(queue), index: nextIndex);
      if (queue.isEmpty) {
        await stop();
      } else {
        await _openCurrent();
      }
      return;
    }
    if (index < state.index) nextIndex -= 1;
    state = state.copyWith(queue: List.unmodifiable(queue), index: nextIndex);
  }

  // ------------------------------------------------------------- play-later

  /// Adds tracks to the "play later" strip (the lx tempPlayList): they leave
  /// the queue (no double slot) and [next] consumes the strip, in order,
  /// before the queue's own advance rules. The playing track is skipped — it
  /// owns neither a queue slot to free nor a strip slot.
  void playLater(List<MusicTrack> tracks) {
    final queue = List<MusicTrack>.from(state.queue);
    final temp = List<MusicTrack>.from(state.tempQueue);
    final known = <String>{...temp.map((t) => t.id)};
    final currentId = state.current?.id;
    var added = 0;
    for (final track in tracks) {
      if (track.id == currentId || known.contains(track.id)) continue;
      final at = queue.indexWhere((t) => t.id == track.id);
      final effective = at >= 0 ? queue.removeAt(at) : track;
      temp.add(effective);
      known.add(effective.id);
      added++;
    }
    if (added == 0) return;
    // Removals before the playing slot shift it; re-derive it by id.
    var index = state.index;
    if (currentId != null) {
      final at = queue.indexWhere((t) => t.id == currentId);
      if (at >= 0) index = at;
    }
    state = state.copyWith(queue: List.unmodifiable(queue), index: index, tempQueue: List.unmodifiable(temp));
    ToastUtil.show(added > 1 ? '${i18n('music_play_later_added')} ×$added' : i18n('music_play_later_added'));
  }

  // ------------------------------------------------------------- batch edits

  /// Removes every listed track in one state write (the multi-select batch op).
  Future<void> removeIds(Set<String> ids) async {
    if (ids.isEmpty) return;
    final currentId = state.current?.id;
    final queue = List<MusicTrack>.from(state.queue)..removeWhere((t) => ids.contains(t.id));
    if (queue.isEmpty) {
      await stop();
      return;
    }
    final removedCurrent = currentId != null && ids.contains(currentId);
    var index = state.index;
    if (!removedCurrent && currentId != null) {
      final at = queue.indexWhere((t) => t.id == currentId);
      if (at >= 0) index = at;
    } else {
      index = index.clamp(0, queue.length - 1);
    }
    state = state.copyWith(queue: List.unmodifiable(queue), index: index);
    if (removedCurrent) await _openCurrent();
  }

  /// Moves every listed track to the marked position (the multi-select
  /// "move here"), keeping their relative order. [targetIndex] is the marker's
  /// index in the CURRENT queue; the block lands where it points after the
  /// moved entries are lifted out.
  void moveIds(Set<String> ids, int targetIndex) {
    if (ids.isEmpty || ids.length >= state.queue.length) return;
    final moved = <MusicTrack>[];
    final rest = <MusicTrack>[];
    var movedBefore = 0;
    for (var i = 0; i < state.queue.length; i++) {
      final track = state.queue[i];
      if (ids.contains(track.id)) {
        moved.add(track);
        if (i < targetIndex) movedBefore++;
      } else {
        rest.add(track);
      }
    }
    if (moved.isEmpty || rest.isEmpty) return;
    final insertAt = (targetIndex - movedBefore).clamp(0, rest.length);
    final queue = List<MusicTrack>.unmodifiable(<MusicTrack>[...rest.sublist(0, insertAt), ...moved, ...rest.sublist(insertAt)]);
    final currentId = state.current?.id;
    final index = queue.indexWhere((t) => t.id == currentId);
    state = state.copyWith(queue: queue, index: index < 0 ? state.index.clamp(0, queue.length - 1) : index);
    ToastUtil.show(i18n('music_queue_moved'));
  }

  // ------------------------------------------------------------- advance rules

  Future<void> next() async {
    // The play-later strip owns the next slot before the queue's own rules.
    if (state.tempQueue.isNotEmpty) {
      final upNext = state.tempQueue.first;
      state = state.copyWith(tempQueue: List.unmodifiable(state.tempQueue.sublist(1)));
      final queue = List<MusicTrack>.from(state.queue);
      final existing = queue.indexWhere((t) => t.id == upNext.id);
      var insertAt = (state.index + 1).clamp(0, queue.length);
      if (existing >= 0) {
        queue.removeAt(existing);
        if (existing < insertAt) insertAt -= 1;
      }
      queue.insert(insertAt.clamp(0, queue.length), upNext);
      state = state.copyWith(queue: List.unmodifiable(queue));
      await jumpTo(insertAt.clamp(0, queue.length - 1));
      return;
    }
    final queue = state.queue;
    if (queue.isEmpty) return;
    var target = state.index;
    switch (state.mode) {
      case MusicPlayMode.random:
        if (queue.length > 1) {
          final picked = _pickRandomTarget();
          if (picked == null) return;
          _randomHistory.add(queue[state.index].id);
          target = picked;
        }
      case MusicPlayMode.sequence:
      case MusicPlayMode.loopOne:
        // Manual next always moves, even under Repeat one.
        target = (state.index + 1) % queue.length;
      case MusicPlayMode.orderStop:
        if (state.index >= queue.length - 1) return;
        target = state.index + 1;
    }
    await jumpTo(target);
  }

  /// The next random pick: an unplayed entry when one exists, else the first
  /// draw of a fresh round (the whole shuffled pass replays, lx-style). Answers
  /// null only when there is nowhere to go.
  int? _pickRandomTarget() {
    final queue = state.queue;
    final played = _randomHistory.toSet();
    final candidates = <int>[
      for (var i = 0; i < queue.length; i++)
        if (i != state.index && !played.contains(queue[i].id)) i,
    ];
    if (candidates.isEmpty) {
      _randomHistory.clear();
      final others = <int>[for (var i = 0; i < queue.length; i++) if (i != state.index) i];
      if (others.isEmpty) return null;
      return others[_random.nextInt(others.length)];
    }
    return candidates[_random.nextInt(candidates.length)];
  }

  Future<void> previous() async {
    final queue = state.queue;
    if (queue.isEmpty) return;
    // A track more than a few seconds in restarts instead of skipping back —
    // the music-player convention.
    final handle = _core.handle;
    if (handle != null && handle.position > const Duration(seconds: 5)) {
      await VodPlaybackCore.ignoreCancelled(() => handle.seek(Duration.zero));
      if (!handle.isPlaying) await VodPlaybackCore.ignoreCancelled(handle.play);
      return;
    }
    // Random walks back through the shuffled order: the history entries leave
    // the record as they are revisited, so forward from there reshuffles only
    // what was undone.
    if (state.mode == MusicPlayMode.random && _randomHistory.isNotEmpty) {
      final currentId = queue[state.index].id;
      while (_randomHistory.isNotEmpty) {
        final id = _randomHistory.removeLast();
        if (id == currentId) continue;
        final at = queue.indexWhere((t) => t.id == id);
        if (at < 0) continue;
        await jumpTo(at);
        return;
      }
    }
    await jumpTo((state.index - 1 + queue.length) % queue.length);
  }

  Future<void> cycleMode() async {
    setPlayMode(state.mode.next);
    ToastUtil.show(i18n(state.mode.i18nKey));
  }

  void setPlayMode(MusicPlayMode mode) {
    if (state.mode == mode) return;
    // The random pass is per-mode state: re-arming random starts a fresh
    // shuffle, leaving it drops the half-walked history.
    _randomHistory.clear();
    state = state.copyWith(mode: mode);
  }

  /// Set when the player page exits with the picture on: the Flutter side
  /// tears its texture down while mpv keeps decoding into the output it lost
  /// track of, so the NEXT page mount shows black until the video output is
  /// rebuilt. [reattachVideoSurface] does that rebuild — the same vid=no →
  /// vid=yes toggle the open path runs for a picture session.
  bool videoSurfaceNeedsReattach = false;

  /// Forces mpv to rebuild its video output against the freshly mounted
  /// surface: dropping and restoring the video track re-creates the decoder's
  /// output with the live texture. Harmless when nothing is wrong.
  Future<void> reattachVideoSurface() async {
    final handle = _core.handle;
    if (handle == null) return;
    try {
      await handle.setAudioOnly(true);
    } catch (_) {}
    try {
      await handle.setAudioOnly(false);
    } catch (_) {}
  }

  /// Re-opens the current stream at [quality] from the rendition list the last
  /// answer shipped — no new API request, just a fresh mpv load.
  Future<void> switchQuality(int quality) async {
    final urls = _core.currentUrls;
    final bvid = _core.currentBvid;
    if (urls == null || bvid == null || quality == state.quality) return;
    final option = urls.videoOptions.where((o) => o.quality == quality).firstOrNull;
    if (option == null || option.url.isEmpty) return;
    final track = state.current;
    if (track == null) return;

    state = state.copyWith(quality: quality, resolving: true);
    try {
      await _core.openUrls(
        track: track,
        urls: MusicPlayUrls(
          videoUrl: option.url,
          audioUrl: urls.audioUrl,
          videoBackupUrls: option.backupUrls,
          quality: quality,
          videoOptions: urls.videoOptions,
        ),
        bvid: bvid,
        audioOnly: state.audioOnly,
        speed: state.speed,
        preferredBackend: _preferredBackend,
      );
      state = state.copyWith(resolving: false);
    } catch (error) {
      state = state.copyWith(resolving: false, error: error.toString());
      ToastUtil.show(i18n('music_play_failed'));
    }
  }

  // ------------------------------------------------------------- transport

  Future<void> togglePlayPause() async {
    final handle = _core.handle;
    if (handle == null) {
      // The stream is gone (stopped, or another session took the speakers) but
      // the queue survived: reopening the current track resumes from it.
      if (state.hasQueue) await _openCurrent();
      return;
    }
    if (handle.isPlaying) {
      await handle.pause();
      // Paused is where a session is usually left: snapshot the position now.
      _persistSession();
    } else {
      await VodPlaybackCore.ignoreCancelled(handle.play);
    }
  }

  Future<void> seekTo(Duration position) async {
    final handle = _core.handle;
    if (handle == null) return;
    final duration = handle.duration;
    var target = position;
    if (duration > Duration.zero) {
      if (target < Duration.zero) target = Duration.zero;
      if (target > duration) target = duration;
    }
    await VodPlaybackCore.ignoreCancelled(() => handle.seek(target));
    _persistSession();
  }

  Future<void> seekBy(int seconds) async {
    final handle = _core.handle;
    if (handle == null) return;
    await seekTo(handle.position + Duration(seconds: seconds));
  }

  /// Seek with newBV's press acceleration: repeated presses inside 200ms grow
  /// the step from 10s up to 60s, so a long skip needs no dozen presses.
  DateTime _accelLastAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _accelStep = 10;

  Future<void> seekAccelerated(int direction) async {
    final now = DateTime.now();
    _accelStep = now.difference(_accelLastAt) < const Duration(milliseconds: 200) ? (_accelStep + 5).clamp(10, 60) : 10;
    _accelLastAt = now;
    await seekBy(direction * _accelStep);
  }

  Future<void> toggleAudioOnly() async {
    final audioOnly = !state.audioOnly;
    final handle = _core.handle;
    state = state.copyWith(audioOnly: audioOnly);

    try {
      await handle?.setAudioOnly(audioOnly);
    } catch (_) {
      state = state.copyWith(audioOnly: !audioOnly);
    }
  }

  Future<void> stop() async {
    _core.bumpGeneration();
    await _core.releaseHandle();
    _core.currentUrls = null;
    _core.currentBvid = null;
    _randomHistory.clear();
    // The queue is gone but the listening preferences survive the session.
    state = MusicPlayerState(
      mode: state.mode,
      audioOnly: state.audioOnly,
      speed: state.speed,
      sleepMinutes: state.sleepMinutes,
    );
  }

  // ------------------------------------------------------------- sleep timer

  /// Arms (or with [minutes] <= 0 disarms) the countdown to the music player.
  /// When it expires, either playback pauses at once or — with the
  /// "finish the current track" setting on — the running track is allowed to
  /// end and the pause happens there.
  void setSleepTimer(int minutes) {
    _sleepTimer?.cancel();
    _sleepTimer = null;
    _sleepAfterTrack = false;
    if (minutes <= 0) {
      state = state.copyWith(sleepMinutes: 0);
      return;
    }
    state = state.copyWith(sleepMinutes: minutes);
    _sleepTimer = Timer(Duration(minutes: minutes), _onSleepDue);
    ToastUtil.show('${i18n('music_sleep_armed')} · $minutes ${i18n('music_sleep_minutes_unit')}');
  }

  void _onSleepDue() {
    _sleepTimer = null;
    if (HivePrefUtil.getString(_sleepFinishCurrentKey) == 'true') {
      _sleepAfterTrack = true;
      ToastUtil.show(i18n('music_sleep_wait_track'));
      return;
    }
    state = state.copyWith(sleepMinutes: 0);
    final handle = _core.handle;
    if (handle != null) {
      unawaited(
        VodPlaybackCore.ignoreCancelled(() async {
          if (handle.isPlaying) await handle.pause();
        }),
      );
    }
    ToastUtil.show(i18n('music_sleep_stopped'));
  }

  /// Another session (live or video) takes the speakers: the open stream is
  /// dropped but the queue and the track pointer survive, so returning to the
  /// music tab can resume from the queue. Cheaper than [stop] and repeatable —
  /// every live channel switch and every video open calls it.
  Future<void> suspend() async {
    if (_core.handle == null && !state.hasQueue) return;
    // Snapshot before the handle goes away: the other session then owns the
    // speakers with the last music position still on record.
    _persistSession();
    _core.bumpGeneration();
    await _core.releaseHandle();
    state = state.copyWith(resolving: false, quality: 0);
  }

  // ------------------------------------------------------------- internals

  /// Opens the current queue entry. [startAt] is the resume position the
  /// last-session restore asks for; a plain track start opens from zero.
  Future<void> _openCurrent([Duration? startAt]) async {
    final generation = _core.bumpGeneration();
    final track = state.current;
    if (track == null) return;

    state = state.copyWith(resolving: true, error: '');

    try {
      // The music session owns the speakers from here on: pause live, and
      // suspend any open video (its page keeps its list, drops the handle).
      // Pausing (not stopping) keeps both resumable.
      unawaited(GlobalPlayerService.instance.livePlayer?.pause().catchError((Object _) {}));
      unawaited(ref.read(videoPlayerControllerProvider.notifier).suspend().catchError((Object _) {}));

      // Ranking and search cards know the archive but not its parts; the first
      // play resolves the cid through the view API and repairs the queue entry.
      var bvid = track.archive.bvid;
      var cid = track.part.cid;
      if (cid <= 0) {
        final detail = await _api.getArchiveDetail(bvid);
        final page = track.part.page.clamp(1, detail.parts.isEmpty ? 1 : detail.parts.length);
        cid = (detail.parts.isEmpty ? null : detail.parts[page - 1])?.cid ?? 0;
        if (detail.parts.isNotEmpty) {
          final queue = List<MusicTrack>.from(state.queue);
          final repaired = MusicTrack(archive: detail, part: detail.parts[page - 1]);
          final at = queue.indexWhere((t) => t.id == track.id);
          if (at >= 0) queue[at] = repaired;
          state = state.copyWith(queue: List.unmodifiable(queue));
        }
        if (cid <= 0) throw Exception('music: no cid for $bvid');
      }

      // Music always resolves through the plain UGC playurl endpoint — the PGC
      // resolver belongs to the video controller and never routes a music track.
      final urls = await _api.getPlayUrls(bvid: bvid, cid: cid);
      if (generation != _core.generation) return;

      await _core.openUrls(
        track: repairedTrack(),
        urls: urls,
        bvid: bvid,
        audioOnly: state.audioOnly,
        speed: state.speed,
        preferredBackend: _preferredBackend,
      );
      if (generation != _core.generation) return;
      state = state.copyWith(resolving: false, quality: urls.quality, qualityOptions: urls.videoOptions);
      await _core.restorePosition(startAt ?? Duration.zero);
      _consecutiveFailures = 0;
      // Recently played: only a track that actually opened counts as played.
      ref.read(musicLibraryControllerProvider.notifier).recordPlay(repairedTrack().archive);
      _persistSession();
      _ensureSessionHeartbeat();
    } catch (error) {
      if (generation != _core.generation) return;
      _consecutiveFailures++;
      state = state.copyWith(resolving: false, error: error.toString());
      ToastUtil.show(i18n('music_play_failed'));
      await _advanceAfterFailure();
    }
  }

  MusicTrack repairedTrack() => state.current ?? (throw StateError('music track vanished'));

  void _onAdapterEvent(PlayerAdapterEvent event) {
    if (event is PlayerAdapterCompleted) {
      _onCompleted();
    } else if (event is PlayerAdapterErrorEvent) {
      // The muxed mp4 carries both tracks, so a failed stream has no separate
      // audio to fall back to — it goes straight to the failure path.
      _consecutiveFailures++;
      ToastUtil.show(i18n('music_play_failed'));
      unawaited(_advanceAfterFailure());
    }
  }

  Future<void> _onCompleted() async {
    // A sleep timer that expired under "finish the current track" owns this
    // completion instead of the advance rules.
    if (_sleepAfterTrack) {
      _sleepAfterTrack = false;
      state = state.copyWith(sleepMinutes: 0);
      final handle = _core.handle;
      if (handle != null) {
        // The track just ended on its own; pause so the queue holds position
        // and the next open (play/pause) resumes it.
        await VodPlaybackCore.ignoreCancelled(() async {
          if (handle.isPlaying) await handle.pause();
        });
      }
      ToastUtil.show(i18n('music_sleep_stopped'));
      return;
    }
    switch (state.mode) {
      case MusicPlayMode.loopOne:
        final handle = _core.handle;
        if (handle == null) return;
        await VodPlaybackCore.ignoreCancelled(() => handle.seek(Duration.zero));
        await VodPlaybackCore.ignoreCancelled(handle.play);
      case MusicPlayMode.sequence:
        // A song queue that finishes starts over.
        await next();
      case MusicPlayMode.orderStop:
        if (state.index >= state.queue.length - 1) {
          // Sequential play reached the end: the session parks here. The
          // play-later strip still owns the next slot, so give it the turn.
          if (state.tempQueue.isEmpty) {
            final handle = _core.handle;
            if (handle != null) {
              await VodPlaybackCore.ignoreCancelled(() async {
                if (handle.isPlaying) await handle.pause();
              });
            }
            return;
          }
        }
        await next();
      case MusicPlayMode.random:
        await next();
    }
  }

  /// Auto-advance after a failure, but give up once the whole queue is dead —
  /// a broken network must not spin the queue forever.
  Future<void> _advanceAfterFailure() async {
    if (!state.hasQueue) return;
    final cap = state.queue.length.clamp(1, 5);
    if (_consecutiveFailures >= cap) {
      await stop();
      return;
    }
    await next();
  }
}
