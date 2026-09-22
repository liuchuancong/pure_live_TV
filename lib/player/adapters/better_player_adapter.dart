import 'dart:async';
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
/// - BetterPlayer exceptions are treated as recoverable first because
///   BetterPlayer may retry the source internally
final class BetterPlayerAdapter extends PlayerAdapterBase {
  /// Creates the adapter.
  BetterPlayerAdapter({super.id = 'exo', super.capabilities = defaultCapabilities});

  BetterPlayerController? _controller;

  bool _isAudioOnly = false;
  bool _audioOutputSuppressed = false;

  /// Pending BetterPlayer exception.
  ///
  /// BetterPlayer may emit an exception while internally retrying the source.
  /// Do not immediately expose it to media_core.
  Timer? _pendingEngineError;

  /// Whether an exception is currently waiting for confirmation.
  bool _hasPendingEngineError = false;

  /// Whether the adapter has confirmed a terminal engine failure.
  bool _terminalEngineError = false;

  /// Gives BetterPlayer enough time to perform its internal retry.
  static const Duration _engineErrorGracePeriod = Duration(seconds: 2);

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
    _cancelPendingEngineError();
    _terminalEngineError = false;

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
  bool get engineReportsOpenFailure => _terminalEngineError;

  @override
  Future<void> onOpen(PlayerSource source) async {
    _cancelPendingEngineError();
    _terminalEngineError = false;

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
    _cancelPendingEngineError();
    _terminalEngineError = false;

    await setVolume(_audioOutputSuppressed ? 0.0 : 1.0);

    if (_audioOutputSuppressed) {
      await play();
    }
  }

  @override
  Future<void> onPlay() async {
    _cancelPendingEngineError();
    _terminalEngineError = false;

    await controller.play();
  }

  @override
  Future<void> onPause() async {
    _cancelPendingEngineError();

    await controller.pause();
  }

  @override
  Future<void> onStop() async {
    _cancelPendingEngineError();

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
    _cancelPendingEngineError();
    _terminalEngineError = false;

    await controller.pause();
    await controller.seekTo(Duration.zero);
  }

