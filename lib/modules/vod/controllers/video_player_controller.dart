import 'dart:async';
import 'package:media_core/media_core.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/player/models/player_engine.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/modules/vod/domain/providers/vod_providers.dart';
import 'package:pure_live/modules/vod/domain/repositories/music_vod_repository.dart';
import 'package:pure_live/modules/vod/controllers/vod_playback_core.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';

part 'video_player_controller.g.dart';

/// What the video player page reads. Playback position and buffering live on the
/// [PlayerHandle] streams instead — they change many times a second and must not
/// rebuild the page.
///
/// Video is a single archive's parts (or a PGC season's episodes) played
/// strictly in order: no play modes, no shuffle, no "play later" strip, no sleep
/// timer. Those belong to the music session, which runs on its own controller
/// and its own handle so the two never clobber each other.
class VideoPlayerState {
  const VideoPlayerState({
    this.queue = const [],
    this.index = -1,
    this.resolving = false,
    this.quality = 0,
    this.speed = 1.0,
    this.qualityOptions = const [],
    this.error = '',
  });

  final List<MusicTrack> queue;
  final int index;
  final bool resolving;

  /// Quality id of the stream currently open (0 = none).
  final int quality;

  /// Playback rate of the current handle.
  final double speed;

  /// Quality tiers the current stream answer can serve, for the quality menu.
  final List<MusicStreamOption> qualityOptions;
  final String error;

  MusicTrack? get current => index >= 0 && index < queue.length ? queue[index] : null;

  bool get hasQueue => queue.isNotEmpty;

  VideoPlayerState copyWith({
    List<MusicTrack>? queue,
    int? index,
    bool? resolving,
    int? quality,
    double? speed,
    List<MusicStreamOption>? qualityOptions,
    String? error,
  }) {
    return VideoPlayerState(
      queue: queue ?? this.queue,
      index: index ?? this.index,
      resolving: resolving ?? this.resolving,
      quality: quality ?? this.quality,
      speed: speed ?? this.speed,
      qualityOptions: qualityOptions ?? this.qualityOptions,
      error: error ?? this.error,
    );
  }
}

/// The video-mode player: its own VOD [PlayerHandle] on the shared kernel, a
/// strictly sequential part/episode list, and the picture-session extras
/// (quality, rate). Deliberately separate from [MusicPlayerController] so a
/// video never replaces the music queue, never overwrites the music resume
/// snapshot, and never reads back as the current song.
///
/// Opening a video suspends the music and live sessions (they keep their state,
/// drop the handle); the page's own [stop] on exit tears the video session down.
@Riverpod(keepAlive: true)
class VideoPlayerController extends _$VideoPlayerController {
  late final VodPlaybackCore _core = VodPlaybackCore(configName: 'video');

  /// The rendition (qn) the video settings want on open. Null = the play-url
  /// answer's own pick.
  int? _preferredQuality;

  /// Stops the auto-advance when every part fails in a row.
  int _consecutiveFailures = 0;

  /// Seek acceleration state (newBV's press-and-hold skip): repeated presses
  /// inside 200ms grow the step from 10s up to 60s.
  DateTime _accelLastAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _accelStep = 10;

  /// The rate steps the speed menu cycles through.
  static const List<double> speedSteps = [0.5, 1.0, 1.25, 1.5, 2.0];

  /// Module-injected playurl hook. The video module plugs its PGC resolver in
  /// (episodes resolve through the pgc playurl endpoint, not the UGC one). The
  /// music controller never consults this, so a music track can no longer be
  /// routed through the PGC endpoint by accident.
  static Future<MusicPlayUrls?> Function(MusicTrack track)? modulePlayUrlResolver;

  @override
  VideoPlayerState build() {
    _core.onAdapterEvent = _onAdapterEvent;
    ref.onDispose(() => _core.releaseHandle());
    return const VideoPlayerState();
  }

  MusicVodRepository get _api => ref.read(musicRepositoryProvider);

  /// The handle the player page renders; null while idle or resolving.
  PlayerHandle? get handle => _core.handle;

  /// Live playback state for the progress bar; null while idle.
  Stream<PlayerTransportState>? get playbackStream => _core.playbackStream;

  /// Replaces the part/episode list and starts at [startIndex]. Always a
  /// picture session — video never runs audio-only.
  Future<void> playQueue(List<MusicTrack> tracks, {int startIndex = 0}) async {
    if (tracks.isEmpty) return;
    final index = startIndex.clamp(0, tracks.length - 1);
    _consecutiveFailures = 0;
    state = VideoPlayerState(queue: List.unmodifiable(tracks), index: index, speed: state.speed);
    await _openCurrent();
  }

  /// Jumps to another part/episode in the current list.
  Future<void> jumpTo(int index) async {
    if (index < 0 || index >= state.queue.length || index == state.index) return;
    state = state.copyWith(index: index, error: '');
    await _openCurrent();
  }

  /// The video settings' default rendition; the next resolve opens it when the
  /// answer ships that rendition.
  void setPreferredQuality(int quality) => _preferredQuality = quality > 0 ? quality : null;

