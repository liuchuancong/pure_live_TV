import '../models/player_engine.dart';
import '../models/player_exception.dart';
import '../models/player_error_type.dart';

class EngineFallbackManager {
  EngineFallbackManager({required this.defaultEngine, this.maxRetryCount = 2});
  final PlayerEngine defaultEngine;
  final int maxRetryCount;
  final Map<PlayerEngine, int> _retryMap = {};
  late final List<PlayerEngine> _priority = [defaultEngine, ...PlayerEngine.values.where((e) => e != defaultEngine)];
  bool shouldFallback(PlayerException error) {
    switch (error.type) {
      case PlayerErrorType.codec:
      case PlayerErrorType.native:
      case PlayerErrorType.texture:
      case PlayerErrorType.initialization:
        return true;
      default:
        return false;
    }
  }

  Future<PlayerEngine> fallback(PlayerEngine current, PlayerException error) async {
    final retry = _retryMap[current] ?? 0;
    if (retry >= maxRetryCount) {
      final currentIndex = _priority.indexOf(current);
      final nextIndex = currentIndex + 1;
      if (nextIndex < _priority.length) {
        return _priority[nextIndex];
      }
      return defaultEngine;
    }
    _retryMap[current] = retry + 1;
    return current;
  }

  void reset(PlayerEngine engine) {
    _retryMap[engine] = 0;
  }
}
