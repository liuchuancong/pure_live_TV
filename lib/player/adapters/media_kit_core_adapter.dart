import 'dart:async';
import 'media_kit_view_holder.dart';
import 'package:flutter/material.dart';
import '../utils/live_buffer_policy.dart';
import '../core/playback_proxy_policy.dart';
import '../utils/mpv_platform_profile.dart';
import '../../services/settings/settings.dart';
import '../utils/device_playback_profile.dart';
import 'package:media_kit/media_kit.dart' as mk;
import 'package:pure_live/shared/utils/log.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:media_core/media_core.dart' hide PlatformUtils;
import 'package:flutter/foundation.dart' show defaultTargetPlatform;

/// [PlayerAdapter] implementation backed by the local media_kit
/// snapshot — the MPV engine.
///
/// Engine semantics:
///
/// - decoded-frame heartbeats via mpv property observers
///   (`video-frame-info/picture-type`) so the
///   live watchdog can detect a wedged decoder
/// - software-decoder fallback marked for the *next* open (never
///   mutated mid-failure)
/// - viewport fit applied through `Video(fit:)`, not a wrapper
///   widget
/// - proxy option for the app-owned loopback input
/// - events consumed through subscriptions bound once for the whole
///   adapter lifetime, so the base's source gate stays open
/// - a capability declaration that matches the signals the adapter really
///   emits ([defaultCapabilities]), because the base drops a
///   `videoFrameProgress` / `videoSizeChanged` emit whose capability is not
///   declared.
final class PureLiveMediaKitAdapter extends PlayerAdapterBase {
  /// Creates the adapter.
  PureLiveMediaKitAdapter({super.id = 'mpv', super.capabilities = defaultCapabilities, mk.Player? player})
    : _injectedPlayer = player;

  final mk.Player? _injectedPlayer;

  mk.Player? _player;
  mkv.VideoController? _videoController;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

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

  /// mpv events are consumed through subscriptions bound once for
  /// the whole adapter lifetime; stale payloads are handled by the
  /// engine itself, so the base's source gate stays open.
  @override
  bool get gatesSourceEvents => false;

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
  /// that frames are still arriving, so publishing at most one heartbeat every
  /// 1000ms keeps a 60 fps stream from pushing dozens of notifications per
  /// second through the isolate without adding any information.
  static const int frameHeartbeatIntervalMs = 1000;

  final Stopwatch _frameHeartbeatClock = Stopwatch();
  int _lastFrameHeartbeatMs = -frameHeartbeatIntervalMs;

  /// The resolved hardware decoder preference.
  String get preferredHardwareDecoder => _preferredHardwareDecoder;
  String _preferredHardwareDecoder = 'auto';

  // ---------------------------------------------------------------------------
  // Engine contract
  // ---------------------------------------------------------------------------

  @override
  Future<void> onInitialize(PlayerAdapterContext context) async {
    _player = _injectedPlayer ?? mk.Player();

    // The device budget must be known before the video controller and the
    // native property contract are built, because both branch on it.
    await DevicePlaybackProfile.ensureLoaded();
    _resolvePreferredHardwareDecoder();
    _videoController = _buildVideoController();
    _subscribeStreams();
    _observeDecodedFrames();
    await _applyNativeLiveProperties();
  }

  @override
  Future<void> onBeforeOpen(PlayerSource source) async {
    final url = source.uri.toString();

    // A prepared software fallback belongs to the source it was prepared for.
    // `_currentUrl` is overwritten here, so the comparison has to happen first:
    // the previous form compared the URL against itself and was therefore
    // always true, which would have forced every later room through the
    // software decoder after a single codec failure — exactly the workload a
    // low-end box cannot afford.
    final bool sameSource = _softwareDecoderNextOpen && url == _currentUrl;

    _currentUrl = url;
    _hasDecodedVideoFrame = false;
    _lastFrameHeartbeatMs = -frameHeartbeatIntervalMs;

    _softwareDecoderNextOpen = sameSource;

    await _applyDecoderPolicy();
    await _applyProxy();
  }

  @override
  Future<void> onOpen(PlayerSource source) async {
    final headers = source.hasHeaders ? source.headers!.values : null;

    await player.open(mk.Media(source.uri.toString(), httpHeaders: headers), play: true);

    _hasOpened = true;

    if (audioOnly) {
      await _applyAudioOnly(true);
    }
  }

