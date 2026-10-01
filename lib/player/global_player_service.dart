import 'dart:async';
import 'dart:developer';
import 'live_player_facade.dart';
import 'models/player_engine.dart';
import 'core/playback_proxy_policy.dart';
import 'core/owned_input_opener.dart';
import '../services/settings/settings.dart';
import '../services/player_settings/player_settings_controller.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:media_core/media_core.dart';
import 'package:media_core_native/media_core_native.dart';
import 'package:media_core_media_kit/media_core_media_kit.dart';
import 'package:media_core_ijk_player/media_core_ijk_player.dart';
import 'package:media_core_fvp/media_core_fvp.dart';
import 'package:media_core_better_player/media_core_better_player.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;

/// Host-owned media_kit (libmpv) configuration.
///
/// The adapter deliberately configures nothing itself: the native
/// [mkv.VideoControllerConfiguration] is applied verbatim at engine creation
/// and every other tuning value arrives as an [EngineOption] (an mpv
/// property) stashed before initialization. This file therefore rebuilds the
/// whole libmpv contract from [SettingsService.to.playerState] — the same
/// mapping the adapter used to own — and rebuilds it per adapter instance,
/// so a settings change applies to the next player session.
final class MediaKitHostConfig {
  const MediaKitHostConfig._();

  /// The mpv protocol set the live sources need (plus the proxy scheme).
  static const String _protocolWhitelist =
      'httpproxy,udp,rtp,tcp,tls,data,file,http,https,crypto,rtmp,rtmps,rtsp,srt';

  /// Hardware-decoding preference in mpv's `hwdec` vocabulary.
  ///
  /// Precedence (macOS pinned to `no`, compat mode Android-only,
  /// RTX VSR Windows-only): macOS → `no`; Android compat mode →
  /// `mediacodec`; Windows + RTX VSR → `d3d11va`; expert output → the
  /// user pick normalised for this platform; otherwise `auto-safe`
  /// when hardware decoding is on, `no` when off.
  static String resolvePreferredHardwareDecoder() {
    final settings = SettingsService.to.playerState;
    final platform = defaultTargetPlatform;

    if (platform == TargetPlatform.macOS) return 'no';

    if (platform == TargetPlatform.android && settings.playerCompatMode) return 'mediacodec';

    if (platform == TargetPlatform.windows && settings.enableRtxVsr) return 'd3d11va';

    if (settings.customPlayerOutput) {
      return MpvPlatformProfile.normalizeHardwareDecoderForPlatform(settings.videoHardwareDecoder, platform);
    }

    return settings.enableCodec ? 'auto-safe' : 'no';
  }

  /// The video-surface half of the contract, mapped onto media_kit's own
  /// configuration type.
  static mkv.VideoControllerConfiguration buildVideoControllerConfiguration() {
    final settings = SettingsService.to.playerState;
    final platform = defaultTargetPlatform;
    final isMacOS = platform == TargetPlatform.macOS;

    // Compat mode pins the legacy mediacodec_embed surface path.
    if (platform == TargetPlatform.android && settings.playerCompatMode) {
      return const mkv.VideoControllerConfiguration(
        vo: 'mediacodec_embed',
        hwdec: 'mediacodec',
        enableAndroidSurfaceProducer: false,
        androidAttachSurfaceAfterVideoParameters: false,
      );
    }

    if (settings.customPlayerOutput) {
      final normalizedVideoOutput = MpvPlatformProfile.normalizeVideoOutputDriverForPlatform(
        settings.videoOutputDriver,
        platform,
      );
      final normalizedHardwareDecoder = isMacOS
          ? 'no'
          : MpvPlatformProfile.normalizeHardwareDecoderForPlatform(settings.videoHardwareDecoder, platform);

      return mkv.VideoControllerConfiguration(
        vo: normalizedVideoOutput,
        hwdec: normalizedHardwareDecoder,
        enableHardwareAcceleration: !isMacOS && normalizedHardwareDecoder != 'no',
        // Historical app default: the SurfaceTexture path, matching the
        // pre-refactor adapter.
        enableAndroidSurfaceProducer: false,
        androidAttachSurfaceAfterVideoParameters: false,
      );
    }

    return mkv.VideoControllerConfiguration(
      enableHardwareAcceleration: !isMacOS && settings.enableCodec,
      hwdec: isMacOS ? 'no' : null,
      enableAndroidSurfaceProducer: false,
      androidAttachSurfaceAfterVideoParameters: false,
    );
  }

