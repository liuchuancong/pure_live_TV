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
}
