import '../models/player_engine.dart';
import '../interface/unified_player_interface.dart';

class PlayerPool {
  final Map<PlayerEngine, UnifiedPlayer> _cache = {};

  final Future<UnifiedPlayer> Function(PlayerEngine) factory;

  PlayerPool({required this.factory});

  Future<UnifiedPlayer> getPlayer(PlayerEngine engine) async {
    if (_cache.containsKey(engine)) {
      return _cache[engine]!;
    }

    final player = await factory(engine);

    await player.init();

    _cache[engine] = player;

    return player;
  }

  Future<void> disposeAll() async {
    for (final player in _cache.values) {
      await player.hardDispose();
    }

    _cache.clear();
  }
}