  /// Every runtime mpv property the adapter used to write itself, as engine
  /// options. `applyEngineOptions` before initialization stashes them and
  /// the engine creation writes them at the player's first moment.
  static List<EngineOption> buildEngineOptions() {
    final settings = SettingsService.to.playerState;
    final platform = defaultTargetPlatform;
    final device = GlobalPlayerService.instance.deviceProfile;
    final lowEnd = device.isLowEnd;
    final preferredHwdec = resolvePreferredHardwareDecoder();

    final options = <EngineOption>[
      EngineOption('protocol_whitelist', _protocolWhitelist),
      EngineOption('demuxer-lavf-probesize', '2097152'),
      EngineOption('demuxer-lavf-analyzeduration', '2'),

      // Live buffer contract: bounded by time and bytes, refill-then-resume.
      EngineOption('force-seekable', 'yes'),
      EngineOption('cache', 'yes'),
      EngineOption('cache-on-disk', 'no'),
      EngineOption('cache-secs', '30'),
      EngineOption('demuxer-max-bytes', (lowEnd ? 40 * 1024 * 1024 : 96 * 1024 * 1024).toString()),
      EngineOption('demuxer-max-back-bytes', (lowEnd ? 5 * 1024 * 1024 : 8 * 1024 * 1024).toString()),
      EngineOption('demuxer-donate-buffer', 'no'),
      EngineOption('demuxer-readahead-secs', '8'),
      EngineOption('cache-pause', 'yes'),
      EngineOption('cache-pause-wait', '4'),
      EngineOption('demuxer-thread', 'yes'),
      EngineOption('framedrop', 'decoder+vo'),

      EngineOption('network-timeout', '15'),
      // Drop a failing hw decoder after one bad frame.
      EngineOption('hwdec-software-fallback', '1'),
      EngineOption('hwdec', preferredHwdec),
    ];

    // Decode-cost tuning at init: the codec is not known yet, so software
    // decoding is only pinned from the resolved preference (the runtime
    // codec-aware downgrade is carried by hwdec-software-fallback above).
    if (preferredHwdec == 'no' && lowEnd) {
      options.addAll([
        EngineOption('vd-lavc-threads', device.softwareDecodeThreads.toString()),
        EngineOption('vd-lavc-o', 'lowres=1'),
        EngineOption('vd-lavc-skiploopfilter', 'nonref'),
      ]);
    } else {
      options.addAll([
        EngineOption('vd-lavc-o', 'lowres=0'),
        EngineOption('vd-lavc-skiploopfilter', 'default'),
      ]);
    }

    if (lowEnd) {
      options.addAll([
        EngineOption('audio-buffer', '0.4'),
        EngineOption(
          'stream-lavf-o',
          'reconnect=1,reconnect_streamed=1,reconnect_on_network_error=1,'
              'reconnect_delay_max=2',
        ),
      ]);
    }

    if (platform == TargetPlatform.android) {
      options.addAll([
        EngineOption('mediacodec-surface-iostream', 'yes'),
        EngineOption('mediacodec-embed-surface-landscape', 'yes'),
      ]);
    }

    if (platform == TargetPlatform.macOS) {
      options.add(const EngineOption('hwdec', 'no'));
    }

    if (platform == TargetPlatform.windows && settings.enableRtxVsr) {
      options.addAll([
        const EngineOption('hwdec', 'd3d11va'),
        const EngineOption('vf', 'd3d11vpp=scale=2:scaling-mode=nvidia'),
      ]);
    }

    final audioOutput = MpvPlatformProfile.effectiveAudioOutputDriverForPlatform(
      customOutput: settings.customPlayerOutput,
      configuredDriver: settings.audioOutputDriver,
      platform: platform,
    );

    if (audioOutput != null) {
      options.add(EngineOption('ao', audioOutput));
    }

    // Proxy for the session's directive; a DIRECT policy resolves to ''
    // which explicitly clears any previous proxy state.
    options.add(EngineOption('http-proxy', PlaybackProxyPolicy.currentNativeUrl(privateInput: false)));

    return options;
  }

