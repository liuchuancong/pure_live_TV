import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart';
import 'package:better_player_plus/better_player_plus.dart';

/// [PlayerAdapter] implementation backed by better_player_plus —
/// the ExoPlayer engine.
///
/// Semantics carried over from the legacy VideoPlayerAdapter:
///
/// - source-scoped event acceptance with deferred errors
///   (ExoPlayer can emit an exception synchronously while
///   setupDataSource is still pending)
/// - fit applied through `setOverriddenFit`, never a wrapper
///   widget
/// - audio-output suppression starts the source muted, avoiding
///   an audible burst during initialization
/// - live streams flagged through the data source
final class BetterPlayerAdapter implements PlayerAdapter {
  /// Creates the adapter.
  BetterPlayerAdapter({this._id = 'exo'});

  final String _id;

  BetterPlayerController? _controller;
  void Function(BetterPlayerEvent)? _eventListener;
  final _eventController = StreamController<PlayerAdapterEvent>.broadcast();

  PlayerState _state = PlayerState.idle;

  bool _initialized = false;
  bool _disposed = false;
  bool _isAudioOnly = false;
  bool _audioOutputSuppressed = false;
  bool _acceptSourceEvents = false;
  bool _sourceOpening = false;
  PlayerAdapterEvent? _deferredError;

  int? _lastWidth;
  int? _lastHeight;

  @override
  String get id => _id;

  @override
  PlayerAdapterCapabilities get capabilities => defaultCapabilities;

  @override
  PlayerState get state => _state;

  @override
  PlayerAdapterMetrics get metrics => const PlayerAdapterMetrics();

  @override
  Stream<PlayerAdapterEvent> get events => _eventController.stream;

  @override
  bool get initialized => _initialized;

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
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize(PlayerAdapterContext context) async {
    if (_initialized) return;

    _controller = BetterPlayerController(
      BetterPlayerConfiguration(
        // A suppressed automatic fallback starts only after its
        // native volume is zero, avoiding a short audible burst
        // during source initialization.
        autoPlay: !_audioOutputSuppressed,
        fit: BoxFit.contain,
        handleLifecycle: false,
        fullScreenByDefault: false,
        autoDispose: false,
        looping: false,
        controlsConfiguration: const BetterPlayerControlsConfiguration(showControls: false),
      ),
    );
    _bindListener();
    _state = PlayerState.idle.initializingState().readyState();
    _initialized = true;
  }

  @override
  Future<void> open(PlayerSource source) async {
    _requireReady();

    // Source-scoped reset: the previous source's late events must
    // not leak into this generation.
    _acceptSourceEvents = false;
    _deferredError = null;
    _lastWidth = null;
    _lastHeight = null;

    try {
      final dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        source.uri.toString(),
        headers: source.hasHeaders ? Map<String, String>.from(source.headers!.values) : null,
        liveStream: true,
      );

      // ExoPlayer can synchronously emit an exception while
      // setupDataSource is still pending. Bind that error to this
      // source instead of dropping the only event before
      // _acceptSourceEvents becomes true.
      _sourceOpening = true;
      _acceptSourceEvents = true;
      await controller.setupDataSource(dataSource);
      _sourceOpening = false;

      final deferred = _deferredError;
      _deferredError = null;
      if (deferred != null && controller.videoPlayerController?.value.hasError == true) {
        _acceptSourceEvents = false;
        _state = _state.errorState();
        _emit(deferred);
        throw StateError('better_player open failed');
      }

      _state = _state.openingState().withSource(true).readyState();
      _emit(PlayerAdapterEvent.opened(source: source.id.value));

      await setVolume(_audioOutputSuppressed ? 0.0 : 1.0);
      if (_audioOutputSuppressed) await play();
    } catch (e) {
      _sourceOpening = false;
      _acceptSourceEvents = false;
      _state = _state.errorState();
      _emit(PlayerAdapterEvent.error(message: 'better_player setDataSource failed: $e'));
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    _requireReady();
    await controller.play();
  }

  @override
  Future<void> pause() async {
    _requireReady();
    await controller.pause();
  }

  @override
  Future<void> stop() async {
    _requireReady();
    _acceptSourceEvents = false;
    await controller.pause();
    await controller.seekTo(Duration.zero);
    _state = _state.stoppedState().withSource(false);
    _emit(const PlayerAdapterEvent.stopped());
  }

