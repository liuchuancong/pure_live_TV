/// 弹幕设置面板的候选值与步进逻辑。
///
/// 取值表移植自老项目 `pure_live` 的 `DanmakuConstants`，保证两端调节手感和
/// 落库数值完全一致；面板里左右键就是在这些候选值之间循环取值。
class DanmakuOptionSteps {
  DanmakuOptionSteps._();

  /// 字号
  static const List<double> fontSize = <double>[10, 12, 14, 16, 18, 20, 22, 24, 28, 32, 40, 48, 64, 72];

  /// 速度
  static const List<double> speed = <double>[4, 6, 8, 10, 12, 14, 16, 18, 20, 22, 24, 26, 28, 30, 32];

  /// 显示区域 / 不透明度（0.1 - 1.0）
  static const List<double> ratio = <double>[0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0];

  /// 距离顶部 / 距离底部
  static const List<double> distance = <double>[0, 5, 10, 15, 20, 25, 30, 35, 40, 50, 70, 100];

  /// 描边宽度（存储 0-8，展示为 2-18）
  static const List<double> stroke = <double>[0, 1, 2, 3, 4, 5, 6, 7, 8];

  /// 在 [values] 里朝 [forward] 方向取相邻值；越界循环，找不到精确值时先就近对齐。
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

  /// 0.1 - 1.0 显示成百分比。
  static String percent(double value) => '${(value * 100).round()}%';

  /// 描边存储值转实际宽度。
  static String strokeLabel(double value) => '${(value * 2 + 2).round()}';

  /// 整数不带小数点。
  static String number(double value) =>
      value == value.roundToDouble() ? value.round().toString() : value.toStringAsFixed(1);
}
