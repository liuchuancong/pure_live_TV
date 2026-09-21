import 'dart:async';
import 'fijk_view_holder.dart';
import '../utils/fijk_helper.dart';
import 'package:flutter/material.dart';
import 'package:flv_lzc/fijkplayer.dart';
import 'package:media_core/media_core.dart';
import '../core/playback_proxy_policy.dart';



/// [PlayerAdapter] implementation backed by the local flv_lzc
/// (fijkplayer) plugin — the IJK engine.
///
/// Mirrors the semantics the legacy FijkAdapter established:
///
/// - source-scoped event acceptance (a listener installed during
///   open must not deliver the previous source's events)
/// - deferred native errors (FijkState.error can arrive before
///   setDataSource completes)
/// - proxy option for the app-owned loopback input
/// - audio-only via the `disable-vid` player option
/// - the view is exposed through [FijkViewHolder] so the surface
///   layer can rebuild without owning the adapter
final class FlvLzcPlayerAdapter implements PlayerAdapter {
  /// Creates the adapter.
  FlvLzcPlayerAdapter({this.id = 'ijk', FijkPlayer? player}) : _injectedPlayer = player;

  @override
  final String id;
  final FijkPlayer? _injectedPlayer;

  late final FijkPlayer _player = _injectedPlayer ?? FijkPlayer();
  final _eventController = StreamController<PlayerAdapterEvent>.broadcast();

  PlayerState _state = PlayerState.idle;
  final PlayerAdapterMetrics _metrics = const PlayerAdapterMetrics();

  bool _initialized = false;
  bool _disposed = false;
  bool _isAudioOnly = false;
  bool _acceptSourceEvents = false;
  bool _sourceOpening = false;
  bool _sourceBuffering = false;
  bool _privateInput = false;
  PlayerAdapterEvent? _deferredError;

  Duration _lastPosition = Duration.zero;
  int? _lastWidth;
  int? _lastHeight;

  BoxFit _videoFit = BoxFit.contain;

  @override
  PlayerAdapterCapabilities get capabilities => defaultCapabilities;

  @override
  PlayerState get state => _state;

  @override
  PlayerAdapterMetrics get metrics => _metrics;

  @override
  Stream<PlayerAdapterEvent> get events => _eventController.stream;

  @override
  bool get initialized => _initialized;

  /// The underlying FijkPlayer.
  FijkPlayer get fijkPlayer => _player;

  /// The holder surface widgets bind to.
  FijkViewHolder get viewHolder => _viewHolder;
  final FijkViewHolder _viewHolder = FijkViewHolder();

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize(PlayerAdapterContext context) async {
    if (_initialized) return;
    _state = PlayerState.idle.initializingState().readyState();

    _player.addListener(_onPlayerValue);
    if (_isAudioOnly) {
      await _player.setOption(FijkOption.playerCategory, 'disable-vid', 1);
    }
    _initialized = true;
  }

  @override
  Future<void> open(PlayerSource source) async {
    _requireReady();

    // Source-scoped listener reset: the previous source's late
    // events must not leak into this generation.
    _acceptSourceEvents = false;
    _sourceBuffering = false;
    _deferredError = null;
    _lastPosition = Duration.zero;
    _lastWidth = null;
    _lastHeight = null;

    final privateInput = _privateInput;
    _privateInput = false;

    try {
      if (_player.state != FijkState.idle) {
        await _player.reset();
      }
      await _player.setOption(
        FijkOption.formatCategory,
        'http_proxy',
        PlaybackProxyPolicy.currentNativeUrl(privateInput: privateInput),
      );
      await FijkHelper.setFijkOption(
        _player,
        disableAudioOutput: false,
        headers: source.hasHeaders ? Map<String, String>.from(source.headers!.values) : null,
      );

      _sourceOpening = true;
      _acceptSourceEvents = true;
      await _player.setDataSource(source.uri.toString(), autoPlay: true);
      _sourceOpening = false;

      final deferred = _deferredError;
      _deferredError = null;
      if (deferred != null && _player.value.state == FijkState.error) {
        _acceptSourceEvents = false;
        _state = _state.errorState();
        _emit(deferred);
        throw StateError('flv_lzc open failed');
      }

      _state = _state.openingState().withSource(true).readyState();
      _emit(PlayerAdapterEvent.opened(source: source.id.value));
    } catch (e) {
      _sourceOpening = false;
      _acceptSourceEvents = false;
      _state = _state.errorState();
      _emit(PlayerAdapterEvent.error(message: 'flv_lzc setDataSource failed: $e'));
      rethrow;
    }
  }

  @override
  Future<void> play() async {
    _requireReady();
    await _player.start();
  }

  @override
  Future<void> pause() async {
    _requireReady();
    await _player.pause();
  }

  @override
  Future<void> stop() async {
    _requireReady();
    _acceptSourceEvents = false;
    _sourceBuffering = false;
    await _player.stop();
    _state = _state.stoppedState().withSource(false);
    _emit(const PlayerAdapterEvent.stopped());
  }

