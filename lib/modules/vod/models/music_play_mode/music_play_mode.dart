/// Queue advance rules, cycled by one button.
enum MusicPlayMode {
  /// Wrap around the queue after the last track.
  sequence,

  /// Replay the current track.
  loopOne,

  /// Jump to a random not-yet-played track; the round reshuffles once every
  /// track has been played, and previous walks back through the random order.
  random,

  /// Play forward to the end of the queue and stop — no wrap.
  orderStop;

  String get i18nKey => switch (this) {
    sequence => 'music_mode_sequence',
    loopOne => 'music_mode_loop_one',
    random => 'music_mode_random',
    orderStop => 'music_mode_order_stop',
  };

  MusicPlayMode get next => switch (this) {
    sequence => loopOne,
    loopOne => random,
    random => orderStop,
    orderStop => sequence,
  };
}
