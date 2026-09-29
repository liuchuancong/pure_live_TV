/// Queue advance rules, cycled by one button.
enum MusicPlayMode {
  /// Wrap around the queue after the last track.
  sequence,

  /// Replay the current track.
  loopOne,

  /// Jump to a random different track.
  random;

  String get i18nKey => switch (this) {
    sequence => 'music_mode_sequence',
    loopOne => 'music_mode_loop_one',
    random => 'music_mode_random',
  };

  MusicPlayMode get next => switch (this) {
    sequence => loopOne,
    loopOne => random,
    random => sequence,
  };
}
