import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:media_core/media_core.dart';
import 'package:media_core_media_kit/media_core_media_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/player/core/playback_header_resolver.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:pure_live/player/models/player_engine.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:pure_live/modules/music/services/music_audio_cache.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';
import 'package:pure_live/modules/media/models/models.dart';

part 'music_player_controller.g.dart';

/// What the queue UI reads. Playback position and buffering live on the
/// [PlayerHandle] streams instead — they change many times a second and must
/// not rebuild every queue tile.
class MusicPlayerState {
  const MusicPlayerState({
    this.queue = const [],
    this.index = -1,
    this.mode = MusicPlayMode.sequence,
    // Music mode listens (cover art only); the video pages start their queues
    // with [MusicPlayerController.playQueue] `audioOnly: false` for the picture.
    this.audioOnly = true,
    this.resolving = false,
    this.quality = 0,
    this.speed = 1.0,
    this.qualityOptions = const [],
    this.error = '',
  });

  final List<MusicTrack> queue;
  final int index;
  final MusicPlayMode mode;
  final bool audioOnly;
  final bool resolving;

  /// Quality id of the stream currently open (0 = none).
  final int quality;

  /// Playback rate of the current handle.
  final double speed;

  /// Quality tiers the current stream answer can serve, for the player page's
  /// quality menu.
  final List<MusicStreamOption> qualityOptions;
  final String error;

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
    );
  }
}

/// The music-mode player: one VOD [PlayerHandle] on the shared kernel, a track
/// queue and the advance rules.
///
/// Deliberately *not* the live facade: that path is tuned for non-seekable
/// streams and lease renewal. VOD needs seek, position and duration, which the
/// raw handle already carries. The handle is created per track and released on
/// switch, so the mpv `audio-file` input (which attaches the DASH audio stream
/// to the video-only primary) is set per track without touching the shared
/// engine registrations.
@Riverpod(keepAlive: true)
class MusicPlayerController extends _$MusicPlayerController {
  PlayerHandle? _handle;
  StreamSubscription<PlayerAdapterEvent>? _events;

  /// Bumped on every switch so a slow resolve from a superseded track cannot
  /// open its stream over the newer one.
  int _generation = 0;

  /// The stream answer behind the open handle, so a quality switch re-opens a
  /// sibling rendition without another API round-trip.
  MusicPlayUrls? _currentUrls;
  String? _currentBvid;

  /// Stops the auto-advance when every track fails in a row.
  int _consecutiveFailures = 0;

