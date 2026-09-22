import 'fijk_view_holder.dart';
import '../utils/fijk_helper.dart';
import 'package:flutter/material.dart';
import 'package:flv_lzc/fijkplayer.dart';
import 'package:media_core/media_core.dart';
import '../../services/settings/settings.dart';
import '../core/playback_proxy_policy.dart';

/// [PlayerAdapter] implementation backed by the local flv_lzc
/// (fijkplayer) plugin — the IJK engine.
///
/// Engine semantics:
///
/// - source-scoped event acceptance and deferred native errors
///   (FijkState.error can arrive before setDataSource completes) —
///   provided by the base
/// - proxy option for the app-owned loopback input
/// - audio-only via the `disable-vid` player option
/// - the view is exposed through [FijkViewHolder] so the surface
///   layer can rebuild without owning the adapter
final class FlvLzcPlayerAdapter extends PlayerAdapterBase {
  /// Creates the adapter.
  FlvLzcPlayerAdapter({super.id = 'ijk', super.capabilities = defaultCapabilities, FijkPlayer? player})
      : _injectedPlayer = player;

  final FijkPlayer? _injectedPlayer;
  late final FijkPlayer _player = _injectedPlayer ?? FijkPlayer();

  bool _isAudioOnly = false;
  bool _sourceBuffering = false;
  bool _privateInput = false;
  Duration _lastDuration = Duration.zero;

  BoxFit _videoFit = BoxFit.contain;

  /// The underlying FijkPlayer.
  FijkPlayer get fijkPlayer => _player;

  /// The holder surface widgets bind to.
  FijkViewHolder get viewHolder => _viewHolder;
  final FijkViewHolder _viewHolder = FijkViewHolder();

  // ---------------------------------------------------------------------------
  // Engine contract
  // ---------------------------------------------------------------------------

  @override
  Future<void> onInitialize(PlayerAdapterContext context) async {
    _player.addListener(_onPlayerValue);
    if (_isAudioOnly) {
      await _player.setOption(FijkOption.playerCategory, 'disable-vid', 1);
    }
  }

  @override
  bool get engineReportsOpenFailure => _player.value.state == FijkState.error;

  @override
  Future<void> onOpen(PlayerSource source) async {
    final privateInput = _privateInput;
    _privateInput = false;

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
      enableCodec: SettingsService.to.playerState.enableCodec,
      disableAudioOutput: false,
      headers: source.hasHeaders ? Map<String, String>.from(source.headers!.values) : null,
    );
    await _player.setDataSource(source.uri.toString(), autoPlay: true);
  }

  @override
  Future<void> onPlay() => _player.start();

  @override
  Future<void> onPause() => _player.pause();

  @override
  Future<void> onStop() async {
    _sourceBuffering = false;
    await _player.stop();
  }

  @override
  Future<void> onSeek(Duration position) => _player.seekTo(position.inMilliseconds);

  @override
  Future<void> onSetVolume(double volume) => _player.setVolume(volume.clamp(0.0, 1.0));

  @override
  Future<void> onSetRate(double rate) async {
    // soundtouch enables tempo processing for rates != 1.0.
    await _player.setOption(FijkOption.playerCategory, 'soundtouch', rate != 1.0 ? 1 : 0);
    await _player.setSpeed(rate);
  }

  @override
  Future<void> onClose() async {
    _sourceBuffering = false;
    await _player.reset();
  }

  @override
  Future<void> onDispose() async {
    _player.removeListener(_onPlayerValue);

    try {
      await _player.release();
    } catch (_) {
      // Release races surface here on some devices; disposal
      // continues regardless.
    }
  }

  // ---------------------------------------------------------------------------
  // TV extensions
  // ---------------------------------------------------------------------------

  /// Whether the next open bypasses the native proxy.
  ///
  /// The source manager supplies an app-owned loopback input; the
  /// proxy must not intercept it.
  void setPrivateInput(bool value) => _privateInput = value;

  /// Enables or disables video decoding without replacing the
  /// player or reopening the current live stream.
  Future<void> setAudioOnly(bool audioOnly) async {
    if (isDisposed || _isAudioOnly == audioOnly) return;
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
    if (!acceptsEngineEvents) return;
    final value = _player.value;
    final state = value.state;

    // Dimensions.
    final size = value.size;
    if (size != null) {
      emitVideoSizeChangedIfChanged(size.width.toInt(), size.height.toInt());
    }

    // Buffering updates drive loading, independent of state.
    // FijkState.started can persist through buffering.
    if (state == FijkState.asyncPreparing || state == FijkState.prepared) {
      if (!_sourceBuffering) {
        _sourceBuffering = true;
        emitBuffering(true);
      }
    }

    switch (state) {
      case FijkState.started:
        if (_sourceBuffering) {
          _sourceBuffering = false;
          emitBuffering(false);
        }
        emitPlaying();
      case FijkState.paused:
        emitPaused();
      case FijkState.completed:
      case FijkState.end:
        emitCompleted();
      case FijkState.error:
        final native = value.exception;
        reportEngineError(message: 'fijk error ${native.code}: ${native.message ?? 'native playback failure'}');
      case FijkState.stopped:
      case FijkState.idle:
      case FijkState.initialized:
      case FijkState.asyncPreparing:
      case FijkState.prepared:
        break;
    }

    // Duration (live streams report zero).
    final duration = value.duration;
    if (duration > Duration.zero && duration != _lastDuration) {
      _lastDuration = duration;
      emitDurationChanged(duration);
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
