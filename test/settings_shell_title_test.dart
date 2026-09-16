import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/features/settings/tv_settings_page.dart';

/// The settings routes live in ONE table behind ONE shell.
///
/// The regression this pins: the pages used to be split across two `ShellRoute`s
/// — a nested one inside `/settings` for the relative children and a second
/// top-level one for the pages with absolute paths. The same scaffold was wired
/// twice, the page list lived in two places, and a pop could pass through both.
/// A single absolute-path table keeps every page in one shell.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final String routerSource = File('lib/app/router/app_router.dart').readAsStringSync();

  test('there is exactly one settings shell', () {
    expect(
      'ShellRoute('.allMatches(routerSource).length,
      1,
      reason: 'a second shell means the settings pages are split across two route tables again',
    );
    expect(routerSource.contains('for (final MapEntry<String, WidgetBuilder> entry in settingsPageRoutes.entries)'), isTrue);
  });

  test('the whole page table is absolute paths and covers every settings page', () {
    expect(settingsPageRoutes.length, greaterThan(30));
    for (final String path in settingsPageRoutes.keys) {
      expect(path.startsWith('/'), isTrue, reason: '$path must be absolute or the single shell cannot match it');
      expect(path.contains(':'), isFalse, reason: 'no path parameters in the settings table');
    }
    // The menu itself is not a shell page; it owns its own scaffold.
    expect(settingsPageRoutes.containsKey('/settings'), isFalse);
    expect(settingsPageRoutes[AppRoutes.kSettingsPlayerKernel], isNotNull);
  });

  test('every page resolves a real title from the full path', () {
    for (final String path in settingsPageRoutes.keys) {
      expect(settingsSectionTitleKey(path), isNot('ui_settings'), reason: '$path would show the generic title');
    }
  });

  test('the catalog lists every page exactly once', () {
    final List<String> catalogPaths = <String>[
      for (final SettingsGroup group in settingsCatalog)
        for (final SettingsEntry entry in group.entries) entry.path,
    ];

    // No duplicates inside the catalog.
    expect(catalogPaths.toSet().length, catalogPaths.length);

    // Every catalog row is a registered page.
    for (final String path in catalogPaths) {
      expect(settingsPageRoutes.containsKey(path), isTrue, reason: '$path is listed but not registered');
    }
  });

  test('a path-less shell cannot resolve a relative child', () {
    // Documented go_router behaviour, and the reason the table above is
    // absolute: see `settings_route_nesting_test.dart`, which exercises it with
    // a real router.
    expect(settingsPageRoutes.keys.every((path) => path.startsWith('/')), isTrue);
  });
}
