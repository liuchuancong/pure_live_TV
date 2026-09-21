import 'dart:async';
import 'dart:developer';

import 'package:media_core/media_core.dart';
import 'package:media_kit/media_kit.dart' as mk;

import 'adapters/flv_lzc_adapter.dart';
import 'adapters/media_kit_core_adapter.dart';
import 'live_player_facade.dart';
import 'models/player_engine.dart';

export 'live_player_facade.dart';
export 'models/player_engine.dart';
export 'models/player_state.dart' show PlayerState;
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

    mk.MediaKit.ensureInitialized();

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
        final registration = _registrationOf(engine, priority: 100);
        kernel.registry.unregister(registration.id);
        kernel.registerBackend(registration);
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
          factory: _MediaKitFactory(),
          capabilities: PureLiveMediaKitAdapter.defaultCapabilities,
          priority: priority,
        );
      case PlayerEngine.fijk:
        return PlayerAdapterRegistration(
          id: 'ijk',
          factory: _FlvLzcFactory(),
          capabilities: FlvLzcPlayerAdapter.defaultCapabilities,
          priority: priority,
        );
      case PlayerEngine.betterPlayer:
        // The legacy Exo adapter is retired; route it to MPV so a
        // stored preference keeps working.
        return PlayerAdapterRegistration(
          id: 'mpv',
          factory: _MediaKitFactory(),
          capabilities: PureLiveMediaKitAdapter.defaultCapabilities,
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

class _MediaKitFactory implements PlayerAdapterFactory {
  @override
  PlayerAdapter create(String id) => PureLiveMediaKitAdapter(id: id);

  @override
  bool supports(String id) => id == 'mpv' || id.isEmpty;
}

class _FlvLzcFactory implements PlayerAdapterFactory {
  @override
  PlayerAdapter create(String id) => FlvLzcPlayerAdapter(id: id);

  @override
  bool supports(String id) => id == 'ijk' || id.isEmpty;
}
