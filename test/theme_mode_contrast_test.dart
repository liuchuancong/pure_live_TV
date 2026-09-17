import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/theme/index.dart';

/// Every preset must be readable in **both** 主题模式 settings.
///
/// The presets were designed as fixed palettes, so the mode used to change only the
/// Material layer: the custom widgets kept the preset's own brightness and 浅色
/// looked like it did nothing. `TvThemeData.resolveFor` now derives a sibling palette
/// per mode, and these invariants are what "derived" has to mean — each pairing that
/// the widgets actually paint must keep its contrast.
void main() {
  /// WCAG relative-luminance contrast ratio.
  double contrast(Color a, Color b) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    final double lighter = math.max(la, lb);
    final double darker = math.min(la, lb);
    return (lighter + 0.05) / (darker + 0.05);
  }

  final List<TvThemeData> presets = <TvThemeData>[
    darkTvTheme,
    blueTvTheme,
    animeTvTheme,
    cyberTvTheme,
    ...extraTvThemes,
  ];

  for (final TvThemeData preset in presets) {
    for (final Brightness brightness in Brightness.values) {
      final TvThemeData palette = preset.resolveFor(brightness: brightness);
      test('${preset.id} in ${brightness.name}: the painted pairings stay readable', () {
        expect(
          contrast(palette.primaryTextColor, palette.backgroundColor),
          greaterThan(4.5),
          reason: 'title text on the page background',
        );
        expect(
          contrast(palette.primaryTextColor, palette.cardColor),
          greaterThan(4.5),
          reason: 'row text on a card',
        );
        expect(
          contrast(palette.secondaryTextColor, palette.cardColor),
          greaterThan(3.0),
          reason: 'subtitle text on a card',
        );
        expect(
          contrast(palette.secondaryTextColor, palette.backgroundColor),
          greaterThan(3.0),
          reason: 'secondary text on the page background',
        );
        expect(
          contrast(palette.onFocusColor, palette.focusColor),
          greaterThan(3.0),
          reason: 'content on an accent-filled (focused/selected) surface',
        );
        expect(
          contrast(palette.onFocusedCard, palette.focusedCardColor),
          greaterThan(4.3),
          reason: 'content on a focused card',
        );
        expect(
          contrast(palette.onFadedFocusColor, Color.lerp(palette.backgroundColor, palette.focusColor, 0.5)!),
          greaterThan(3.0),
          reason: 'content on the faded focus fill',
        );
        expect(
          contrast(palette.focusColor, palette.backgroundColor),
          greaterThan(3.0),
          reason: 'the accent itself: focus rings, borders and accent-coloured labels '
              'are drawn in it straight onto the page',
        );
      });
    }
  }
}