  /// Builds one fully configured media_kit adapter for the kernel.
  static PlayerAdapter createAdapter(String id) {
    final adapter = MediaKitPlayerAdapter(
      id: id,
      capabilities: MediaKitPlayerAdapter.defaultCapabilities,
      // media_kit's own `PlayerConfiguration` defaults: the old adapter also
      // created the player without a native player configuration.
      playerConfiguration: null,
      videoControllerConfiguration: buildVideoControllerConfiguration(),
      // Loopback relay lines open through the app-owned input channel:
      // the recipe starts the relay per open and the proxy is cleared
      // there, not from this creation-time snapshot.
      customInputOpener: openOwnedInputOnKernelPlayer,
    );

    adapter.applyEngineOptions(buildEngineOptions());

    return adapter;
  }
}

/// Host-owned fvp (libmdk) configuration.
///
/// fvp is the Android backup engine: it ships a current FFmpeg plus the
/// platform hardware decoders, so it recovers sources the bundled libmpv
/// drops (legacy codec-id-12 HEVC FLV, for example). The adapter writes
/// exactly what is passed here.
final class FvpHostConfig {
  const FvpHostConfig._();

  /// Video decoder priority for the platform: hardware first with software
  /// fallbacks, software-only when hardware decoding is off.
  static List<String> videoDecoders({required bool hardware}) {
    if (!hardware) return const <String>['FFmpeg', 'dav1d'];

    final platform = defaultTargetPlatform;
    if (platform == TargetPlatform.android) return const <String>['AMediaCodec', 'FFmpeg', 'dav1d'];
    if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
      return const <String>['VT', 'FFmpeg', 'dav1d'];
    }
    if (platform == TargetPlatform.windows) {
      return const <String>['MFT:d3d=11', 'D3D11', 'DXVA', 'FFmpeg', 'dav1d'];
    }

    return const <String>['VAAPI', 'VDPAU', 'FFmpeg', 'dav1d'];
  }

  /// Audio backends, or null where mdk's own default is fine.
  ///
  /// Android goes through OpenSL first: libmdk's AAudio output crashes on
  /// dispose, stutters on devices with a coarse clock and dies on output
  /// routing changes.
  static List<String>? audioBackends() =>
      defaultTargetPlatform == TargetPlatform.android ? const <String>['OpenSL', 'AudioTrack', 'AAudio'] : null;

  static PlayerAdapter createAdapter(String id) {
    final settings = SettingsService.to.playerState;

    return FvpPlayerAdapter(
      id: id,
      capabilities: FvpPlayerAdapter.defaultCapabilities,
      // `avio.http_proxy` is re-read at every engine creation (fvp builds a
      // fresh player per source); a DIRECT policy resolves to '' which FFmpeg
      // ignores. Empty for loopback inputs as well — see
      // [PlaybackProxyPolicy.currentNativeUrl].
      properties: <String, String>{
        'avio.http_proxy': PlaybackProxyPolicy.currentNativeUrl(privateInput: false),
      },
      videoDecoders: videoDecoders(hardware: settings.enableCodec),
      audioBackends: audioBackends(),
    );
  }
}

/// Host-owned ijkplayer (flv_lzc) configuration.
///
/// The adapter invents nothing: every option the old [FijkPlayerConfig]
/// defaults carried is rebuilt here as a raw (domain, key, value) triple,
/// applied by the adapter before every open.
final class IjkHostConfig {
  const IjkHostConfig._();

  static PlayerAdapter createAdapter(String id) {
    final settings = SettingsService.to.playerState;

    return FlvLzcPlayerAdapter(
      id: id,
      capabilities: FlvLzcPlayerAdapter.defaultCapabilities,
      options: <EngineOption>[
        // player category
        EngineOption('mediacodec', settings.enableCodec, domain: 'player'),
        EngineOption('mediacodec-hevc', settings.enableCodec, domain: 'player'),
        EngineOption('videotoolbox', settings.enableCodec, domain: 'player'),
        const EngineOption('enable-accurate-seek', true, domain: 'player'),
        const EngineOption('soundtouch', true, domain: 'player'),
        const EngineOption('subtitle', true, domain: 'player'),
        const EngineOption('an', false, domain: 'player'),

        // host category
        const EngineOption('request-screen-on', true, domain: 'host'),
        const EngineOption('request-audio-focus', true, domain: 'host'),

        // format category
        const EngineOption('reconnect', true, domain: 'format'),
        EngineOption('timeout', const Duration(seconds: 30).inMicroseconds, domain: 'format'),
        const EngineOption('fflags', 'fastseek', domain: 'format'),
        const EngineOption('rtsp_transport', 'tcp', domain: 'format'),
        EngineOption('http_proxy', PlaybackProxyPolicy.currentNativeUrl(privateInput: false), domain: 'format'),
      ],
    );
  }
}

