/// Candidate values and stepping logic for the danmaku settings panel.
///
/// The value tables mirror DanmakuConstants from the legacy `pure_live` app so
/// both apps feel the same and persist identical numbers. Left/Right cycles
/// through exactly these candidates.
class DanmakuOptionSteps {
  DanmakuOptionSteps._();

  /// Font size.
  static const List<double> fontSize = <double>[10, 12, 14, 16, 18, 20, 22, 24, 28, 32, 40, 48, 64, 72];

  /// Speed, in px/s — the unit the engine's `baseSpeed` is in.
  ///
  /// The old table (4-32) was the legacy app's "speed level" scale; feeding those numbers
  /// straight to the renderer froze every danmaku at a few pixels per second.
  static const List<double> speed = <double>[40, 60, 80, 100, 120, 150, 180, 210, 240, 280, 320, 360, 400];

  /// Display area ratio and opacity (0.1 - 1.0).
  static const List<double> ratio = <double>[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];

  /// Distance from the top and from the bottom, in logical pixels (0 - 300).
  static const List<double> distance = <double>[0, 10, 20, 30, 40, 50, 70, 100, 140, 180, 220, 260, 300];

  /// Stroke width, in logical pixels (0 - 8).
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

  /// Speed, in the unit the engine takes (`px/s`).
  static String speedLabel(double value) => '${number(value)} px/s';

  /// Distances and stroke widths are plain logical pixels; showing the value the engine
  /// receives is the point — the old stroke label multiplied it by two and added two.
  static String pixelLabel(double value) => '${number(value)} px';

  /// Integers are shown without a decimal point.
  static String number(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
}
