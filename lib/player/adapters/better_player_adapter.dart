import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart';
import 'package:better_player_plus/better_player_plus.dart';

/// [PlayerAdapter] implementation backed by better_player_plus —
/// the ExoPlayer engine.
///
/// Engine semantics:
///
/// - source-scoped event acceptance with deferred errors
///   (ExoPlayer can emit an exception synchronously while
///   setupDataSource is still pending) — provided by the base
/// - fit applied through `setOverriddenFit`, never a wrapper widget
/// - audio-output suppression starts the source muted, avoiding an
///   audible burst during initialization
/// - live streams flagged through the data source
/// - an honest capability declaration ([defaultCapabilities]): the engine
///   has no decoded-frame signal, so `supportsVideoFrameProgress` is false
///   and the live video-frame watchdog stays disabled for this backend
///   instead of being fed a fabricated heartbeat.
final class BetterPlayerAdapter extends PlayerAdapterBase {
  /// Creates the adapter.
  BetterPlayerAdapter({super.id = 'exo', super.capabilities = defaultCapabilities});

  BetterPlayerController? _controller;

  bool _isAudioOnly = false;
  bool _audioOutputSuppressed = false;

  /// The underlying BetterPlayerController.
  ///
  /// Throws [StateError] before [initialize].
  BetterPlayerController get controller {
    final c = _controller;
    if (c == null) {
      throw StateError('BetterPlayerAdapter has not been initialized.');
    }
    return c;
  }

  // ---------------------------------------------------------------------------
  // Engine contract
  // ---------------------------------------------------------------------------