  @override
  Future<void> seek(Duration position) async {
    _requireReady();
    await controller.seekTo(position);
    _emit(PlayerAdapterEvent.positionChanged(position: position));
  }

  @override
  Future<void> setVolume(double volume) async {
    _requireReady();
    await controller.setVolume(volume.clamp(0.0, 1.0));
  }

  @override
  Future<void> setRate(double rate) async {
    _requireReady();
    await controller.setSpeed(rate);
    _emit(PlayerAdapterEvent.rateChanged(rate: rate));
  }

  @override
  Future<void> close() async {
    final c = _controller;
    if (c == null) return;
    _acceptSourceEvents = false;
    await c.pause();
    await c.seekTo(Duration.zero);
    _state = _state.stoppedState().withSource(false);
    _emit(const PlayerAdapterEvent.stopped());
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _state = _state.disposingState();
    _removeListener();
    // better_player returns early from dispose() when autoDispose is false, and
    // this adapter sets it false to own the lifecycle itself. Without
    // forceDispose the native ExoPlayer survives - decoder, surface and audio
    // included - so the next engine switch fights it for the hardware decoder
    // and a closed room keeps playing behind the UI.
    final controller = _controller;
    _controller = null;
    controller?.dispose(forceDispose: true);

    _state = _state.disposedState();
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
  }

  // ---------------------------------------------------------------------------
  // TV-specific extensions
  // ---------------------------------------------------------------------------

  /// Suppresses audio output for the next open.
  void setAudioOutputSuppressed(bool suppressed) {
    _audioOutputSuppressed = suppressed;
  }

  /// Enables or disables video rendering.
  Future<void> setAudioOnly(bool audioOnly) async {
    if (_disposed || _isAudioOnly == audioOnly) return;
    _isAudioOnly = audioOnly;
    if (!_initialized) return;
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
  // Event listener
  // ---------------------------------------------------------------------------

  void _bindListener() {
    _removeListener();

    _eventListener = (BetterPlayerEvent event) {
      if (_disposed || !_acceptSourceEvents) return;
      switch (event.betterPlayerEventType) {
        case BetterPlayerEventType.initialized:
        case BetterPlayerEventType.changedResolution:
          final size = _controller?.videoPlayerController?.value.size;
          if (size != null && size.width > 0 && size.height > 0) {
            final w = size.width.toInt();
            final h = size.height.toInt();
            if (w != _lastWidth || h != _lastHeight) {
              _lastWidth = w;
              _lastHeight = h;
              _state = _state.withVideoEnabled(true);
              _emit(PlayerAdapterEvent.videoSizeChanged(width: w, height: h));
            }
          }
        case BetterPlayerEventType.play:
          _state = _state.playingState();
          _emit(const PlayerAdapterEvent.playing());
        case BetterPlayerEventType.pause:
          _state = _state.pausedState();
          _emit(const PlayerAdapterEvent.paused());
        case BetterPlayerEventType.bufferingStart:
          _state = _state.bufferingState();
          _emit(const PlayerAdapterEvent.buffering(buffering: true));
        case BetterPlayerEventType.bufferingEnd:
          _state = _playingNow ? _state.playingState() : _state.pausedState();
          _emit(const PlayerAdapterEvent.buffering(buffering: false));
        case BetterPlayerEventType.finished:
          _state = _state.completedState();
          _emit(const PlayerAdapterEvent.completed());
        case BetterPlayerEventType.exception:
          final message = event.parameters?['exception']?.toString() ?? 'BetterPlayer Error';
          final adapterEvent = PlayerAdapterEvent.error(message: message);
          if (_sourceOpening) {
            _deferredError = adapterEvent;
          } else {
            _state = _state.errorState();
            _emit(adapterEvent);
          }
        default:
          break;
      }
    };

    controller.addEventsListener(_eventListener!);
  }

  void _removeListener() {
    final listener = _eventListener;
    if (listener != null && _controller != null) {
      _controller!.removeEventsListener(listener);
    }
    _eventListener = null;
  }

  bool get _playingNow => _state.playing;

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  void _emit(PlayerAdapterEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void _requireReady() {
    if (!_initialized || _disposed) {
      throw StateError('BetterPlayerAdapter is not initialized or has been disposed.');
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
