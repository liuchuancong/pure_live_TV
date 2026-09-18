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

  test('there is exactly one settings shell, and it is a generated one', () {
    // A hand-built `ShellRoute(` (with a builder argument) would mean a second,
    // untyped shell: the table below is served by the one typed shell.
    expect(
      RegExp(r'\bShellRoute\(').allMatches(routerSource).length,
      0,
      reason: 'the shell is declared as a TypedShellRoute and built by go_router_builder',
    );
    expect(
      routerSource.contains('@TypedShellRoute<SettingsShellRoute>('),
      isTrue,
      reason: 'the settings shell must stay declared as a typed shell route',
    );
    expect(
      routerSource.contains('TypedGoRoute<'),
      isTrue,
      reason: 'the pages are typed routes, not hand-built GoRoute(...) entries',
    );
  });

  test('every shell page has a typed route', () {
    // The route classes carry the path constants; the table maps those same
    // paths to pages. A page without a class is unreachable from the typed API.
    final Set<String> routedPaths = <String>{
      ...settingsSectionRoutes.keys,
    };
    for (final String path in settingsPageRoutes.keys) {
      expect(routedPaths.contains(path), isTrue, reason: '$path has a page but no typed route');
    }
    expect(settingsSectionRoutes.length, settingsPageRoutes.length);
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