  /// The rendition (qn) the VIDEO mode wants on open, from the video settings.
  /// Null = the play-url answer's own pick — music never sets this.
  int? _preferredQuality;
  final Random _random = Random();

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
    final position = _handle?.position ?? Duration.zero;
    await _releaseHandle();
    final track = state.current;
    if (track == null || _currentUrls == null || _currentBvid == null) return;
    await _ignoreCancelled(() => _openUrls(track, _currentUrls!, _currentBvid!));
    await _restorePosition(position);
  }

  /// The resume option fires once per app run, on the music pane's first build.
  bool _resumeAttempted = false;

  /// Keeps the saved position fresh while a track is playing: a force-kill
  /// then replays at most one heartbeat interval.
  Timer? _sessionHeartbeat;

  void _ensureSessionHeartbeat() {
    _sessionHeartbeat ??= Timer.periodic(const Duration(seconds: 10), (_) {
      if (_handle != null && _handle!.isPlaying && state.hasQueue) _persistSession();
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
      HivePrefUtil.setString(
        _sessionKey,
        jsonEncode({
          'archives': [for (final archive in archives.values) archive.toJson()],
          'order': order,
          'index': state.index < 0 ? 0 : state.index,
          'speed': state.speed,
          'positionMs': _handle?.position.inMilliseconds ?? 0,
        }),
      );
    } catch (_) {
      // A failed snapshot only costs the resume convenience.
    }
  }

  ({List<MusicTrack> tracks, int index, double speed, Duration position})? _loadSession() {
    try {
      final raw = HivePrefUtil.getString(_sessionKey);
      if (raw == null || raw.isEmpty) return null;
      final json = jsonDecode(raw);
      if (json is! Map<String, dynamic>) return null;
      final archives = <String, MusicArchive>{
        for (final entry in (json['archives'] as List?) ?? const <dynamic>[])
          if (entry is Map<String, dynamic>) entry['bvid']?.toString() ?? '': MusicArchive.fromJson(entry),
      };
      final tracks = <MusicTrack>[];
      for (final ref in (json['order'] as List?) ?? const <dynamic>[]) {
        final parts = ref?.toString().split('#');
        if (parts == null || parts.length != 2) continue;
        final archive = archives[parts[0]];
        if (archive == null) continue;
        final page = int.tryParse(parts[1]) ?? 1;
        final part =
            archive.parts.where((p) => p.page == page).firstOrNull ?? (archive.parts.isEmpty ? null : archive.parts.first);
        if (part == null) continue;
        tracks.add(MusicTrack(archive: archive, part: part));
      }
      if (tracks.isEmpty) return null;
      final index = (int.tryParse(json['index']?.toString() ?? '') ?? 0).clamp(0, tracks.length - 1);
      final speed = double.tryParse(json['speed']?.toString() ?? '') ?? 1.0;
      final position = Duration(milliseconds: int.tryParse(json['positionMs']?.toString() ?? '') ?? 0);
      return (tracks: tracks, index: index, speed: speed, position: position);
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
    if (state.hasQueue || _handle != null) return;
    final session = _loadSession();
    if (session == null) return;
    state = state.copyWith(
      queue: List.unmodifiable(session.tracks),
      index: session.index,
      speed: session.speed,
      error: '',
    );
    await _openCurrent(session.position);
  }

  /// The rate steps the player page cycles through.
  static const List<double> speedSteps = [1.0, 1.25, 1.5, 2.0];

  /// Module-injected playurl hook. The media layer owns playback but not the
  /// module data around it, so the video module plugs its PGC resolver in
  /// (episodes resolve through the pgc playurl endpoint, not the UGC one).
  static Future<MusicPlayUrls?> Function(MusicTrack track)? modulePlayUrlResolver;

  @override
  MusicPlayerState build() {
    ref.onDispose(_releaseHandle);
    // Music-mode defaults from the music settings section: the play mode and
    // the audio-only preference the user picked rule until they change them.
    final savedMode = MusicPlayMode.values
        .where((m) => m.name == HivePrefUtil.getString('musicDefaultPlayMode'))
        .firstOrNull;
    final savedAudioOnly = HivePrefUtil.getString('musicDefaultAudioOnly') != 'false';
    return MusicPlayerState(mode: savedMode ?? MusicPlayMode.sequence, audioOnly: savedAudioOnly);
  }

  BilibiliMusicApi get _api => BilibiliMusicApi.instance;

  PlayerKernel? get _kernel => GlobalPlayerService.instance.kernel;

  /// The handle the player page renders; null while idle or resolving.
  PlayerHandle? get handle => _handle;

  /// Live playback state for the progress bar; null while idle.
  Stream<PlaybackState>? get playbackStream => _handle?.playbackStream;

  // ------------------------------------------------------------- queue input

  /// Replaces the queue and starts at [startIndex]. [audioOnly] seeds the
  /// listening style: music pages keep the default (cover-art listening),
  /// video pages pass false so the picture shows.
  Future<void> playQueue(List<MusicTrack> tracks, {int startIndex = 0, bool? audioOnly}) async {
    if (tracks.isEmpty) return;
    final index = startIndex.clamp(0, tracks.length - 1);
    state = state.copyWith(
      queue: List.unmodifiable(tracks),
      index: index,
      error: '',
      audioOnly: audioOnly,
      qualityOptions: const [],
    );
    await _openCurrent();
  }

  /// Mainstream 下一首播放: puts [track] right after the playing one. With no
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

  // ------------------------------------------------------------- advance rules

  Future<void> next() async {
    final queue = state.queue;
    if (queue.isEmpty) return;
    var target = state.index;
    switch (state.mode) {
      case MusicPlayMode.random:
        if (queue.length > 1) {
          do {
            target = _random.nextInt(queue.length);
          } while (target == state.index);
        } else {
          target = state.index;
        }
      case MusicPlayMode.sequence:
      case MusicPlayMode.loopOne:
        // Manual next always moves, even under Repeat one.
        target = (state.index + 1) % queue.length;
    }
    await jumpTo(target);
  }

  Future<void> previous() async {
    final queue = state.queue;
    if (queue.isEmpty) return;
    // A track more than a few seconds in restarts instead of skipping back —
    // the music-player convention.
    final handle = _handle;
    if (handle != null && handle.position > const Duration(seconds: 5)) {
      await _ignoreCancelled(() => handle.seek(Duration.zero));
      if (!handle.isPlaying) await _ignoreCancelled(handle.play);
      return;
    }
    await jumpTo((state.index - 1 + queue.length) % queue.length);
  }

  Future<void> cycleMode() async {
    state = state.copyWith(mode: state.mode.next);
  }

  /// Re-opens the current stream at [quality] from the rendition list the last
  /// answer shipped — no new API request, just a fresh mpv load.
  Future<void> switchQuality(int quality) async {
    final urls = _currentUrls;
    final bvid = _currentBvid;
    if (urls == null || bvid == null || quality == state.quality) return;
    final option = urls.videoOptions.where((o) => o.quality == quality).firstOrNull;
    if (option == null || option.url.isEmpty) return;
    final track = state.current;
    if (track == null) return;

    state = state.copyWith(quality: quality, resolving: true);
    try {
      await _openUrls(
        track,
        MusicPlayUrls(
          videoUrl: option.url,
          audioUrl: urls.audioUrl,
          videoBackupUrls: option.backupUrls,
          quality: quality,
          videoOptions: urls.videoOptions,
        ),
        bvid,
      );
      state = state.copyWith(resolving: false);
    } catch (error) {
      state = state.copyWith(resolving: false, error: error.toString());
      ToastUtil.show(i18n('music_play_failed'));
    }
  }

  /// The video settings' default rendition; the next resolve opens it when the
  /// answer ships that rendition.
  void setPreferredQuality(int quality) => _preferredQuality = quality > 0 ? quality : null;

  /// Sets the rate directly (the video settings' default speed applies it once
  /// on page entry); unlike [cycleSpeed] it takes an absolute value.
  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    await _ignoreCancelled(() async {
      final target = handle;
      if (target != null) await target.setRate(speed);
    });
  }

  /// Cycles the playback rate through [speedSteps].
  Future<void> cycleSpeed() async {
    final next = speedSteps[(speedSteps.indexOf(state.speed) + 1) % speedSteps.length];
    state = state.copyWith(speed: next);
    await _handle?.setRate(next);
  }

  // ------------------------------------------------------------- transport

  Future<void> togglePlayPause() async {
    final handle = _handle;
    if (handle == null) {
      // The stream is gone (stopped, or live playback took the speakers) but
      // the queue survived: reopening the current track resumes from it.
      if (state.hasQueue) await _openCurrent();
      return;
    }
    if (handle.isPlaying) {
      await handle.pause();
      // Paused is where a session is usually left: snapshot the position now.
      _persistSession();
    } else {
      await _ignoreCancelled(handle.play);
    }
  }

  /// A transport operation that loses to a newer one — another seek, a track
  /// switch, a stop — is cancelled by media_core by design: the player has
  /// already moved on, so the superseded one must not surface as an error.
  Future<void> _ignoreCancelled(Future<void> Function() operation) async {
    try {
      await operation();
    } on OperationCancelledException {
      // Superseded — the newer operation owns the transport now.
    }
  }

  Future<void> seekTo(Duration position) async {
    final handle = _handle;
    if (handle == null) return;
    final duration = handle.duration;
    var target = position;
    if (duration > Duration.zero) {
      if (target < Duration.zero) target = Duration.zero;
      if (target > duration) target = duration;
    }
    await _ignoreCancelled(() => handle.seek(target));
    _persistSession();
  }

  Future<void> seekBy(int seconds) async {
    final handle = _handle;
    if (handle == null) return;
    await seekTo(handle.position + Duration(seconds: seconds));
  }

  /// Seek with newBV's press acceleration: repeated presses inside 200ms grow
  /// the step from 10s up to 60s, so a long skip needs no dozen presses. The
  /// transport-row 快退/快进 buttons and the hidden-state arrows share this.
  DateTime _accelLastAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _accelStep = 10;

  Future<void> seekAccelerated(int direction) async {
    final now = DateTime.now();
    _accelStep = now.difference(_accelLastAt) < const Duration(milliseconds: 200) ? (_accelStep + 5).clamp(10, 60) : 10;
    _accelLastAt = now;
    await seekBy(direction * _accelStep);
  }

  /// Toggles between the lyric view and the video view without leaving the
  /// player.
  ///
  /// - video → audio: mpv drops the video track in place, the sound keeps
  ///   playing, no re-open.
  /// - audio → video: if the open source is the audio-only stream there *is*
  ///   no video track to restore, so the cached DASH pair is re-opened and
  ///   playback resumes at the current position — the dynamic switch the
  ///   music player's 歌词/视频 toggle rides on.
  ///
  /// A re-open that fails keeps the sound and puts the mode back: a video stream
  /// that is expired or refused is not a dead track, and letting it reach the
  /// failure path is what made "显示画面" skip to the next song.
  /// Switches between 纯音乐 and 显示画面 without touching the stream.
  ///
  /// Both views share one player: the DASH pair (or the mp4) is always opened
  /// whole, so the toggle is the native video-track switch — instant, and the
  /// position never moves (the reference client's behaviour). The one reopen
  /// left is audio-only playing the locally cached file, which carries no
  /// picture: showing it needs the network pair.
  Future<void> toggleAudioOnly() async {
    final audioOnly = !state.audioOnly;
    final handle = _handle;
    state = state.copyWith(audioOnly: audioOnly);

    if (!audioOnly && _playingLocalFile) {
      final position = handle?.position ?? Duration.zero;
      final track = state.current;
      final bvid = _currentBvid;
      if (track != null && bvid != null) {
        // The cached file carries no picture: say it is loading instead of
        // leaving the toggle silent while the network pair re-opens.
        state = state.copyWith(resolving: true);
        try {
          // The answer that fed the cache may be hours old, and a stale DASH
          // audio URL is exactly the silent-video failure — the picture
          // streams while the expired audio 403s. Re-resolve instead of
          // replaying the stored answer.
          var fresh = await modulePlayUrlResolver?.call(track);
          fresh ??= await _api.getPlayUrls(bvid: bvid, cid: track.part.cid);
          await _openUrls(track, fresh, bvid);
          await _restorePosition(position);
          return;
        } catch (_) {
          state = state.copyWith(audioOnly: true);
          return;
        } finally {
          if (ref.mounted) state = state.copyWith(resolving: false);
        }
      }
    }

    try {
      await handle?.setAudioOnly(audioOnly);
    } catch (_) {
      state = state.copyWith(audioOnly: !audioOnly);
    }
  }

  /// Whether the open source is the cache's local file rather than the network.
  bool _playingLocalFile = false;

  /// Drops back to the audio stream at [position] after the picture could not be
  /// opened, keeping the track playing.
  ///
  /// Deliberately not the failure path ([_advanceAfterFailure]): that one is for
  /// a track that is dead, and running a refused video stream through it skipped
  /// the queue on every 显示画面 press.
  Future<void> _degradeToAudioOnly(Duration position) async {
    _consecutiveFailures = 0;
    state = state.copyWith(audioOnly: true, resolving: false);
    ToastUtil.show(i18n('music_video_failed'));

    final urls = _currentUrls;
    final track = state.current;
    final bvid = _currentBvid;
    if (urls == null || urls.audioUrl == null || track == null || bvid == null) {
      await _openCurrent();
      return;
    }
    try {
      await _openUrls(track, urls, bvid);
      await _restorePosition(position);
    } catch (_) {
      // The audio is gone too — now it is the failure path's business.
      await _openCurrent();
    }
  }

  Future<void> _restorePosition(Duration position) async {
    if (position <= Duration.zero) return;
    await _ignoreCancelled(() async {
      final target = _handle;
      if (target != null) await target.seek(position);
    });
  }

  Future<void> stop() async {
    _generation++;
    await _releaseHandle();
    _currentUrls = null;
    _currentBvid = null;
    // The queue is gone but the listening preferences survive the session.
    state = MusicPlayerState(mode: state.mode, audioOnly: state.audioOnly, speed: state.speed);
  }

  /// Live playback takes the speakers: the open stream is dropped but the
  /// queue and the track pointer survive, so returning to the music tab can
  /// resume from the queue. Cheaper than [stop] and repeatable — every live
  /// channel switch calls it.
  Future<void> pauseForLive() async {
    if (_handle == null && !state.hasQueue) return;
    // Snapshot before the handle goes away: live playback then owns the
    // speakers with the last music position still on record.
    _persistSession();
    _generation++;
    await _releaseHandle();
    state = state.copyWith(resolving: false, quality: 0);
  }

  // ------------------------------------------------------------- internals

  /// Opens the current queue entry. [startAt] is the resume position the
  /// last-session restore asks for; a plain track start opens from zero.
  Future<void> _openCurrent([Duration? startAt]) async {
    final generation = ++_generation;
    final track = state.current;
    if (track == null) return;

    state = state.copyWith(resolving: true, error: '');

    try {
      // Live playback owns the speakers from here on; music owns them when a
      // track opens. Pausing (not stopping) keeps the live session resumable.
      unawaited(GlobalPlayerService.instance.livePlayer?.pause().catchError((Object _) {}));

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

      // A module resolver (video PGC) may own the track; otherwise the plain
      // UGC playurl endpoint answers.
      var urls = await modulePlayUrlResolver?.call(repairedTrack());
      urls ??= await _api.getPlayUrls(bvid: bvid, cid: cid);
      if (generation != _generation) return;

      // The video mode's 默认清晰度: exact rendition match only — if the answer
      // does not ship it, the server's own pick stands (no second open).
      final preferred = _preferredQuality;
      if (preferred != null && preferred != urls.quality) {
        final match = urls.videoOptions.where((o) => o.quality == preferred && o.url.isNotEmpty).firstOrNull;
        if (match != null) {
          urls = MusicPlayUrls(
            videoUrl: match.url,
            audioUrl: urls.audioUrl,
            videoBackupUrls: match.backupUrls,
            quality: preferred,
            videoOptions: urls.videoOptions,
          );
        }
      }

      await _openUrls(repairedTrack(), urls, bvid);
      await _restorePosition(startAt ?? Duration.zero);
      _consecutiveFailures = 0;
      // Recently played: only a track that actually opened counts as played.
      ref.read(musicLibraryControllerProvider.notifier).recordPlay(repairedTrack().archive);
      _persistSession();
      _ensureSessionHeartbeat();
    } catch (error) {
      if (generation != _generation) return;
      _consecutiveFailures++;
      state = state.copyWith(resolving: false, error: error.toString());
      ToastUtil.show(i18n('music_play_failed'));
      await _advanceAfterFailure();
    }
  }

  MusicTrack repairedTrack() => state.current ?? (throw StateError('music track vanished'));

  Future<void> _openUrls(MusicTrack track, MusicPlayUrls urls, String bvid) async {
    // Music keeps one player for the whole queue: the handle below is reused
    // across tracks, and only [stop] / [pauseForLive] (live or video taking
    // the speakers) / a backend switch tear it down. Every open resets the
    // per-source state a reused player carries — see the audio-file and
    // header resets below.
    // Music can be the first thing the user plays in a session; the live
    // bootstrap otherwise owns this call. Idempotent.
    await GlobalPlayerService.instance.initialize();
    final kernel = _kernel;
    if (kernel == null) throw Exception('player kernel not ready');
    _currentUrls = urls;
    _currentBvid = bvid;

    // The VOD branch of the playback header resolver: the live bilibili
    // policy with the video-page Referer.
    final headers = await PlaybackHeaderResolver.resolveVod(bvid: bvid);

    // 纯音乐 prefers the cached file: once a track has been heard, replaying it
    // asks nothing from the network. The file carries no picture, so the video
    // view always streams (and keeps the cache warm for the next listen).
    _playingLocalFile = false;
    String openUrl = urls.videoUrl;
    var openProtocol = SourceProtocol.https;
    // Whether the primary source is the video-only m4s — only then does the
    // DASH audio ride along as mpv's external audio-file track.
    var videoPrimary = true;
    if (state.audioOnly) {
      final File? cached = await MusicAudioCache.instance.cachedFile(track.id);
      if (cached != null) {
        openUrl = cached.path;
        openProtocol = SourceProtocol.file;
        _playingLocalFile = true;
        videoPrimary = false;
      } else if (urls.audioUrl != null && urls.audioUrl!.isNotEmpty) {
        // No cache yet: the AUDIO m4s becomes the primary source, like the
        // pre-cache builds. Opening the video m4s and hanging the audio on
        // mpv's audio-file input stalled every first play of a track: mpv
        // waits for the external track's demuxer to initialize, and a slow
        // CDN open blocked playback start indefinitely (stuck at open).
        openUrl = urls.audioUrl!;
        videoPrimary = false;
      }
    }

    final PlayerHandle handle = _handle ?? await kernel.create(
      config: const PlayerConfig(name: 'music', autoPlay: true),
      preferredBackend: _preferredBackend,
    );
    _handle = handle;

    // DASH video+audio are separate streams and the source model carries one
    // URI: the video plays as the primary source and the audio rides along on
    // mpv's audio-file input. Both CDN requests need the same headers, so they
    // are appended to the player-wide http-header-fields as well.
    // 纯音乐 plays the cached file with no attachment (there is nothing to
    // attach to — the file is the finished audio), and a no-cache audio-only
    // open takes the audio m4s itself as primary — a single stream, no
    // external track. Only a video-primary open hangs the audio on mpv's
    // audio-file input.
    //
    // Runs on every open, fresh or reused: a reused player still holds the
    // previous track's attachment and headers, and both would bleed into this
    // one.
    final String attachedAudio =
        videoPrimary && urls.isDash && urls.audioUrl != null && urls.audioUrl!.isNotEmpty
        ? urls.audioUrl!
        : '';
    final adapter = handle.adapter;
    if (adapter is MediaKitPlayerAdapter) {
      // media_kit's Player proxy does not surface setProperty/command; the
      // native player behind `platform` does. Same dynamic hop the adapter's
      // own property helper takes.
      final native = adapter.player.platform;
      if (native != null) {
        // Each write stands alone: one rejection must not silently skip the
        // rest (an audio-file without its headers answers 403, and the DASH
        // video stream has no audio of its own to fall back to).
        // ignore: avoid_dynamic_calls
        await (native as dynamic).setProperty('audio-file', attachedAudio).catchError((Object _) {});
        // The header list survives on a reused player: clear it, then one
        // `add` per header (a comma-bearing UA would split if the whole list
        // went through one string).
        try {
          // ignore: avoid_dynamic_calls
          await (native as dynamic).setProperty('http-header-fields', '');
        } catch (_) {}
        final userAgent = headers['user-agent'] ?? '';
        final referer = headers['referer'] ?? '';
        if (userAgent.isNotEmpty) {
          try {
            // ignore: avoid_dynamic_calls
            await (native as dynamic).command(['add', 'http-header-fields', 'User-Agent: $userAgent']);
          } catch (_) {}
        }
        if (referer.isNotEmpty) {
          try {
            // ignore: avoid_dynamic_calls
            await (native as dynamic).command(['add', 'http-header-fields', 'Referer: $referer']);
          } catch (_) {}
        }
      }
    }

    final source = PlayerSource(
      id: SourceId('music_${track.id}_${DateTime.now().millisecondsSinceEpoch}'),
      uri: Uri.parse(openUrl),
      protocol: openProtocol,
      headers: SourceHeaders(headers),
      title: track.title,
    );
    try {
      await handle.open(source, autoPlay: true);
    } catch (_) {
      // An open that failed mid-flight can leave the adapter in a state the
      // next open cannot trust: retire it, and the next track builds fresh.
      await _releaseHandle();
      rethrow;
    }

    // 纯音乐/显示画面 is the native video-track switch on the just-opened
    // stream, not a different source: toggling back is then instant and
    // seamless. Applied on EVERY open, both ways — a reused player keeps
    // `vid=no` from an earlier audio-only track, and video mode that never
    // turned it back on would show a dead surface for the rest of the queue.
    try {
      await handle.setAudioOnly(state.audioOnly);
    } catch (_) {}

    // Warm the cache for the next play of this track while the network stream
    // runs. Skipped when this session already plays the cached file.
    if (!_playingLocalFile && state.audioOnly && urls.audioUrl != null && urls.audioUrl!.isNotEmpty) {
      MusicAudioCache.instance.prefetch(trackId: track.id, url: urls.audioUrl!, headers: headers);
    }

    _events?.cancel();
    _events = handle.adapterEvents.listen(_onAdapterEvent);
    // The rate persists across track switches: a user watching at 1.5x keeps
    // 1.5x on the next episode.
    if (state.speed != 1.0) {
      await _ignoreCancelled(() => handle.setRate(state.speed));
    }
    state = state.copyWith(resolving: false, quality: urls.quality, qualityOptions: urls.videoOptions);

    // Cloud history heartbeat per track start (the bmsc behaviour): the
    // bilibili history page then shows what was listened to. Silent when
    // logged out or the report fails.
    if (track.archive.aid > 0) {
      BilibiliUgcApi.instance
          .reportHistory(aid: track.archive.aid, cid: track.part.cid, progress: 0, bvid: track.archive.bvid)
          .catchError((Object _) {});
    }
  }

  void _onAdapterEvent(PlayerAdapterEvent event) {
    if (event is PlayerAdapterCompleted) {
      _onCompleted();
    } else if (event is PlayerAdapterErrorEvent) {
      // A video stream that fell over is not a dead track — the same track's
      // audio stream usually still plays, and the lyrics view is the right answer
      // for it. Only a track with nothing left to play goes to the failure path.
      if (!state.audioOnly && _currentUrls?.audioUrl != null) {
        unawaited(_degradeToAudioOnly(_handle?.position ?? Duration.zero));
        return;
      }
      _consecutiveFailures++;
      ToastUtil.show(i18n('music_play_failed'));
      unawaited(_advanceAfterFailure());
    }
  }

  Future<void> _onCompleted() async {
    switch (state.mode) {
      case MusicPlayMode.loopOne:
        final handle = _handle;
        if (handle == null) return;
        await _ignoreCancelled(() => handle.seek(Duration.zero));
        await _ignoreCancelled(handle.play);
      case MusicPlayMode.sequence:
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

  Future<void> _releaseHandle() async {
    _events?.cancel();
    _events = null;
    final handle = _handle;
    _handle = null;
    if (handle == null) return;
    final kernel = _kernel;
    if (kernel == null) return;
    try {
      await kernel.release(handle.id);
    } catch (_) {
      // A handle that already fell over must not take the next track down.
    }
  }
}
