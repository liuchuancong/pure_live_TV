import 'dart:async';

import 'package:flutter/foundation.dart' show defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart' hide PlatformUtils;
import 'package:media_kit/media_kit.dart' as mk;
import 'package:media_kit_video/media_kit_video.dart' as mkv;

import '../../services/settings/settings.dart';
import '../../shared/utils/platform_utils.dart';
import '../core/playback_proxy_policy.dart';
import '../utils/device_playback_profile.dart';
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

  /// Minimum spacing between published decoded-frame heartbeats.
  ///
  /// libmpv reports every decoded frame; the live watchdog only needs proof
  /// that frames are still arriving, so publishing at most one heartbeat per
  /// interval keeps a 60 fps stream from pushing 60 notifications per second
  /// through the isolate without adding any information.
  static const int frameHeartbeatIntervalMs = 250;

  final Stopwatch _frameHeartbeatClock = Stopwatch();
  int _lastFrameHeartbeatMs = -frameHeartbeatIntervalMs;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  @override
  Future<void> initialize(PlayerAdapterContext context) async {
    if (_initialized) return;

    _player = _injectedPlayer ?? mk.Player();
    // The device budget must be known before the video controller and the
    // native property contract are built, because both branch on it.
    await DevicePlaybackProfile.ensureLoaded();
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
  /// Fast live probing, a bounded buffer budget (see [LiveBufferPolicy]),
  /// direct surface rendering on Android, the decode-cost budget of the
  /// current device (see [DevicePlaybackProfile]) and the configured audio
  /// output driver.
  Future<void> _applyNativeLiveProperties() async {
    if (_player?.platform == null) return;
    final profile = DevicePlaybackProfile.current;

    await _setNativeProperty('protocol_whitelist', 'httpproxy,udp,rtp,tcp,tls,data,file,http,https,crypto,rtmp,rtmps,rtsp,srt');
    await _setNativeProperty('demuxer-lavf-probesize', '2097152');
    // Short probe for live FLV/HLS: less black screen before the
    // first frame.
    await _setNativeProperty('demuxer-lavf-analyzeduration', '2');
    await LiveBufferPolicy.apply(_setNativeProperty, profile: profile);
    await _setNativeProperty('network-timeout', '15');
    // Drop a failing hw decoder after one bad frame so playback
    // falls back to software instead of a black surface.
    await _setNativeProperty('hwdec-software-fallback', '1');
    // The decoder is not chosen until the first open, so this is the
    // preference the first open will use.
    await _applyDecodeCostPolicy(profile, software: _preferredHardwareDecoder == 'no');

    if (profile.lowEnd) {
      // Absorb audio-device jitter. `video-sync=audio` (mpv's default) paces
      // video against the audio clock, so an underrun on a weak Android audio
      // HAL surfaces as a dropped video frame; the larger buffer is the
      // cheapest way to keep that clock steady.
      await _setNativeProperty('audio-buffer', '0.4');
      // Recover a short Wi-Fi/CDN interruption inside libavformat instead of
      // letting the transport die. This is deliberately limited to a low-end
      // device: there, the app's own recovery costs a full re-open and
      // re-probe of the stream, while a capable device would rather fail fast
      // and let the line fallback move on. `reconnect_delay_max` keeps the
      // retry bounded, so mpv's `network-timeout` and the live watchdogs still
      // end a genuinely dead transport.
      await _setNativeProperty(
        'stream-lavf-o',
        'reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1,reconnect_delay_max=2',
      );
    }

    if (PlatformUtils.isAndroid) {
      // mediacodec surface direct rendering: frames go straight
      // from the decoder to the display surface, skipping both
      // the copy to RAM and the Flutter texture round-trip.
      await _setNativeProperty('mediacodec-surface-iostream', 'yes');
      await _setNativeProperty('mediacodec-embed-surface-landscape', 'yes');
    }

    final audioOutput = effectiveMpvAudioOutputDriverForPlatform(
      customOutput: SettingsService.to.playerState.customPlayerOutput,
      configuredDriver: SettingsService.to.playerState.audioOutputDriver,
      platform: defaultTargetPlatform,
    );
    if (audioOutput != null) {
      await _setNativeProperty('ao', audioOutput);
    }

    if (PlatformUtils.isMacOS) {
      await _setNativeProperty('hwdec', 'no');
    }

    if (PlatformUtils.isWindows && SettingsService.to.playerState.enableRtxVsr) {
      await _setNativeProperty('hwdec', 'd3d11va');
      await _setNativeProperty('vf', 'd3d11vpp=scale=2:scaling-mode=nvidia');
    }
  }

  /// Keeps software decoding inside what the device can afford.
  ///
  /// Every option here is ignored by a hardware decoder, so the contract only
  /// means anything while mpv decodes in software — the case a low-end TV box
  /// lands in when its SoC has no decoder for the room's codec, or when the
  /// user turned hardware decoding off. Full-resolution 1080p in software is
  /// beyond such a box, so it decodes at a reduced resolution and skips
  /// deblocking of non-reference frames, the most expensive optional step of
  /// an H.264/HEVC decode. Both trade picture detail for frames that arrive on
  /// time, which is the right way round on a device that would otherwise
  /// stutter.
  ///
  /// This libmpv build has no `vd-lavc-downscale` option; the low-resolution
  /// request therefore travels as a libavcodec AVOption through `vd-lavc-o`.
  /// Codecs without low-resolution support ignore it, and `vd-lavc-o` is
  /// restored on a hardware decoder so a software episode cannot leak into the
  /// next open.
  Future<void> _applyDecodeCostPolicy(DevicePlaybackProfile profile, {required bool software}) async {
    if (!profile.lowEnd) return;

    if (software) {
      await _setNativeProperty('vd-lavc-threads', profile.softwareDecodeThreads.toString());
      await _setNativeProperty('vd-lavc-o', 'lowres=1');
      await _setNativeProperty('vd-lavc-skiploopfilter', 'nonref');
      return;
    }
    await _setNativeProperty('vd-lavc-o', 'lowres=0');
    await _setNativeProperty('vd-lavc-skiploopfilter', 'default');
  }

  /// Sets one mpv property on the active player, best-effort.
  ///
  /// Property support varies across media_kit and libmpv builds, and a
  /// rejected property is never a reason to fail playback.
  Future<void> _setNativeProperty(String name, String value) async {
    final native = _player?.platform;
    if (native == null) return;
    try {
      // ignore: avoid_dynamic_calls
      await (native as dynamic).setProperty(name, value);
    } catch (_) {
      // Best-effort.
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

    // A prepared software fallback belongs to the source it was prepared for.
    // `_currentUrl` is overwritten here, so the comparison has to happen first:
    // the previous form compared the URL against itself and was therefore
    // always true, which would have forced every later room through the
    // software decoder after a single codec failure — exactly the workload a
    // low-end box cannot afford.
    final bool sameSource = _softwareDecoderNextOpen && url == _currentUrl;
    _currentUrl = url;
    _hasDecodedVideoFrame = false;
    _softwareDecoderNextOpen = sameSource;

    await _applyDecoderPolicy();
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
    // decoder is alive even while mpv still reports playing=true,
    // which is what lets the live watchdog tell a wedged decoder
    // from a healthy one.
    //
    // `video-frame-info/picture-type` is the property mpv actually
    // publishes for the frame being decoded. The probe used to read
    // `decoded-picture-type`, which is not an mpv property at all, so this
    // heartbeat never fired and the watchdog could only ever be fed by
    // geometry changes. `estimated-vf-fps` is the second, independent signal:
    // it keeps moving while frames are decoded, so a codec that publishes no
    // picture type still reports liveness.
    _frameHeartbeatClock.start();
    for (final String property in const <String>['video-frame-info/picture-type', 'estimated-vf-fps']) {
      try {
        final native = player.platform;
        // ignore: avoid_dynamic_calls
        (native as dynamic).observeProperty?.call(property, (String value) {
          _onNativeFrameSignal(property, value);
        });
      } catch (_) {
        // observeProperty is a NativePlayer extension; a build without it
        // simply keeps the geometry-driven heartbeat.
      }
    }
  }

  /// Turns one raw mpv frame probe into a throttled frame heartbeat.
  void _onNativeFrameSignal(String property, String value) {
    if (_disposed) return;

    final signal = value.trim();
    if (property == 'video-frame-info/picture-type') {
      final type = signal.toUpperCase();
      if (type != 'I' && type != 'P' && type != 'B') return;
    } else {
      final fps = double.tryParse(signal);
      if (fps == null || !fps.isFinite || fps <= 0) return;
    }

    _hasDecodedVideoFrame = true;

    final now = _frameHeartbeatClock.elapsedMilliseconds;
    if (now - _lastFrameHeartbeatMs < frameHeartbeatIntervalMs) return;
    _lastFrameHeartbeatMs = now;

    _viewHolder.notifyFrameProgress();
    // media_core maps a geometry event to the live watchdog's frame-progress
    // witness, and only a decoded frame is authoritative proof of that. Emit
    // it as the same event the surface already publishes once the geometry is
    // known; before that, the size event that follows the first decoded frame
    // carries the heartbeat instead.
    final width = _width;
    final height = _height;
    if (width != null && height != null && width > 0 && height > 0) {
      _emit(PlayerAdapterEvent.videoSizeChanged(width: width, height: height));
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

  /// Applies the decoder contract for the open that is about to happen.
  ///
  /// A software fallback prepared by recovery applies to the next open only;
  /// mutating `hwdec` while the failing source is still open can re-enter the
  /// error path. The decode-cost policy follows the decoder that will actually
  /// run, so a source that fell back to software also stops paying for
  /// full-resolution decoding.
  Future<void> _applyDecoderPolicy() async {
    final decoder = _softwareDecoderNextOpen ? 'no' : _preferredHardwareDecoder;
    _softwareDecoderNextOpen = false;
    await _setNativeProperty('hwdec', decoder);
    await _applyDecodeCostPolicy(DevicePlaybackProfile.current, software: decoder == 'no');
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
