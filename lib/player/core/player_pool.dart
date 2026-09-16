import '../models/player_engine.dart';
import '../interface/unified_player_interface.dart';

class PlayerPool {
  final Map<PlayerEngine, UnifiedPlayer> _cache = {};

  final Future<UnifiedPlayer> Function(PlayerEngine) factory;

  PlayerPool({required this.factory});

  /// Returns the pooled adapter for [engine], creating it on first use.
  ///
  /// A cached adapter is reused, so [audioOnly] is re-applied to it: the mode
  /// is reversible per player, and a caller that flips 仅播放音频 must not get
  /// the stale mode of the instance created earlier.
  Future<UnifiedPlayer> getPlayer(PlayerEngine engine, {bool audioOnly = false}) async {
    final cached = _cache[engine];
    if (cached != null) {
      await cached.setAudioOnly(audioOnly);
      return cached;
    }

    final player = await factory(engine);

    await player.init(audioOnly: audioOnly);

    _cache[engine] = player;

    return player;
  }

  /// Applies [audioOnly] to every pooled adapter, including idle ones.
  ///
  /// Used when the setting changes while a player already exists: the pooled
  /// instances are what a later engine switch hands back to the manager.
  Future<void> setAudioOnly(bool audioOnly) async {
    for (final player in _cache.values.toList(growable: false)) {
      await player.setAudioOnly(audioOnly);
    }
  }

  Future<void> removeFromCache(PlayerEngine engine) async {
    if (_cache.containsKey(engine)) {
      final player = _cache[engine]!;
      await player.hardDispose(); // release the native player
      _cache.remove(engine); // drop it from the cache
    }
  }

  /// Drops [player] from the cache, whichever engine slot holds it.
  ///
  /// Every destroyed adapter must be evicted: a disposed instance left behind
  /// is handed out again by [getPlayer], and each native call on it then fails
  /// with `Assertion failed: "[Player] has been disposed"` — the surface also
  /// keeps a dead `ValueNotifier` and throws once per frame.
  Future<void> evict(UnifiedPlayer player) async {
    _cache.removeWhere((_, cached) => identical(cached, player));
  }

  Future<void> disposeAll() async {
    for (final player in _cache.values) {
      await player.hardDispose();
    }

    _cache.clear();
  }
}