  @override
  Future<void> onDispose() async {
    _cancelPendingEngineError();

    _terminalEngineError = false;

    // better_player returns early from dispose() when autoDispose is false,
    // and this adapter sets it false to own the lifecycle itself. Without
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
    if (isDisposed || _isAudioOnly == audioOnly) {
      return;
    }

    _isAudioOnly = audioOnly;

    if (!initialized) {
      return;
    }

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
  // Engine recovery
  // ---------------------------------------------------------------------------

  /// Marks the engine as recovered and notifies media_core/UI that playback
  /// is healthy again.
  ///
  /// This is important because BetterPlayer may recover internally without
  /// emitting a new event after an `exception`.
  void _recoverFromEngineError() {
    _cancelPendingEngineError();

    _terminalEngineError = false;

    if (!acceptsEngineEvents) {
      return;
    }

    // Explicitly send a healthy playback state.
    //
    // This clears a previously reported UI error state when the underlying
    // ExoPlayer has already recovered and is actually producing playback.
    emitPlaying();
  }

  // ---------------------------------------------------------------------------
  // Engine error handling
  // ---------------------------------------------------------------------------

  /// Handles a BetterPlayer exception as a recoverable event first.
  ///
  /// BetterPlayer may do:
  ///
  ///     exception
  ///         ↓
  ///     ExoPlayer retry
  ///         ↓
  ///     playback continues
  ///
  /// In this situation the BetterPlayer controller may still expose
  /// `value.hasError == true`, even though the player is actually producing
  /// audio/video.
  ///
  /// Therefore `hasError` is NOT used to determine recovery.
  void _scheduleEngineError(BetterPlayerEvent event) {
    _cancelPendingEngineError();

    _hasPendingEngineError = true;

    final message = event.parameters?['exception']?.toString() ?? 'BetterPlayer Error';

    _pendingEngineError = Timer(_engineErrorGracePeriod, () {
      _pendingEngineError = null;

      if (!_hasPendingEngineError) {
        return;
      }

      _hasPendingEngineError = false;

      if (!acceptsEngineEvents) {
        return;
      }

      final videoController = _controller?.videoPlayerController;

      if (videoController == null) {
        _terminalEngineError = true;

        reportEngineError(message: message);

        return;
      }

      final value = videoController.value;

      // -------------------------------------------------------------------
      // Recovery
      // -------------------------------------------------------------------
      //
      // IMPORTANT:
      //
      // Do NOT check:
      //
      //     value.isPlaying && !value.hasError
      //
      // ExoPlayer may keep `hasError == true` after a recoverable source
      // error even though BetterPlayer has successfully restarted playback.
      //
      // Actual playback is the source of truth.
      if (value.isPlaying) {
        _recoverFromEngineError();
        return;
      }

      // -------------------------------------------------------------------
      // Still recovering
      // -------------------------------------------------------------------
      //
      // If BetterPlayer is buffering, do not immediately expose an error.
      // It may still be reconnecting/retrying the live stream.
      if (value.isBuffering) {
        _scheduleDelayedTerminalCheck(message);
        return;
      }

      // -------------------------------------------------------------------
      // Terminal failure
      // -------------------------------------------------------------------
      //
      // The engine is neither playing nor buffering after the recovery
      // window, so expose the failure to media_core.
      _terminalEngineError = true;

      reportEngineError(message: message);
    });
  }

  /// Performs another check when the player is still buffering.
  ///
  /// This avoids turning a temporary live-stream reconnect into an error.
  void _scheduleDelayedTerminalCheck(String message) {
    _cancelPendingEngineError();

    _hasPendingEngineError = true;

    _pendingEngineError = Timer(_engineErrorGracePeriod, () {
      _pendingEngineError = null;

      if (!_hasPendingEngineError) {
        return;
      }

      _hasPendingEngineError = false;

      if (!acceptsEngineEvents) {
        return;
      }

      final videoController = _controller?.videoPlayerController;

      if (videoController == null) {
        _terminalEngineError = true;

        reportEngineError(message: message);

        return;
      }

      final value = videoController.value;

      // BetterPlayer recovered while we were waiting.
      if (value.isPlaying) {
        _recoverFromEngineError();
        return;
      }

      // Still recovering.
      if (value.isBuffering) {
        _scheduleDelayedTerminalCheck(message);
        return;
      }

      // No playback and no buffering:
      // this is now considered a real failure.
      _terminalEngineError = true;

      reportEngineError(message: message);
    });
  }

  /// Cancels a pending recoverable engine error.
  void _cancelPendingEngineError() {
    _pendingEngineError?.cancel();
    _pendingEngineError = null;
    _hasPendingEngineError = false;
  }

  // ---------------------------------------------------------------------------
  // Engine events
  // ---------------------------------------------------------------------------

  void _onEngineEvent(BetterPlayerEvent event) {
    if (!acceptsEngineEvents) {
      return;
    }

    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.initialized:
        _terminalEngineError = false;
        _cancelPendingEngineError();

        final size = _controller?.videoPlayerController?.value.size;

        if (size != null) {
          emitVideoSizeChangedIfChanged(size.width.toInt(), size.height.toInt());
        }

      case BetterPlayerEventType.changedResolution:
        final size = _controller?.videoPlayerController?.value.size;

        if (size != null) {
          emitVideoSizeChangedIfChanged(size.width.toInt(), size.height.toInt());
        }

      case BetterPlayerEventType.play:
        // BetterPlayer explicitly told us playback resumed.
        //
        // This is a valid recovery signal even if ExoPlayer's internal
        // `hasError` flag still contains the previous Source error.
        _recoverFromEngineError();

      case BetterPlayerEventType.pause:
        _cancelPendingEngineError();

        emitPaused();

      case BetterPlayerEventType.bufferingStart:
        // Buffering is not an error.
        //
        // The player may be reconnecting/retrying the live source.
        emitBuffering(true);

      case BetterPlayerEventType.bufferingEnd:
        // BetterPlayer successfully finished buffering.
        //
        // If the UI was previously in error because of a recoverable
        // exception, explicitly restore the healthy state.
        _recoverFromEngineError();

        emitBuffering(false, resumePlaying: state.playing);

      case BetterPlayerEventType.finished:
        _cancelPendingEngineError();

        emitCompleted();

      case BetterPlayerEventType.exception:
        print('****************************************************');
        print(event.betterPlayerEventType.toString());
        print(event.parameters.toString());

        // IMPORTANT:
        //
        // Do NOT call reportEngineError() immediately.
        //
        // BetterPlayer may internally retry the source after this event.
        // Wait for actual playback recovery before deciding that the engine
        // has failed permanently.
        _scheduleEngineError(event);

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
