/// Candidate values and stepping logic for the danmaku settings panel.
///
/// The value tables mirror DanmakuConstants from the legacy `pure_live` app so
/// both apps feel the same and persist identical numbers. Left/Right cycles
/// through exactly these candidates.
class DanmakuOptionSteps {
  DanmakuOptionSteps._();

  /// Font size.
  static const List<double> fontSize = <double>[10, 12, 14, 16, 18, 20, 22, 24, 28, 32, 40, 48, 64, 72];

  /// Speed.
  static const List<double> speed = <double>[4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32];

  /// Display area and opacity (0.1 - 1.0).
  static const List<double> ratio = <double>[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];

  /// Distance from the top and from the bottom.
  static const List<double> distance = <double>[0, 5, 10, 15, 20, 25, 30, 35, 40, 50, 70, 100];

  /// Stroke width: stored as 0-8 and displayed as 2-18.
  static const List<double> stroke = <double>[0, 1, 2, 3, 4, 5, 6, 7, 8];

  /// Steps through [values] in the [forward] direction, wrapping at the ends and
  /// snapping to the nearest entry when an exact match is missing.
  static double step(List<double> values, double current, {required bool forward}) {
    if (values.isEmpty) return current;
    var index = values.indexOf(current);
    if (index < 0) {
      var best = 0;
      var bestDelta = double.infinity;
      for (var i = 0; i < values.length; i++) {
        final delta = (values[i] - current).abs();
        if (delta < bestDelta) {
          bestDelta = delta;
          best = i;
        }
      }
      index = best;
    }
    final next = forward ? (index + 1) % values.length : (index - 1 + values.length) % values.length;
    return values[next];
  }

  /// Renders 0.1 - 1.0 as a percentage.
  static String percent(double value) => '${(value * 100).round()}%';

  /// Maps a stored stroke value to its real width.
  static String strokeLabel(double value) => '${(value * 2 + 2).round()}';

  /// Integers are shown without a decimal point.
  static String number(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
}
