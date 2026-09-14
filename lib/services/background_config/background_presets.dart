import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// 背景预设：纯色卡、渐变预设，以及「旧项目」的填充模式标签。
///
/// 对应 iTab 壁纸库里的「纯色」页签：一屏颜色卡 + 自定义取色器 +
/// 一排渐变色卡（iTab 用的是 webGradients 那套预设）。
class BackgroundPresets {
  BackgroundPresets._();

  /// 纯色预设。
  ///
  /// 前半段取自 iTab 纯色页签的取色器快捷色板（`#ffffff` `#3b78dc` … 共 12 个），
  /// 后半段补上项目主题里常用的深色底 —— 电视上大面积纯色用太亮会刺眼，
  /// 深色底是实际会被用到的那些。
  static const List<Color> solidColors = <Color>[
    Color(0xFFFFFFFF),
    Color(0xFF3B78DC),
    Color(0xFF00AFC7),
    Color(0xFF3B4BA8),
    Color(0xFF8D24A0),
    Color(0xFF008B7D),
    Color(0xFF0F9251),
    Color(0xFFBBC934),
    Color(0xFFE2A600),
    Color(0xFFC83E32),
    Color(0xFF704F42),
    Color(0xFF58727F),
    // 深色底（项目默认背景色系）。
    Color(0xFF141E30),
    Color(0xFF243B55),
    Color(0xFF0F2027),
    Color(0xFF1C1C1C),
    Color(0xFF2B1055),
    Color(0xFF3A1C71),
  ];

  /// 渐变预设：名字 + 颜色序列（iTab 的渐变卡片是线性渐变，这里保持同样的表达）。
  static const List<({String name, List<Color> colors})> gradients =
      <({String name, List<Color> colors})>[
        (name: '深蓝夜色', colors: <Color>[Color(0xFF141E30), Color(0xFF243B55), Color(0xFF141E30)]),
        (name: '暗夜森林', colors: <Color>[Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]),
        (name: '紫罗兰', colors: <Color>[Color(0xFF2B1055), Color(0xFF7597DE)]),
        (name: '落日', colors: <Color>[Color(0xFF3A1C71), Color(0xFFD76D77), Color(0xFFFFAF7B)]),
        (name: '墨黑', colors: <Color>[Color(0xFF000000), Color(0xFF1C1C1C)]),
        // 下面几条对齐 iTab 纯色/渐变页签里出现频率最高的几套配色。
        (name: 'Night Fade', colors: <Color>[Color(0xFFFC96D3), Color(0xFF8B56E9)]),
        (name: 'Winter Neva', colors: <Color>[Color(0xFF259BE5), Color(0xFF8B56E9)]),
        (name: 'Deep Blue', colors: <Color>[Color(0xFF259BE5), Color(0xFFFC96D3), Color(0xFF8B56E9)]),
        (name: 'Dusty Grass', colors: <Color>[Color(0xFF7BCC9B), Color(0xFF259BE5)]),
        (name: 'Malibu Beach', colors: <Color>[Color(0xFF259BE5), Color(0xFFE5E9EC)]),
        (name: 'Premium Dark', colors: <Color>[Color(0xFF434343), Color(0xFF000000)]),
        (name: 'Happy Fisher', colors: <Color>[Color(0xFF259BE5), Color(0xFF7BCC9B)]),
      ];

  /// 在预设里找最接近的颜色（取色器回显用）；找不到返回 0。
  static int closestSolidIndex(Color color) {
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < solidColors.length; i++) {
      final distance = _distance(solidColors[i], color);
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return best;
  }

  static int gradientIndexOf(List<Color> colors) {
    if (colors.isEmpty) return 0;
    var best = 0;
    var bestDistance = double.infinity;
    for (var i = 0; i < gradients.length; i++) {
      final preset = gradients[i].colors;
      if (preset.isEmpty) continue;
      final distance = _distance(preset.first, colors.first) + (preset.length - colors.length).abs() * 16.0;
      if (distance < bestDistance) {
        bestDistance = distance;
        best = i;
      }
    }
    return best;
  }

  static double _distance(Color a, Color b) {
    final dr = (a.r - b.r) * 255;
    final dg = (a.g - b.g) * 255;
    final db = (a.b - b.b) * 255;
    return math.sqrt(dr * dr + dg * dg + db * db);
  }

  /// 解析 `#RRGGBB` / `RRGGBB` / `#AARRGGBB` 这类手输色值；失败返回 null。
  ///
  /// 对应 iTab 纯色页签的取色器：用户可以直接敲一个色值。
  static Color? parseHexColor(String input) {
    var text = input.trim().replaceAll('#', '').replaceAll('0x', '');
    if (text.length == 6) text = 'ff$text';
    if (text.length != 8) return null;
    final value = int.tryParse(text, radix: 16);
    if (value == null) return null;
    return Color(value);
  }
}