  @override
  Future<void> seek(Duration position) async {
    _requireReady();
    await _player.seekTo(position.inMilliseconds);
    _emit(PlayerAdapterEvent.positionChanged(position: position));
  }

  @override
  Future<void> setVolume(double volume) async {
    _requireReady();
    await _player.setVolume(volume.clamp(0.0, 1.0));
  }

  @override
  Future<void> setRate(double rate) async {
    _requireReady();
    // soundtouch enables tempo processing for rates != 1.0.
    await _player.setOption(FijkOption.playerCategory, 'soundtouch', rate != 1.0 ? 1 : 0);
    await _player.setSpeed(rate);
    _emit(PlayerAdapterEvent.rateChanged(rate: rate));
  }

  @override
  Future<void> close() async {
    if (!_initialized) return;
    _acceptSourceEvents = false;
    _sourceBuffering = false;
    await _player.reset();
    _state = _state.stoppedState().withSource(false);
    _emit(const PlayerAdapterEvent.stopped());
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _state = _state.disposingState();
    _player.removeListener(_onPlayerValue);

    try {
      await _player.release();
    } catch (_) {
      // Release races surface here on some devices; disposal
      // continues regardless.
    }

    _state = _state.disposedState();
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
  }

  // ---------------------------------------------------------------------------
  // TV-specific extensions
  // ---------------------------------------------------------------------------

  /// Whether the next open bypasses the native proxy.
  ///
  /// The source manager supplies an app-owned loopback input; the
  /// proxy must not intercept it.
  void setPrivateInput(bool value) => _privateInput = value;

  /// Enables or disables video decoding without replacing the
  /// player or reopening the current live stream.
  Future<void> setAudioOnly(bool audioOnly) async {
    if (_disposed || _isAudioOnly == audioOnly) return;
    await _player.setOption(FijkOption.playerCategory, 'disable-vid', audioOnly ? 1 : 0);
    _isAudioOnly = audioOnly;
  }

  /// Applies the viewport fit without wrapping the texture in a
  /// transformed widget.
  void setVideoFit(BoxFit fit) {
    _videoFit = fit;
    _viewHolder.updateFit(fit);
  }

  /// The current viewport fit.
  BoxFit get videoFit => _videoFit;

  // ---------------------------------------------------------------------------
  // Value listener
  // ---------------------------------------------------------------------------

  void _onPlayerValue() {
    if (_disposed || !_acceptSourceEvents) return;
    final value = _player.value;
    final state = value.state;

    // Dimensions.
    final size = value.size;
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

    // Buffering updates drive loading, independent of state.
    // FijkState.started can persist through buffering.
    if (state == FijkState.asyncPreparing || state == FijkState.prepared) {
      if (!_sourceBuffering) {
        _sourceBuffering = true;
        _state = _state.bufferingState();
        _emit(const PlayerAdapterEvent.buffering(buffering: true));
      }
    }

    switch (state) {
      case FijkState.started:
        if (_sourceBuffering) {
          _sourceBuffering = false;
          _emit(const PlayerAdapterEvent.buffering(buffering: false));
        }
        _state = _state.playingState();
        _emit(const PlayerAdapterEvent.playing());
      case FijkState.paused:
        _state = _state.pausedState();
        _emit(const PlayerAdapterEvent.paused());
      case FijkState.completed:
      case FijkState.end:
        _state = _state.completedState();
        _emit(const PlayerAdapterEvent.completed());
      case FijkState.error:
        final native = value.exception;
        final event = PlayerAdapterEvent.error(
          message: 'fijk error ${native.code}: ${native.message ?? 'native playback failure'}',
        );
        if (_sourceOpening) {
          _deferredError = event;
        } else {
          _state = _state.errorState();
          _emit(event);
        }
      case FijkState.stopped:
      case FijkState.idle:
      case FijkState.initialized:
      case FijkState.asyncPreparing:
      case FijkState.prepared:
        break;
    }

    // Duration (live streams report zero).
    final duration = value.duration;
    if (duration > Duration.zero && duration != _lastPosition) {
      _lastPosition = duration;
      _emit(PlayerAdapterEvent.durationChanged(duration: duration));
    }
  }

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
      throw StateError('FlvLzcPlayerAdapter is not initialized or has been disposed.');
    }
  }

  /// Capabilities of the IJK engine.
  static const PlayerAdapterCapabilities defaultCapabilities = PlayerAdapterCapabilities(
    supportsLive: true,
    supportsSeek: true,
    supportsPause: true,
    supportsRateControl: false,
    supportsVolumeControl: true,
    supportsHardwareDecoder: true,
    supportsSoftwareDecoder: true,
    supportsPictureInPicture: false,
    supportsFullscreen: true,
    supportedProtocols: {'http', 'https', 'hls', 'rtmp', 'rtsp', 'udp', 'file', 'asset'},
    supportedFormats: {'mp4', 'mkv', 'webm', 'flv', 'm3u8', 'mov', 'avi', 'ts', 'h265', 'hevc'},
  );
}
