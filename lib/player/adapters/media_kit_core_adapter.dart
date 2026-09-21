import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart' hide PlatformUtils;
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;

import '../../services/settings/settings.dart';
import '../../shared/utils/platform_utils.dart';
import '../core/playback_proxy_policy.dart';
import '../utils/live_buffer_policy.dart';
import '../utils/mpv_platform_profile.dart';
import 'media_kit_view_holder.dart';



/// [PlayerAdapter] implementation backed by the local media_kit
/// snapshot — the MPV engine.
///
/// TV semantics carried over from the legacy adapter:
///
/// - decoded-frame heartbeats via mpv property observers
///   (`decoded-picture-type` / `container-fps`) so the live
///   watchdog can detect a wedged decoder
/// - software-decoder fallback marked for the *next* open (never
///   mutated mid-failure)
/// - viewport fit applied through `Video(fit:)`, not a wrapper
///   widget
/// - proxy option for the app-owned loopback input
final class PureLiveMediaKitAdapter implements PlayerAdapter {
  /// Creates the adapter.
  PureLiveMediaKitAdapter({this.id = 'mpv', mk.Player? player}) : _injectedPlayer = player;

  @override
  final String id;
  final mk.Player? _injectedPlayer;

  mk.Player? _player;
  mkv.VideoController? _videoController;
  final _eventController = StreamController<PlayerAdapterEvent>.broadcast();
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  PlayerState _state = PlayerState.idle;
  PlayerAdapterMetrics _metrics = const PlayerAdapterMetrics();

  bool _initialized = false;
  bool _disposed = false;
  bool _isAudioOnly = false;
  bool _privateInput = false;
  bool _softwareDecoderNextOpen = false;
  // Read by setAudioOutputSuppressed callers before open; kept
  // for parity with the legacy adapter surface.
  // ignore: unused_field
  bool _audioOutputSuppressed = false;
  String? _currentUrl;

  bool _playingNow = false;
  bool _bufferingNow = false;
  bool _hasOpened = false;
  int? _width;
  int? _height;
  double _lastEmittedVolume = -1.0;

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

  /// The underlying media_kit player.
  ///
  /// Throws [StateError] before [initialize].
  mk.Player get player {
    final p = _player;
    if (p == null) {
      throw StateError('PureLiveMediaKitAdapter has not been initialized.');
    }
    return p;
  }

  /// The video controller surface widgets bind to.
  mkv.VideoController? get videoController => _videoController;

  /// The holder surface widgets watch.
  MediaKitViewHolder get viewHolder => _viewHolder;
  final MediaKitViewHolder _viewHolder = MediaKitViewHolder();

  /// Whether decoded video frames have been observed for the
  /// current source.
  bool get hasDecodedVideoFrame => _hasDecodedVideoFrame;
  bool _hasDecodedVideoFrame = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize(PlayerAdapterContext context) async {
    if (_initialized) return;

    _player = _injectedPlayer ?? mk.Player();
    _resolvePreferredHardwareDecoder();
    _videoController = _buildVideoController();
    _state = PlayerState.idle.initializingState().readyState();

    _subscribeStreams();
    _observeDecodedFrames();
    await _applyNativeLiveProperties();
    _initialized = true;
  }

  /// Resolves the hardware decoder preference from settings.
  ///
  /// Three tiers, mirroring the legacy adapter:
  /// - macOS: always software (`no`) — VideoToolbox was unstable.
  /// - Android compat mode: force `mediacodec`.
  /// - Expert output configured: the user-picked decoder.
  /// - Default: `enableCodec ? auto-safe : no`.
  void _resolvePreferredHardwareDecoder() {
    final settings = SettingsService.to.playerState;
    final androidCompatMode = PlatformUtils.isAndroid && settings.playerCompatMode;
    final hardwareDecoder = normalizeMpvHardwareDecoderForPlatform(settings.videoHardwareDecoder, defaultTargetPlatform);

    _preferredHardwareDecoder = PlatformUtils.isMacOS
        ? 'no'
        : androidCompatMode
        ? 'mediacodec'
        : settings.customPlayerOutput
        ? hardwareDecoder
        : settings.enableCodec
        ? 'auto-safe'
        : 'no';
  }