  @override
  Future<void> onPlay() async {
    await player.play();
    emitPlaying();
  }

  @override
  Future<void> onPause() async {
    await player.pause();
    emitPaused();
  }

  @override
  Future<void> onStop() async {
    await player.stop();

    _playingNow = false;
    _bufferingNow = false;
    _hasOpened = false;
  }

  @override
  Future<void> onSeek(Duration position) => player.seek(position);

  @override
  Future<void> onSetVolume(double volume) => player.setVolume(volume.clamp(0.0, 1.0) * 100.0);

  @override
  Future<void> onSetRate(double rate) => player.setRate(rate);

  @override
  Future<void> onClose() async {
    await player.stop();

    _hasOpened = false;
    _playingNow = false;
    _bufferingNow = false;
  }

  @override
  Future<void> onDispose() async {
    await Future.wait(_subscriptions.map((s) => s.cancel()));

    _subscriptions.clear();

    await _player?.dispose();

    _player = null;
    _videoController = null;
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

  /// Restricts playback to the audio track through mpv's `vid` property.
  ///
  /// The base calls this only when the value changes and only because
  /// [defaultCapabilities] declares [PlayerAdapterCapabilities.supportsAudioOnly].
  @override
  Future<void> onSetAudioOnly(bool audioOnly) => _applyAudioOnly(audioOnly);

  /// Applies the audio-only preference to the engine.
  ///
  /// `vid` is an option default rather than a sticky property: a new
  /// source resets the track selection, so this runs both on a change and
  /// again after every open - including the replays media_core performs on
  /// its own (same-engine retry, line cycling, recovery).
  Future<void> _applyAudioOnly(bool audioOnly) async {
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
  // Engine configuration
  // ---------------------------------------------------------------------------

  /// Resolves the hardware decoder preference from settings.
  ///
  /// Three tiers, mirroring the legacy adapter:
  /// - Android compat mode: force `mediacodec`.
  /// - Expert output configured: the user-picked decoder.
  /// - Default: `enableCodec ? auto-safe : no`.
  void _resolvePreferredHardwareDecoder() {
    final settings = SettingsService.to.playerState;

    final androidCompatMode = settings.playerCompatMode;

    final hardwareDecoder = normalizeMpvHardwareDecoderForPlatform(
      settings.videoHardwareDecoder,
      defaultTargetPlatform,
    );

    _preferredHardwareDecoder = androidCompatMode
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

    final androidCompatMode = settings.playerCompatMode;

    final videoOutputDriver = normalizeMpvVideoOutputDriverForPlatform(settings.videoOutputDriver, platform);

    if (androidCompatMode) {
      return mkv.VideoController(
        player,
        configuration: const mkv.VideoControllerConfiguration(
          vo: 'mediacodec_embed',
          hwdec: 'mediacodec',
          enableAndroidSurfaceProducer: false,
          androidAttachSurfaceAfterVideoParameters: false,
        ),
      );
    }

    if (settings.customPlayerOutput) {
      return mkv.VideoController(
        player,
        configuration: mkv.VideoControllerConfiguration(
          vo: videoOutputDriver,
          hwdec: normalizeMpvHardwareDecoderForPlatform(settings.videoHardwareDecoder, platform),
          enableHardwareAcceleration: true,
          enableAndroidSurfaceProducer: false,
          androidAttachSurfaceAfterVideoParameters: false,
        ),
      );
    }

    return mkv.VideoController(
      player,
      configuration: mkv.VideoControllerConfiguration(
        enableHardwareAcceleration: settings.enableCodec,
        hwdec: 'no',
        enableAndroidSurfaceProducer: false,
        androidAttachSurfaceAfterVideoParameters: false,
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

    await _setNativeProperty(
      'protocol_whitelist',
      'httpproxy,udp,rtp,tcp,tls,data,file,http,https,crypto,rtmp,rtmps,rtsp,srt',
    );

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

    // mediacodec surface direct rendering: frames go straight
    // from the decoder to the display surface, skipping both
    // the copy to RAM and the Flutter texture round-trip.
    await _setNativeProperty('mediacodec-surface-iostream', 'yes');

    await _setNativeProperty('mediacodec-embed-surface-landscape', 'yes');

    final audioOutput = effectiveMpvAudioOutputDriverForPlatform(
      customOutput: SettingsService.to.playerState.customPlayerOutput,
      configuredDriver: SettingsService.to.playerState.audioOutputDriver,
      platform: defaultTargetPlatform,
    );

    if (audioOutput != null) {
      await _setNativeProperty('ao', audioOutput);
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
  /// restored on a hardware decoder so a software episode cannot leak into
  /// the next open.
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

  /// Observes MPV's estimated video frame rate and turns it into
  /// a throttled video-frame heartbeat.
  ///
  /// MPV does not expose a decoded-frame callback through
  /// `video-frame-info/picture-type` in the current media_kit/libmpv
  /// build, so that property cannot be used as the frame heartbeat.
  ///
  /// `estimated-vf-fps` is a video-frame-rate statistic rather than
  /// a per-frame notification. It is therefore only used as evidence
  /// that video output is still progressing.
  ///
  /// The callback is throttled by [_onNativeFrameSignal] so the
  /// media_core event stream receives at most one heartbeat per second.
  /// This heartbeat is consumed by the live watchdog to detect a
  /// stalled video decoder/output.
  ///
  /// Do not use `video-params` here. It describes video geometry and
  /// format and does not represent continuous frame progress.
  void _observeDecodedFrames() {
    _frameHeartbeatClock.start();

    const property = 'estimated-vf-fps';

    try {
      final native = player.platform;

      // ignore: avoid_dynamic_calls
      (native as dynamic).observeProperty?.call(property, (dynamic value) async {
        _onNativeFrameSignal(property, value?.toString() ?? '');
      });
    } catch (error, stackTrace) {
      Log.d(
        '[MPV FRAME] observeProperty failed: '
        '$error\n$stackTrace',
      );
    }
  }

  /// Turns one raw mpv video-output statistic into a throttled
  /// frame heartbeat.
  ///
  /// `estimated-vf-fps` is not a per-frame callback. It is an MPV
  /// video-frame-rate statistic, so it is only used as evidence that
  /// video output is still progressing. The heartbeat itself is
  /// throttled to once per second before entering media_core.
  void _onNativeFrameSignal(String property, String value) {
    if (isDisposed) return;

    // A native callback can arrive slightly after pause/stop/close.
    // It must not keep the live watchdog alive after playback has stopped.
    if (!_hasOpened || !_playingNow) return;

    if (property != 'estimated-vf-fps') {
      return;
    }

    final fps = double.tryParse(value.trim());

    // Ignore invalid / unavailable FPS values.
    if (fps == null || fps <= 0) {
      return;
    }

    // MPV reports the estimated frame rate much more frequently than
    // the watchdog needs. Only publish one heartbeat per second.
    final now = _frameHeartbeatClock.elapsedMilliseconds;

    if (now - _lastFrameHeartbeatMs < frameHeartbeatIntervalMs) {
      return;
    }

    _lastFrameHeartbeatMs = now;

    _hasDecodedVideoFrame = true;
    // media_core-level frame heartbeat.
    //
    // Do NOT emit videoSizeChanged here. Video size is geometry only
    // and must never be used as a proof that frames are still decoding.
    emitVideoFrameProgress();
  }

  void _onPlaying(bool playing) {
    if (_playingNow == playing) return;

    _playingNow = playing;

    if (playing) {
      emitPlaying();
    } else if (_hasOpened && !state.stopped && !state.completed) {
      emitPaused();
    }
  }

  void _onCompleted(bool completed) {
    if (!completed) return;

    _playingNow = false;

    emitCompleted();
  }

  void _onBuffering(bool buffering) {
    if (_bufferingNow == buffering) return;

    _bufferingNow = buffering;

    emitBuffering(buffering, resumePlaying: buffering ? null : _playingNow);
  }

  void _onPosition(Duration position) {
    emitPositionChanged(position);
  }

  void _onDuration(Duration duration) {
    emitDurationChanged(duration);
  }

  void _onVolume(double v) {
    final normalised = (v / 100.0).clamp(0.0, 1.0);

    if (normalised == _lastEmittedVolume) return;

    _lastEmittedVolume = normalised;

    emitVolumeChanged(normalised);
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

    // Video dimensions are geometry only.
    //
    // Do NOT set `_hasDecodedVideoFrame` here. A size notification
    // does not prove that the decoder is still producing frames.
    //
    // The deduplicating helper is used so the base owns the
    // comparison and resets it on every open: the first geometry of
    // each source is always published, and width / height arriving as
    // two separate stream events cannot publish the same pair twice.
    emitVideoSizeChangedIfChanged(w, h);
  }

  void _onError(String message) {
    Log.d(message);
    reportEngineError(message: message);
  }

  void _onBuffer(Duration buffered) {
    updateMetrics((metrics) => metrics.copyWith(buffered: buffered));
  }

  /// Capabilities of the MPV engine, as exposed by this adapter.
  ///
  /// The declaration is scoped to what the adapter actually produces or
  /// accepts today, not to what libmpv exposes in the abstract. Backend
  /// events the adapter does not yet subscribe to
  /// (`MPV_EVENT_VIDEO_RECONFIG`, `MPV_EVENT_AUDIO_RECONFIG`, `metadata`,
  /// track lists, …) stay false; they can be flipped on the same line as the
  /// subscription that makes them real.
  ///
  /// [PlayerAdapterCapabilities] is the single source of truth for what this
  /// adapter supports: this class declares no `supportsXxx` field or getter of
  /// its own, and the base reads the snapshot directly.
  ///
  /// Signal emits and their capability flags:
  ///
  /// - [PlayerAdapterEvent.videoFrameProgress] is produced by
  ///   [_observeDecodedFrames] from mpv's `estimated-vf-fps`. It is a rate
  ///   statistic rather than a per-frame callback, but it is a real proof that
  ///   video output is still advancing, which is exactly what the video-frame
  ///   watchdog needs. The flag has to be declared: the base drops a signal
  ///   emit whose capability is false, and [LiveWatchdogs] never arms that
  ///   watchdog without it.
  /// - [PlayerAdapterEvent.videoSizeChanged] is produced by
  ///   [_onWidth] / [_onHeight] from the media_kit width and height streams.
  static const PlayerAdapterCapabilities defaultCapabilities = PlayerAdapterCapabilities(
    // Core playback.
    //
    // Every command hook is implemented and forwarded to media_kit:
    // play() / pause() / stop() / seek() / setVolume() / setRate().
    // `supportsMuteControl` stays false: muting is done by routing through
    // `setAudioTrack(no)` for the current source, not by a dedicated mute
    // command the adapter accepts for the lifetime of the session.
    supportsLive: true,
    supportsSeek: true,
    supportsPause: true,
    supportsStop: true,
    supportsRateControl: true,
    supportsVolumeControl: true,
    supportsMuteControl: false,

    // `supportsAudioOnly` is true: `vid` really switches the video
    // decoder off, so an audio-only session does not pay for video
    // decoding. It is re-applied after every open because a new source
    // resets the track selection.
    supportsAudioOnly: true,

    // Video and rendering.
    //
    // Only the two signals the adapter currently emits are declared.
    // Reconfig / hwdec info / filters / screenshot are backend capabilities
    // that are not surfaced through the adapter yet, so they stay false until
    // a corresponding subscription or command is added.
    supportsVideoFrameProgress: true,
    supportsVideoSizeChanged: true,
    supportsVideoReconfig: false,
    supportsHwdecInfo: false,
    supportsVideoFilters: false,
    supportsScreenshot: false,

    // Audio.
    //
    // No audio reconfig subscription, device list, or dynamic filter surface
    // is wired through the adapter.
    supportsAudioReconfig: false,
    supportsAudioDeviceSelection: false,
    supportsAudioFilters: false,

    // Tracks and subtitles.
    //
    // `setAudioOnly` and `setAudioOutputSuppressed` exist, but they are
    // adapter-specific toggles, not the general "list and pick a track"
    // surface the capability describes.
    supportsTrackSelection: false,
    supportsSubtitleTrack: false,
    supportsExternalSubtitle: false,

    // Playback state and buffering.
    //
    // `_onBuffer` updates metrics but does not emit a buffering progress
    // ratio, so `supportsBufferingProgress` stays false until
    // `emitBuffering(progress: …)` is actually wired.
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
    // mpv decodes in hardware (mediacodec) or software (FFmpeg), and the
    // adapter selects between them through the `hwdec` property.
    supportsHardwareDecoder: true,
    supportsSoftwareDecoder: true,

    // Presentation.
    //
    // PiP is not provided by mpv; fullscreen is a widget-level decision the
    // adapter does not veto.
    supportsPictureInPicture: false,
    supportsFullscreen: true,

    // Source matching.
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