/// Creates a media_kit adapter with the current settings.
///
/// Registered under the app's historical backend id `mpv`
/// ([PlayerConsts.defaultKey]); the kernel addresses the registration by that
/// id and never consults [PlayerAdapterFactory.supports].
final class _MediaKitFactory implements PlayerAdapterFactory {
  const _MediaKitFactory();

  @override
  PlayerAdapter create(String id) => MediaKitHostConfig.createAdapter(id);

  @override
  bool supports(String id) => id == BackendIds.mediaKit || id.isEmpty;
}

/// Creates an fvp adapter with the current settings.
final class _FvpFactory implements PlayerAdapterFactory {
  const _FvpFactory();

  @override
  PlayerAdapter create(String id) => FvpHostConfig.createAdapter(id);

  @override
  bool supports(String id) => id == BackendIds.fvp || id.isEmpty;
}

/// Creates an ijkplayer (flv_lzc) adapter with the current settings.
final class _FlvLzcFactory implements PlayerAdapterFactory {
  const _FlvLzcFactory();

  @override
  PlayerAdapter create(String id) => IjkHostConfig.createAdapter(id);

  @override
  bool supports(String id) => id == BackendIds.fijk || id.isEmpty;
}

/// Creates a better_player adapter with the current settings.
final class _BetterPlayerFactory implements PlayerAdapterFactory {
  const _BetterPlayerFactory();

  @override
  PlayerAdapter create(String id) => BetterPlayerAdapter(id: id, capabilities: BetterPlayerAdapter.defaultCapabilities);

  @override
  bool supports(String id) => id == BackendIds.betterPlayer || id.isEmpty;
}

/// Media-core-backed global player service.
///
/// The heavy orchestration (watchdogs, line / engine fallback,
/// backoff) lives in `media_core`'s [LivePlaybackController];
/// this service owns the kernel, the engine registrations and the
/// facade the features consume ([livePlayer]).
class GlobalPlayerService {
  GlobalPlayerService._();

  static final GlobalPlayerService instance = GlobalPlayerService._();

  /// The media_core kernel every player runs on.
  PlayerKernel? _kernel;

  /// The live orchestration facade.
  LivePlayerFacade? _livePlayer;

  bool _initialized = false;

  bool get initialized => _initialized;

  PlatformProvider? _platformProvider;

  /// What the platform probe learned about this device.
  ///
  /// [PlatformDeviceProfile.unknown] until [loadPlatformProvider] ran; an
  /// unknown profile reports itself as unreported and deliberately behaves like
  /// a healthy device, so a caller that tunes work down must say so explicitly.
  PlatformDeviceProfile get deviceProfile => _platformProvider?.device ?? PlatformDeviceProfile.unknown;

  /// Probes the platform once and keeps the result.
  ///
  /// The kernel takes it as its [PlatformProvider], which is how the adapters
  /// learn the core count, the RAM ceiling and the codec list; the app reads the
  /// same profile for its own policies (the danmaku frame budget). Safe to call
  /// early and more than once.
  Future<void> loadPlatformProvider() async {
    if (_platformProvider != null) return;

    try {
      final provider = await NativePlatformProvider.load();

      _platformProvider = provider;

      _kernel?.attachPlatformProvider(provider);
    } catch (error, stackTrace) {
      // A probe that failed must not tune playback down, and it must not fail
      // startup either: the kernel keeps its unreported defaults.
      log('GlobalPlayerService: platform probe failed: $error', name: 'GlobalPlayerService', error: error, stackTrace: stackTrace);
    }
  }

  /// The live player facade features consume.
  ///
  /// Null until [initialize] completed.
  LivePlayerFacade? get livePlayer => _livePlayer;