  /// Builds the video controller with the settings-appropriate
  /// output configuration.
  mkv.VideoController _buildVideoController() {
    final settings = SettingsService.to.playerState;
    final platform = defaultTargetPlatform;
    final androidCompatMode = PlatformUtils.isAndroid && settings.playerCompatMode;
    final videoOutputDriver = normalizeMpvVideoOutputDriverForPlatform(settings.videoOutputDriver, platform);

    if (androidCompatMode) {
      return mkv.VideoController(
        player,
        configuration: const mkv.VideoControllerConfiguration(vo: 'mediacodec_embed', hwdec: 'mediacodec'),
      );
    }
    if (settings.customPlayerOutput) {
      return mkv.VideoController(
        player,
        configuration: mkv.VideoControllerConfiguration(
          vo: videoOutputDriver,
          hwdec: PlatformUtils.isMacOS ? 'no' : normalizeMpvHardwareDecoderForPlatform(settings.videoHardwareDecoder, platform),
          enableHardwareAcceleration: !PlatformUtils.isMacOS,
        ),
      );
    }
    return mkv.VideoController(
      player,
      configuration: mkv.VideoControllerConfiguration(
        enableHardwareAcceleration: PlatformUtils.isMacOS ? false : settings.enableCodec,
        hwdec: PlatformUtils.isMacOS ? 'no' : null,
      ),
    );
  }

  /// Applies the native live-stream property contract to mpv.
  ///
  /// Fast live probing, a bounded buffer budget (see
  /// [LiveBufferPolicy]), direct surface rendering on Android and
  /// the configured audio output driver.
  Future<void> _applyNativeLiveProperties() async {
    final native = _player?.platform;
    if (native == null) return;

    Future<void> setProp(String name, String value) async {
      try {
        // ignore: avoid_dynamic_calls
        await (native as dynamic).setProperty(name, value);
      } catch (_) {
        // Property support varies across builds; each is
        // best-effort.
      }
    }

    await setProp('protocol_whitelist', 'httpproxy,udp,rtp,tcp,tls,data,file,http,https,crypto,rtmp,rtmps,rtsp,srt');
    await setProp('demuxer-lavf-probesize', '2097152');
    // Short probe for live FLV/HLS: less black screen before the
    // first frame.
    await setProp('demuxer-lavf-analyzeduration', '2');
    await LiveBufferPolicy.apply(setProp);
    await setProp('network-timeout', '15');
    // Drop a failing hw decoder after one bad frame so playback
    // falls back to software instead of a black surface.
    await setProp('hwdec-software-fallback', '1');

    if (PlatformUtils.isAndroid) {
      // mediacodec surface direct rendering: frames go straight
      // from the decoder to the display surface, skipping both
      // the copy to RAM and the Flutter texture round-trip.
      await setProp('mediacodec-surface-iostream', 'yes');
      await setProp('mediacodec-embed-surface-landscape', 'yes');
    }

    final audioOutput = effectiveMpvAudioOutputDriverForPlatform(
      customOutput: SettingsService.to.playerState.customPlayerOutput,
      configuredDriver: SettingsService.to.playerState.audioOutputDriver,
      platform: defaultTargetPlatform,
    );
    if (audioOutput != null) {
      await setProp('ao', audioOutput);
    }

    if (PlatformUtils.isMacOS) {
      await setProp('hwdec', 'no');
    }

    if (PlatformUtils.isWindows && SettingsService.to.playerState.enableRtxVsr) {
      await setProp('hwdec', 'd3d11va');
      await setProp('vf', 'd3d11vpp=scale=2:scaling-mode=nvidia');
    }
  }

  /// The resolved hardware decoder preference.
  String get preferredHardwareDecoder => _preferredHardwareDecoder;
  String _preferredHardwareDecoder = 'auto';

  @override
  Future<void> open(PlayerSource source) async {
    _requireReady();

    final url = source.uri.toString();
    final headers = source.hasHeaders ? source.headers!.values : null;

    _currentUrl = url;
    _hasDecodedVideoFrame = false;
    _softwareDecoderNextOpen = _softwareDecoderNextOpen && url == _currentUrl;

    await _applyDecoderPolicy(url);
    await _applyProxy();

    await player.open(mk.Media(url, httpHeaders: headers), play: true);

    _hasOpened = true;
    _state = _state.openingState().withSource(true).readyState();
    _emit(PlayerAdapterEvent.opened(source: source.id.value));
  }

  @override
  Future<void> play() async {
    _requireReady();
    await player.play();
    _state = _state.playingState();
    _emit(const PlayerAdapterEvent.playing());
  }

