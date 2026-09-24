import 'dart:async';
import 'dart:developer';
import 'live_player_facade.dart';
import 'models/player_engine.dart';
import 'package:media_core/media_core.dart';
import 'package:media_core_ijk_player/media_core_ijk_player.dart';
import 'package:media_core_media_kit/media_core_media_kit.dart';
import 'package:media_core_better_player/media_core_video_player.dart';

export 'live_player_facade.dart';
export 'models/player_engine.dart';
export 'utils/player_consts.dart';

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

  /// The live player facade features consume.
  ///
  /// Null until [initialize] completed.
  LivePlayerFacade? get livePlayer => _livePlayer;

  /// Ensures the service is up on [defaultEngine].
  Future<void> initialize({PlayerEngine defaultEngine = PlayerEngine.mediaKit}) async {
    if (_initialized) return;

    MediaKitPlayerAdapter.ensureInitialized();

    final kernel = PlayerKernel();
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
          id: 'mpv',
          factory: const MediaKitAdapterFactory(),
          capabilities: MediaKitPlayerAdapter.defaultCapabilities,
          priority: priority,
        );
      case PlayerEngine.fijk:
        return PlayerAdapterRegistration(
          id: 'ijk',
          factory: const IjkPlayerAdapterFactory(),
          capabilities: FlvLzcPlayerAdapter.defaultCapabilities,
          priority: priority,
        );
      case PlayerEngine.betterPlayer:
        return PlayerAdapterRegistration(
          id: 'exo',
          factory: const BetterPlayerAdapterFactory(),
          capabilities: BetterPlayerAdapter.defaultCapabilities,
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
