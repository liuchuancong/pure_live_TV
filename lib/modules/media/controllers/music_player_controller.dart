import 'dart:async';
import 'dart:math';

import 'package:media_core/media_core.dart';
import 'package:media_core_media_kit/media_core_media_kit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:pure_live/player/models/player_engine.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';

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
  final Random _random = Random();

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
      await handle.seek(Duration.zero);
      if (!handle.isPlaying) await handle.play();
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
    } else {
      await handle.play();
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
    await handle.seek(target);
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

  /// Toggles the picture off (music listening) and back on. mpv drops the
  /// video track in place, so no re-open is needed; the player page paints the
  /// cover over the idle surface.
  Future<void> toggleAudioOnly() async {
    final audioOnly = !state.audioOnly;
    state = state.copyWith(audioOnly: audioOnly);
    await _handle?.setAudioOnly(audioOnly);
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
    _generation++;
    await _releaseHandle();
    state = state.copyWith(resolving: false, quality: 0);
  }

  // ------------------------------------------------------------- internals

  Future<void> _openCurrent() async {
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

      await _openUrls(repairedTrack(), urls, bvid);
      _consecutiveFailures = 0;
      // Recently played: only a track that actually opened counts as played.
      ref.read(musicLibraryControllerProvider.notifier).recordPlay(repairedTrack().archive);
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
    await _releaseHandle();
    // Music can be the first thing the user plays in a session; the live
    // bootstrap otherwise owns this call. Idempotent.
    await GlobalPlayerService.instance.initialize();
    final kernel = _kernel;
    if (kernel == null) throw Exception('player kernel not ready');
    _currentUrls = urls;
    _currentBvid = bvid;

    final headers = await _api.streamHeaders(bvid);
    final audioOnlySource = state.audioOnly && urls.audioUrl != null;

    final handle = await kernel.create(
      config: const PlayerConfig(name: 'music', autoPlay: true),
      preferredBackend: BackendIds.mediaKit,
    );
    _handle = handle;

    // DASH video+audio are separate streams and the source model carries one
    // URI: the video plays as the primary source and the audio rides along on
    // mpv's audio-file input. Both CDN requests need the same headers, so they
    // are appended to the player-wide http-header-fields as well.
    if (!audioOnlySource && urls.isDash && urls.audioUrl != null && urls.audioUrl!.isNotEmpty) {
      final adapter = handle.adapter;
      if (adapter is MediaKitPlayerAdapter) {
        // media_kit's Player proxy does not surface setProperty/command; the
        // native player behind `platform` does. Same dynamic hop the adapter's
        // own property helper takes.
        final native = adapter.player.platform;
        if (native != null) {
          try {
            // ignore: avoid_dynamic_calls
            await (native as dynamic).setProperty('audio-file', urls.audioUrl!);
            final userAgent = headers['user-agent'] ?? '';
            final referer = headers['referer'] ?? '';
            // One `add` per header: list options would split a comma-bearing
            // UA if the whole list went through one string.
            if (userAgent.isNotEmpty) {
              // ignore: avoid_dynamic_calls
              await (native as dynamic).command(['add', 'http-header-fields', 'User-Agent: $userAgent']);
            }
            if (referer.isNotEmpty) {
              // ignore: avoid_dynamic_calls
              await (native as dynamic).command(['add', 'http-header-fields', 'Referer: $referer']);
            }
          } catch (_) {
            // Best-effort: without the attached audio mpv still plays the
            // video stream's own audio when one exists.
          }
        }
      }
    }

    final source = PlayerSource(
      id: SourceId('music_${track.id}_${DateTime.now().millisecondsSinceEpoch}'),
      uri: Uri.parse(audioOnlySource ? urls.audioUrl! : urls.videoUrl),
      protocol: SourceProtocol.https,
      headers: SourceHeaders(headers),
      title: track.title,
    );
    await handle.open(source, autoPlay: true);

    _events?.cancel();
    _events = handle.adapterEvents.listen(_onAdapterEvent);
    // The rate persists across track switches: a user watching at 1.5x keeps
    // 1.5x on the next episode.
    if (state.speed != 1.0) {
      await handle.setRate(state.speed);
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
        await handle.seek(Duration.zero);
        await handle.play();
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