  @override
  Future<void> pause() async {
    _requireReady();
    await player.pause();
    _state = _state.pausedState();
    _emit(const PlayerAdapterEvent.paused());
  }

  @override
  Future<void> stop() async {
    _requireReady();
    await player.stop();
    _playingNow = false;
    _bufferingNow = false;
    _hasOpened = false;
    _state = _state.stoppedState().withSource(false);
    _emit(const PlayerAdapterEvent.stopped());
  }

  @override
  Future<void> seek(Duration position) async {
    _requireReady();
    await player.seek(position);
    _emit(PlayerAdapterEvent.positionChanged(position: position));
  }

  @override
  Future<void> setVolume(double volume) async {
    _requireReady();
    await player.setVolume((volume.clamp(0.0, 1.0)) * 100.0);
  }

  @override
  Future<void> setRate(double rate) async {
    _requireReady();
    await player.setRate(rate);
    _emit(PlayerAdapterEvent.rateChanged(rate: rate));
  }

  @override
  Future<void> close() async {
    if (!_initialized || _player == null) return;
    await player.stop();
    _hasOpened = false;
    _playingNow = false;
    _bufferingNow = false;
    _state = _state.stoppedState().withSource(false);
    _emit(const PlayerAdapterEvent.stopped());
  }

  @override
  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;

    _state = _state.disposingState();

    await Future.wait(_subscriptions.map((s) => s.cancel()));
    _subscriptions.clear();

    await _player?.dispose();
    _player = null;
    _videoController = null;