  /// The kernel every player runs on.
  ///
  /// Null until [initialize] completed. VOD consumers (the music mode) create
  /// their own [PlayerHandle] on this kernel instead of building a second one,
  /// so the engine registrations and the platform probe stay shared.
  PlayerKernel? get kernel => _kernel;

  /// Ensures the service is up on [defaultEngine].
  Future<void> initialize({PlayerEngine defaultEngine = PlayerEngine.mediaKit}) async {
    if (_initialized) return;
    MediaKitPlayerAdapter.ensureInitialized();

    // Output settings ride two rails: a live-appliable mpv property change
    // (hardware decoder, audio output, decode tuning) is written to the engine
    // that is already playing through applyEngineOptions; a render-context
    // change (video output driver / custom-output / compat surface) is bound to
    // the mpv video output and rebuilds the engine on the same backend, which
    // re-runs the adapter factory (so it re-reads the new vo) and restores the
    // source, position and play intent. Installed here rather than from the
    // settings layer so services never import the player back.
    PlayerSettingsController.outputSettingsDispatcher = ({required bool rebuild}) {
      final handle = _livePlayer?.controller.handle;
      if (handle == null) return;

      if (rebuild) {
        unawaited(handle.rebuildEngine(reason: 'video output settings changed'));
        return;
      }
      unawaited(handle.applyEngineOptions(MediaKitHostConfig.buildEngineOptions()));
    };

    await loadPlatformProvider();
    final kernel = PlayerKernel();
    if (_platformProvider != null) kernel.attachPlatformProvider(_platformProvider!);
    _kernel = kernel;
    // Register the engines this app ships. Priority encodes the
    // fallback preference: the default engine first, the rest by
    // platform strength.
    kernel.registerBackend(_registrationOf(defaultEngine, priority: 100));
    for (final engine in PlayerEngine.values) {
      if (engine != defaultEngine) {
        kernel.registerBackend(_registrationOf(engine, priority: 80));
      }
    }

    final facade = LivePlayerFacade(
      kernel,
      defaultEngine: defaultEngine,
      onPreferredEngineChanged: (engine) {
        // Re-register the whole set, not only the chosen engine. Raising the new
        // preference to 100 while the previous one stayed at 100 left two
        // registrations tied, and [PlayerAdapterSelector] resolved that tie by
        // list order — so a second switch could keep running the kernel that was
        // already active.
        for (final PlayerEngine candidate in PlayerEngine.values) {
          final registration = _registrationOf(candidate, priority: candidate == engine ? 100 : 80);
          kernel.registry.unregister(registration.id);
          kernel.registerBackend(registration);
        }
      },
    );
    _livePlayer = facade;

    _initialized = true;
    log('GlobalPlayerService: initialized on media_core (default: ${defaultEngine.name})', name: 'GlobalPlayerService');
  }

  PlayerAdapterRegistration _registrationOf(PlayerEngine engine, {required int priority}) {
    switch (engine) {
      case PlayerEngine.mediaKit:
        return PlayerAdapterRegistration(
          id: BackendIds.mediaKit,
          factory: const _MediaKitFactory(),
          capabilities: MediaKitPlayerAdapter.defaultCapabilities,
          priority: priority,
        );
      case PlayerEngine.fijk:
        return PlayerAdapterRegistration(
          id: BackendIds.fijk,
          factory: const _FlvLzcFactory(),
          capabilities: FlvLzcPlayerAdapter.defaultCapabilities,
          priority: priority,
        );
      case PlayerEngine.betterPlayer:
        return PlayerAdapterRegistration(
          id: BackendIds.betterPlayer,
          factory: const _BetterPlayerFactory(),
          capabilities: BetterPlayerAdapter.defaultCapabilities,
          priority: priority,
        );
      case PlayerEngine.fvp:
        return PlayerAdapterRegistration(
          id: BackendIds.fvp,
          factory: const _FvpFactory(),
          capabilities: FvpPlayerAdapter.defaultCapabilities,
          priority: priority,
        );
    }
  }

  /// Global dispose - call this only when the app is destroyed.
  Future<void> dispose() async {
    if (!_initialized) return;
    await _livePlayer?.dispose();
    await _kernel?.dispose();
    _livePlayer = null;
    _kernel = null;
    _initialized = false;
    log('GlobalPlayerService: Disposed.', name: 'GlobalPlayerService');
  }
}
