import 'dart:async';
import 'dart:developer';
import 'live_player_facade.dart';
import 'models/player_engine.dart';
import 'core/playback_proxy_policy.dart';
import '../services/settings/settings.dart';
import 'package:media_core/media_core.dart';
import 'package:media_core_native/media_core_native.dart';
import 'package:media_core_media_kit/media_core_media_kit.dart';
import 'package:media_core_ijk_player/media_core_ijk_player.dart';
import 'package:media_core_fvp/media_core_fvp.dart';
import 'package:media_core_better_player/media_core_video_player.dart';

/// Builds the media_kit adapter configuration from the persisted engine
/// switches.
///
/// The package adapter takes its configuration by construction and never reads
/// this app's settings, so the factory has to rebuild the config for every
/// adapter the kernel creates. A settings change then applies to the next
/// player session instead of being silently dropped.
///
/// The fields that libmpv only honours on one platform (compat mode, RTX VSR)
/// are forwarded as stored; the adapter ignores them elsewhere. Driver values
/// are forwarded unnormalised because the adapter normalises them per platform
/// itself.
MediaKitPlayerConfig buildMediaKitPlayerConfig() {
  final settings = SettingsService.to.playerState;
  return MediaKitPlayerConfig(
    // A loopback/private input must never be sent through the native proxy.
    proxyUrlResolver: ({required bool privateInput}) =>
        PlaybackProxyPolicy.currentNativeUrl(privateInput: privateInput),
    enableCodec: settings.enableCodec,
    playerCompatMode: settings.playerCompatMode,
    customPlayerOutput: settings.customPlayerOutput,
    videoHardwareDecoder: settings.videoHardwareDecoder,
    videoOutputDriver: settings.videoOutputDriver,
    audioOutputDriver: settings.audioOutputDriver,
    enableRtxVsr: settings.enableRtxVsr,
  );
}

/// Builds the ijkplayer adapter configuration from the persisted switches.
FijkPlayerConfig buildFijkPlayerConfig() {
  final settings = SettingsService.to.playerState;
  return FijkPlayerConfig(
    proxyUrlResolver: ({required bool privateInput}) =>
        PlaybackProxyPolicy.currentNativeUrl(privateInput: privateInput),
    enableCodec: settings.enableCodec,
  );
}

/// Builds the fvp (libmdk) adapter configuration from the persisted engine
/// switches.
///
/// fvp is the Android backup engine: it ships a current FFmpeg plus the
/// platform hardware decoders, so it recovers sources the bundled libmpv drops
/// (legacy codec-id-12 HEVC FLV, for example). The adapter applies the Android
/// audio-backend order and the legacy-HEVC software rule itself; they are
/// visible here only because they are configuration.
FvpPlayerConfig buildFvpPlayerConfig() {
  final settings = SettingsService.to.playerState;
  return FvpPlayerConfig(
    // A loopback/private input must never be sent through the proxy.
    proxyUrlResolver: ({required bool privateInput}) =>
        PlaybackProxyPolicy.currentNativeUrl(privateInput: privateInput),
    enableCodec: settings.enableCodec,
  );
}

/// Creates a media_kit adapter with the current settings.
///
/// Registered under the app's historical backend id `mpv`
/// ([PlayerConsts.defaultKey]); the kernel addresses the registration by that
/// id and never consults [PlayerAdapterFactory.supports].
final class _MediaKitFactory implements PlayerAdapterFactory {
  const _MediaKitFactory();

  @override
  PlayerAdapter create(String id) => MediaKitPlayerAdapter(
    id: id,
    capabilities: MediaKitPlayerAdapter.defaultCapabilities,
    config: buildMediaKitPlayerConfig(),
  );

  @override
  bool supports(String id) => id == BackendIds.mediaKit || id.isEmpty;
}

/// Creates an fvp adapter with the current settings.
final class _FvpFactory implements PlayerAdapterFactory {
  const _FvpFactory();

  @override
  PlayerAdapter create(String id) =>
      FvpPlayerAdapter(id: id, capabilities: FvpPlayerAdapter.defaultCapabilities, config: buildFvpPlayerConfig());

  @override
  bool supports(String id) => id == BackendIds.fvp || id.isEmpty;
}

/// Creates an ijkplayer (flv_lzc) adapter with the current settings.
final class _FlvLzcFactory implements PlayerAdapterFactory {
  const _FlvLzcFactory();

  @override
  PlayerAdapter create(String id) => FlvLzcPlayerAdapter(
    id: id,
    capabilities: FlvLzcPlayerAdapter.defaultCapabilities,
    config: buildFijkPlayerConfig(),
  );

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

  /// Ensures the service is up on [defaultEngine].
  Future<void> initialize({PlayerEngine defaultEngine = PlayerEngine.mediaKit}) async {
    if (_initialized) return;
    MediaKitPlayerAdapter.ensureInitialized();
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
