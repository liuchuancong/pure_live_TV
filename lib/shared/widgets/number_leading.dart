import 'package:flutter/material.dart';

/// A leading widget that shows a number instead of an icon.
///
/// Sizes itself to match a typical [ListTile] leading (24 logical pixels by
/// default) and paints the number in the colour the surrounding [IconTheme]
/// carries, so it follows a focus/selection tint the same way a real icon does.
class NumberLeading extends StatelessWidget {
  const NumberLeading(this.number, {super.key, this.size = 18, this.color, this.fontWeight = FontWeight.w600});

  /// The number to draw. Any int; multi-digit values shrink the glyph to fit.
  final int number;

  /// Box size, matching [IconThemeData.size] by default.
  final double size;

  /// Overrides the colour from [IconTheme]; when null the theme colour (or the
  /// ambient text colour) is used.
  final Color? color;

  final FontWeight fontWeight;

  @override
  Widget build(BuildContext context) {
    final Color resolved =
        color ?? IconTheme.of(context).color ?? DefaultTextStyle.of(context).style.color ?? Colors.white;

    final String text = '$number';
    // Two digits fit at ~0.85×; three or more need to shrink further so the
    // glyphs never overflow the square the tile reserves for a leading.
    final double scale = text.length <= 1
        ? 0.95
        : text.length == 2
        ? 0.78
        : 0.6;

    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: resolved,
            fontSize: size * scale,
            fontWeight: fontWeight,
            height: 1.0,
            leadingDistribution: TextLeadingDistribution.even,
          ),
        ),
      ),
    );
  }
}
