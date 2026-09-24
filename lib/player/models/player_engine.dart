enum PlayerEngine { mediaKit, fijk, betterPlayer }

abstract class BackendIds {
  static const String mediaKit = 'mpv';
  static const String fijk = 'ijk';
  static const String betterPlayer = 'better_player';
}

class PlayerEngineConfig {
  final PlayerEngine engine;
  final String nameKey;

  const PlayerEngineConfig({required this.engine, required this.nameKey});
}