  /// Sets the rate directly (the video settings' default speed applies it once
  /// on page entry).
  Future<void> setSpeed(double speed) async {
    state = state.copyWith(speed: speed);
    final target = _core.handle;
    if (target != null) await VodPlaybackCore.ignoreCancelled(() => target.setRate(speed));
  }

  /// Cycles the playback rate through [speedSteps].
  Future<void> cycleSpeed() async {
    final next = speedSteps[(speedSteps.indexOf(state.speed) + 1) % speedSteps.length];
    await setSpeed(next);
  }

  /// Re-opens the current stream at [quality] from the rendition list the last
  /// answer shipped — no new API request, just a fresh load.
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
        audioOnly: false,
        speed: state.speed,
        preferredBackend: BackendIds.mediaKit,
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
      // the list survived: reopening the current part resumes from it.
      if (state.hasQueue) await _openCurrent();
      return;
    }
    if (handle.isPlaying) {
      await handle.pause();
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
  }

  Future<void> seekBy(int seconds) async {
    final handle = _core.handle;
    if (handle == null) return;
    await seekTo(handle.position + Duration(seconds: seconds));
  }

  Future<void> seekAccelerated(int direction) async {
    final now = DateTime.now();
    _accelStep = now.difference(_accelLastAt) < const Duration(milliseconds: 200) ? (_accelStep + 5).clamp(10, 60) : 10;
    _accelLastAt = now;
    await seekBy(direction * _accelStep);
  }

  /// Tears the video session down (the page exits): the handle is released and
  /// the list cleared. The music queue is untouched — it lives on its own
  /// controller and was only suspended, never replaced.
  Future<void> stop() async {
    _core.bumpGeneration();
    await _core.releaseHandle();
    _core.currentUrls = null;
    _core.currentBvid = null;
    _consecutiveFailures = 0;
    state = const VideoPlayerState();
  }

  /// Another session (music or live) took the speakers: drop the handle but
  /// keep the list and index, so a still-mounted page can resume.
  Future<void> suspend() async {
    if (_core.handle == null && !state.hasQueue) return;
    _core.bumpGeneration();
    await _core.releaseHandle();
    state = state.copyWith(resolving: false, quality: 0);
  }

  // ------------------------------------------------------------- internals

  Future<void> _openCurrent([Duration? startAt]) async {
    final generation = _core.bumpGeneration();
    final track = state.current;
    if (track == null) return;

    state = state.copyWith(resolving: true, error: '');

    try {
      // The video session owns the speakers from here on. Pause live, and
      // suspend the music queue (keeping it intact so returning to music can
      // resume) — the inverse of what the music controller does on open.
      unawaited(GlobalPlayerService.instance.livePlayer?.pause().catchError((Object _) {}));
      unawaited(ref.read(musicPlayerControllerProvider.notifier).suspend().catchError((Object _) {}));

      // Ranking and search cards know the archive but not its parts; the first
      // play resolves the cid through the view API and repairs the list entry.
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
        if (cid <= 0) throw Exception('video: no cid for $bvid');
      }

      // A module resolver (PGC) may own the track; otherwise the plain UGC
      // playurl endpoint answers.
      var urls = await modulePlayUrlResolver?.call(repairedTrack()) ?? await _api.getPlayUrls(bvid: bvid, cid: cid);
      if (generation != _core.generation) return;

      // The video settings' preferred rendition overrides the answer's own pick
      // when the answer ships it.
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

      await _core.openUrls(
        track: repairedTrack(),
        urls: urls,
        bvid: bvid,
        audioOnly: false,
        speed: state.speed,
        preferredBackend: BackendIds.mediaKit,
      );
      if (generation != _core.generation) return;
      state = state.copyWith(resolving: false, quality: urls.quality, qualityOptions: urls.videoOptions);
      await _core.restorePosition(startAt ?? Duration.zero);
      _consecutiveFailures = 0;
    } catch (error) {
      if (generation != _core.generation) return;
      _consecutiveFailures++;
      state = state.copyWith(resolving: false, error: error.toString());
      ToastUtil.show(i18n('music_play_failed'));
      await _advanceAfterFailure();
    }
  }

  MusicTrack repairedTrack() => state.current ?? (throw StateError('video track vanished'));

  void _onAdapterEvent(PlayerAdapterEvent event) {
    if (event is PlayerAdapterCompleted) {
      _onCompleted();
    } else if (event is PlayerAdapterErrorEvent) {
      _consecutiveFailures++;
      ToastUtil.show(i18n('music_play_failed'));
      unawaited(_advanceAfterFailure());
    }
  }

  /// Video is strictly sequential, no wrap: the last part ending is THE end and
  /// the session parks there.
  Future<void> _onCompleted() async {
    if (state.index >= state.queue.length - 1) return;
    await jumpTo(state.index + 1);
  }

  /// Auto-advance after a failure, but give up once the list is exhausted or too
  /// many parts failed in a row — a broken network must not spin forever.
  Future<void> _advanceAfterFailure() async {
    if (!state.hasQueue) return;
    final cap = state.queue.length.clamp(1, 5);
    if (_consecutiveFailures >= cap || state.index >= state.queue.length - 1) {
      await stop();
      return;
    }
    await jumpTo(state.index + 1);
  }
}