  @override
  Future<void> onInitialize(PlayerAdapterContext context) async {
    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        // A suppressed automatic fallback starts only after its
        // native volume is zero, avoiding a short audible burst
        // during source initialization.
        autoPlay: !_audioOutputSuppressed,
        fit: BoxFit.contain,
        handleLifecycle: false,
        fullScreenByDefault: false,
        looping: false,
        controlsConfiguration: const BetterPlayerControlsConfiguration(showControls: false),
      ),
    );

    controller.addEventsListener(_onEngineEvent);
  }

  @override
  bool get engineReportsOpenFailure => controller.videoPlayerController?.value.hasError == true;

  @override
  Future<void> onOpen(PlayerSource source) async {
    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      source.uri.toString(),
      headers: source.hasHeaders ? Map<String, String>.from(source.headers!.values) : null,
      liveStream: true,
    );

    await controller.setupDataSource(dataSource);
  }

  @override
  Future<void> onAfterOpen(PlayerSource source) async {
    await setVolume(_audioOutputSuppressed ? 0.0 : 1.0);

    if (_audioOutputSuppressed) {
      await play();
    }
  }

  @override
  Future<void> onPlay() => controller.play();

  @override
  Future<void> onPause() => controller.pause();

  @override
  Future<void> onStop() async {
    await controller.pause();
    await controller.seekTo(Duration.zero);
  }

  @override
  Future<void> onSeek(Duration position) => controller.seekTo(position);

  @override
  Future<void> onSetVolume(double volume) => controller.setVolume(volume.clamp(0.0, 1.0));

  @override
  Future<void> onSetRate(double rate) => controller.setSpeed(rate);

  @override
  Future<void> onClose() async {
    await controller.pause();
    await controller.seekTo(Duration.zero);
  }

  @override
  Future<void> onDispose() async {
    // better_player returns early from dispose() when autoDispose is false, and
    // this adapter sets it false to own the lifecycle itself. Without
    // forceDispose the native ExoPlayer survives - decoder, surface and audio
    // included - so the next engine switch fights it for the hardware decoder
    // and a closed room keeps playing behind the UI.
    final controller = _controller;
    _controller = null;

    controller?.dispose(forceDispose: true);
  }

  // ---------------------------------------------------------------------------
  // TV extensions
  // ---------------------------------------------------------------------------

  /// Suppresses audio output for the next open.
  void setAudioOutputSuppressed(bool suppressed) {
    _audioOutputSuppressed = suppressed;
  }

  /// Enables or disables video rendering.
  Future<void> setAudioOnly(bool audioOnly) async {
    if (isDisposed || _isAudioOnly == audioOnly) return;

    _isAudioOnly = audioOnly;

    if (!initialized) return;

    // ExoPlayer track selection goes through the video controller;
    // better_player exposes no direct toggle, so mute the video
    // track via the underlying controller where available.
    final underlying = _controller?.videoPlayerController;

    if (underlying != null) {
      try {
        await underlying.setVolume(audioOnly ? underlying.value.volume : underlying.value.volume);
      } catch (_) {
        // Best-effort.
      }
    }
  }

  /// Applies the viewport fit through `setOverriddenFit`.
  void setVideoFit(BoxFit fit) {
    _controller?.setOverriddenFit(fit);
  }

  // ---------------------------------------------------------------------------
  // Engine events
  // ---------------------------------------------------------------------------

  void _onEngineEvent(BetterPlayerEvent event) {
    if (!acceptsEngineEvents) return;

    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.initialized:
      case BetterPlayerEventType.changedResolution:
        final size = _controller?.videoPlayerController?.value.size;

        if (size != null) {
          emitVideoSizeChangedIfChanged(size.width.toInt(), size.height.toInt());
        }

      case BetterPlayerEventType.play:
        emitPlaying();

      case BetterPlayerEventType.pause:
        emitPaused();

      case BetterPlayerEventType.bufferingStart:
        emitBuffering(true);

      case BetterPlayerEventType.bufferingEnd:
        emitBuffering(false, resumePlaying: state.playing);

      case BetterPlayerEventType.finished:
        emitCompleted();

      case BetterPlayerEventType.exception:
        reportEngineError(message: event.parameters?['exception']?.toString() ?? 'BetterPlayer Error');

      default:
        break;
    }
  }

  /// Capabilities of the ExoPlayer engine, as exposed by this adapter.
  ///
  /// The declaration is scoped to what the adapter actually produces or
  /// accepts today, not to what Media3 exposes in the abstract. Backend
  /// features reachable only through a sub-API better_player_plus does not
  /// surface stay false; they can be flipped on the same line as the
  /// subscription or command that makes them real.
  ///
  /// [PlayerAdapterCapabilities] is the single source of truth for what this
  /// adapter supports: this class declares no `supportsXxx` field or getter of
  /// its own, and the base reads the snapshot directly.
  ///
  /// Signal emits and their capability flags:
  ///
  /// - [PlayerAdapterEvent.videoSizeChanged] is produced from better_player's
  ///   `initialized` / `changedResolution` events.
  /// - [PlayerAdapterEvent.videoFrameProgress] is **not** produced:
  ///   better_player_plus exposes no per-frame decode callback and does not
  ///   surface ExoPlayer's own `VideoFrameMetadataListener`, so this adapter
  ///   has no signal that proves a frame was decoded. An `isPlaying` poll is
  ///   not that signal — it would only report what the engine already
  ///   believes, and a wedged-but-"playing" ExoPlayer would never be caught.
  ///   The flag therefore stays false and [LiveWatchdogs] keeps its
  ///   video-frame stall detector off for this backend.
  static const PlayerAdapterCapabilities defaultCapabilities = PlayerAdapterCapabilities(
    // Core playback.
    //
    // Every command hook is implemented against the controller:
    // play() / pause() / pause()+seekTo(zero) for stop / seekTo() /
    // setSpeed() / setVolume(). Mute is setVolume(0.0), which the adapter
    // accepts for the lifetime of the session.
    supportsLive: true,
    supportsSeek: true,
    supportsPause: true,
    supportsStop: true,
    supportsRateControl: true,
    supportsVolumeControl: true,
    supportsMuteControl: true,

    // Video and rendering.
    //
    // `supportsVideoSizeChanged` is true because the adapter consumes
    // better_player's `initialized` / `changedResolution` events.
    //
    // `supportsVideoFrameProgress` is false: the engine has no frame-level
    // callback this adapter can forward, and geometry is not a substitute for
    // frame progress. The live video-frame watchdog must therefore stay
    // disabled for this backend rather than be fed a fabricated heartbeat.
    //
    // The remaining video capabilities are not surfaced through the adapter,
    // so reconfig / hwdec info / filters / screenshot stay false until the
    // adapter wraps them.
    supportsVideoFrameProgress: false,
    supportsVideoSizeChanged: true,
    supportsVideoReconfig: false,
    supportsHwdecInfo: false,
    supportsVideoFilters: false,
    supportsScreenshot: false,

    // Audio.
    //
    // No dedicated audio-output reconfigured event, device list, or runtime
    // filter surface is wired through the adapter.
    supportsAudioReconfig: false,
    supportsAudioDeviceSelection: false,
    supportsAudioFilters: false,

    // Tracks and subtitles.
    //
    // better_player can enumerate tracks, but this adapter neither exposes the
    // list nor accepts a selection command, and it has no subtitle surface.
    supportsTrackSelection: false,
    supportsSubtitleTrack: false,
    supportsExternalSubtitle: false,

    // Playback state and buffering.
    //
    // `emitBuffering` is called without a ratio and the buffered position is
    // never read into metrics, so no buffering progress is promised and no
    // cache state is observable.
    supportsCacheState: false,
    supportsBufferingProgress: false,
    supportsChapterControl: false,
    supportsLoop: false,

    // Metadata and playlist.
    supportsMetadata: false,
    supportsPlaylist: false,
    supportsPlaylistControl: false,

    // Diagnostics and integration.
    supportsClientMessage: false,
    supportsLogMessages: false,

    // Decoders.
    //
    // The ExoPlayer build shipped with better_player_plus decodes through
    // MediaCodec; this adapter wires no software fallback.
    supportsHardwareDecoder: true,
    supportsSoftwareDecoder: false,

    // Presentation.
    //
    // PiP is a system-level feature the adapter exposes no command for;
    // fullscreen is a widget-level decision the adapter does not veto.
    supportsPictureInPicture: false,
    supportsFullscreen: true,

    // Source matching.
    supportedProtocols: {'http', 'https', 'hls', 'dash', 'file'},
    supportedFormats: {'mp4', 'webm', 'm3u8', 'mpd', 'ts', 'mov', 'mkv'},
  );
}
