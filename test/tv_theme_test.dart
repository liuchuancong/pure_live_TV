import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/theme/index.dart';

/// Theme presets carry a translation *key*, not a translated string.
///
/// Storing `i18n(...)` in the preset froze whichever language was active when
/// the preset was first touched, so switching the app language left the theme
/// names in the old language. These tests keep the names translatable.
void main() {
  final List<TvThemeData> themes = <TvThemeData>[
    darkTvTheme,
    blueTvTheme,
    animeTvTheme,
    cyberTvTheme,
    ...extraTvThemes,
  ];

  test('theme ids stay unique', () {
    final ids = themes.map((theme) => theme.id).toList();
    expect(ids.toSet().length, ids.length, reason: 'duplicate theme id');
    expect(ids, contains('dark'));
  });

  test('there is a real choice of presets', () {
    expect(themes.length, greaterThanOrEqualTo(10));
  });

  test('every preset name is translated in both languages', () {
    for (final lang in <String>['zh', 'en']) {
      final file = File('assets/translations/$lang.json');
      if (!file.existsSync()) {
        markTestSkipped('translations not found relative to ${Directory.current.path}');
        return;
      }
      final translations = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      for (final theme in themes) {
        expect(theme.nameKey, isNotEmpty, reason: theme.id);
        expect(
          translations.containsKey(theme.nameKey),
          isTrue,
          reason: '${theme.id}: ${theme.nameKey} missing from $lang.json',
        );
      }
    }
  });

  test('presets hold a coherent palette', () {
    for (final theme in themes) {
      expect(theme.focusColor, isNot(theme.backgroundColor), reason: theme.id);
      expect(theme.primaryTextColor, isNot(theme.backgroundColor), reason: theme.id);
      expect(theme.focusedCardColor, isNot(theme.focusColor), reason: theme.id);
    }
  });

  test('palettes are designed rather than accent swaps', () {
    // A theme only looks different if its own surfaces differ: the theme
    // supplies the page background whenever no background is configured.
    final backgrounds = themes.map((theme) => theme.backgroundColor.toARGB32()).toSet();
    final cards = themes.map((theme) => theme.cardColor.toARGB32()).toSet();
    final accents = themes.map((theme) => theme.focusColor.toARGB32()).toSet();

    expect(backgrounds.length, greaterThanOrEqualTo(8), reason: 'too many presets share one base surface');
    expect(cards.length, greaterThanOrEqualTo(8), reason: 'too many presets share one card tone');
    expect(accents.length, themes.length, reason: 'two presets share an accent colour');
  });

  test('both dark and light presets exist, and light ones keep readable text', () {
    bool isLight(TvThemeData theme) => theme.backgroundColor.computeLuminance() > 0.5;

    final light = themes.where(isLight).toList();
    expect(light, isNotEmpty, reason: 'no light preset');
    expect(themes.where((theme) => !isLight(theme)), isNotEmpty, reason: 'no dark preset');

    for (final theme in light) {
      expect(theme.primaryTextColor.computeLuminance(), lessThan(0.35), reason: theme.id);
      expect(theme.secondaryTextColor.computeLuminance(), lessThan(0.5), reason: theme.id);
    }
  });

  test('text on a focused card contrasts with that card in every preset', () {
    // The room card and the player rows paint their content with
    // `onFocusedCard`. Most presets focus a card onto white and the
    // coffee/amber/mint/… ones onto a dark shade, and the light presets focus
    // onto white as well — the rule that used the page background as the focused
    // text colour left near-white text on a white card on every light palette.
    for (final theme in themes) {
      final double contrast =
          (theme.onFocusedCard.computeLuminance() - theme.focusedCardColor.computeLuminance()).abs();
      expect(contrast, greaterThan(0.5), reason: '${theme.id}: focused card text is unreadable');
    }
  });
}
