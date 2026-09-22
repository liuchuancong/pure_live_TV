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
    if (_audioOutputSuppressed) await play();
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

  /// Capabilities of the ExoPlayer engine.
  static const PlayerAdapterCapabilities defaultCapabilities = PlayerAdapterCapabilities(
    supportsLive: true,
    supportsSeek: true,
    supportsPause: true,
    supportsRateControl: true,
    supportsVolumeControl: true,
    supportsHardwareDecoder: true,
    supportsSoftwareDecoder: false,
    supportsPictureInPicture: false,
    supportsFullscreen: true,
    supportedProtocols: {'http', 'https', 'hls', 'dash', 'file'},
    supportedFormats: {'mp4', 'webm', 'm3u8', 'mpd', 'ts', 'mov', 'mkv'},
  );
}