    _state = _state.disposedState();
    if (!_eventController.isClosed) {
      await _eventController.close();
    }
  }

  // ---------------------------------------------------------------------------
  // TV-specific extensions
  // ---------------------------------------------------------------------------

  /// Whether the next open bypasses the native proxy.
  void setPrivateInput(bool value) => _privateInput = value;

  /// Marks that the next open of the current source should use
  /// software decoding.
  ///
  /// Called by recovery when a codec error suggests the hardware
  /// decoder is wedged. Only the next open applies it; mutating
  /// `hwdec` mid-failure can re-enter the error path.
  void prepareSoftwareDecoderFallback() {
    _softwareDecoderNextOpen = true;
  }

  /// Suppresses audio output for the next open (an explicitly
  /// selected null audio output must survive engine fallback).
  Future<void> setAudioOutputSuppressed(bool suppressed) async {
    _audioOutputSuppressed = suppressed;
    if (suppressed) {
      try {
        await player.setAudioTrack(mk.AudioTrack.no());
      } catch (_) {
        // Best-effort; some builds reject track selection before open.
      }
    }
  }

  /// Enables or disables the video track.
  Future<void> setAudioOnly(bool audioOnly) async {
    if (_disposed || _isAudioOnly == audioOnly) return;
    _isAudioOnly = audioOnly;
    if (!_initialized) return;
    await player.setVideoTrack(audioOnly ? mk.VideoTrack.no() : mk.VideoTrack.auto());
  }

  /// Applies the viewport fit through the Video widget.
  void setVideoFit(BoxFit fit) {
    _videoFit = fit;
    _viewHolder.updateFit(fit);
  }

  /// The current viewport fit.
  BoxFit get videoFit => _videoFit;

  // ---------------------------------------------------------------------------
  // Stream wiring
  // ---------------------------------------------------------------------------

  void _subscribeStreams() {
    final s = player.stream;

    _subscriptions.add(s.playing.listen(_onPlaying));
    _subscriptions.add(s.completed.listen(_onCompleted));
    _subscriptions.add(s.buffering.listen(_onBuffering));
    _subscriptions.add(s.position.listen(_onPosition));
    _subscriptions.add(s.duration.listen(_onDuration));
    _subscriptions.add(s.volume.listen(_onVolume));
    _subscriptions.add(s.width.listen(_onWidth));
    _subscriptions.add(s.height.listen(_onHeight));
    _subscriptions.add(s.error.listen(_onError));
    _subscriptions.add(s.buffer.listen(_onBuffer));
  }

  void _observeDecodedFrames() {
    // Decoded-frame heartbeats: any observed frame proves the
    // decoder is alive. The live watchdog uses this to detect a
    // wedged decoder that still reports playing=true.
    try {
      final native = player.platform;
      // ignore: avoid_dynamic_calls
      (native as dynamic).observeProperty?.call('decoded-picture-type', (String value) {
        final type = value.trim().toUpperCase();
        if (type == 'I' || type == 'P' || type == 'B') {
          _hasDecodedVideoFrame = true;
          _viewHolder.notifyFrameProgress();
        }
      });
    } catch (_) {
      // observeProperty is a NativePlayer extension; platforms
      // without it simply fall back to size-based progress.
    }
  }

  void _onPlaying(bool playing) {
    if (_playingNow == playing) return;
    _playingNow = playing;

    if (playing) {
      _state = _state.withSource(true).playingState();
      _emit(const PlayerAdapterEvent.playing());
    } else if (_hasOpened && !_state.stopped && !_state.completed) {
      _state = _state.pausedState();
      _emit(const PlayerAdapterEvent.paused());
    }
  }

  void _onCompleted(bool completed) {
    if (!completed) return;
    _playingNow = false;
    _state = _state.completedState();
    _emit(const PlayerAdapterEvent.completed());
  }

  void _onBuffering(bool buffering) {
    if (_bufferingNow == buffering) return;
    _bufferingNow = buffering;

    if (buffering) {
      _state = _state.bufferingState();
    } else {
      _state = _playingNow ? _state.playingState() : _state.pausedState();
    }
    _emit(PlayerAdapterEvent.buffering(buffering: buffering));
  }

  void _onPosition(Duration position) {
    _emit(PlayerAdapterEvent.positionChanged(position: position));
  }

  void _onDuration(Duration duration) {
    _emit(PlayerAdapterEvent.durationChanged(duration: duration));
  }

  void _onVolume(double v) {
    final normalised = (v / 100.0).clamp(0.0, 1.0);
    if (normalised == _lastEmittedVolume) return;
    _lastEmittedVolume = normalised;
    _emit(PlayerAdapterEvent.volumeChanged(volume: normalised));
  }

  void _onWidth(int? w) {
    _width = w;
    _maybeEmitSize();
  }

  void _onHeight(int? h) {
    _height = h;
    _maybeEmitSize();
  }

  void _maybeEmitSize() {
    final w = _width;
    final h = _height;
    if (w == null || h == null || w <= 0 || h <= 0) return;
    _hasDecodedVideoFrame = true;
    _state = _state.withVideoEnabled(true);
    _emit(PlayerAdapterEvent.videoSizeChanged(width: w, height: h));
  }

  void _onError(String message) {
    _state = _state.errorState();
    _emit(PlayerAdapterEvent.error(message: message));
  }

  void _onBuffer(Duration buffered) {
    _metrics = _metrics.copyWith(buffered: buffered);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Future<void> _applyDecoderPolicy(String url) async {
    final native = _player?.platform;
    if (native == null) return;
    try {
      // ignore: avoid_dynamic_calls
      await (native as dynamic).setProperty('hwdec', _softwareDecoderNextOpen ? 'no' : _preferredHardwareDecoder);
      _softwareDecoderNextOpen = false;
    } catch (_) {
      // Property setting is best-effort across media_kit builds.
    }
  }

  Future<void> _applyProxy() async {
    final native = _player?.platform;
    if (native == null) return;
    try {
      // ignore: avoid_dynamic_calls
      await (native as dynamic).setProperty(
        'http-proxy',
        PlaybackProxyPolicy.currentNativeUrl(privateInput: _privateInput),
      );
      _privateInput = false;
    } catch (_) {
      // Best-effort.
    }
  }

  void _emit(PlayerAdapterEvent event) {
    if (!_eventController.isClosed) {
      _eventController.add(event);
    }
  }

  void _requireReady() {
    if (!_initialized || _disposed) {
      throw StateError('PureLiveMediaKitAdapter is not initialized or has been disposed.');
    }
  }

  /// Capabilities of the MPV engine.
  static const PlayerAdapterCapabilities defaultCapabilities = PlayerAdapterCapabilities(
    supportsLive: true,
    supportsSeek: true,
    supportsPause: true,
    supportsRateControl: true,
    supportsVolumeControl: true,
    supportsHardwareDecoder: true,
    supportsSoftwareDecoder: true,
    supportsPictureInPicture: false,
    supportsFullscreen: true,
    supportedProtocols: {'http', 'https', 'hls', 'dash', 'rtmp', 'rtsp', 'udp', 'file', 'asset'},
    supportedFormats: {
      'mp4',
      'mkv',
      'webm',
      'flv',
      'm3u8',
      'mpd',
      'mov',
      'avi',
      'ts',
      'mp3',
      'aac',
      'flac',
      'h265',
      'hevc',
    },
  );
}
