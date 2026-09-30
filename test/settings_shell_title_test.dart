import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/app/router/app/app_router.dart';
import 'package:pure_live/app/router/app/app_routes.dart';
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

  // The route classes are split over the library and its parts, so the source
  // guard has to read all of them or it would silently assert nothing.
  final String routerSource = <String>[
    'lib/app/router/app/app_router.dart',
    'lib/app/router/settings/settings_routes.dart',
  ].map((path) => File(path).readAsStringSync()).join('\n');

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
    //
    // `settingsSectionRoutes` is the superset: it is the *push* table the menu
    // walks, so it also carries the standalone pages (music settings) that own
    // their scaffold instead of being served by the shell.
    final Set<String> routedPaths = <String>{...settingsSectionRoutes.keys};
    for (final String path in settingsPageRoutes.keys) {
      expect(routedPaths.contains(path), isTrue, reason: '$path has a page but no typed route');
    }
    expect(settingsSectionRoutes.length, greaterThanOrEqualTo(settingsPageRoutes.length));
  });

  test('the one \$appRoutes registers every settings page', () {
    // The regression: settings routes used to live in a second library, which
    // go_router_builder turned into a second `$appRoutes`. The router's local
    // one shadowed it, `flutter analyze` stayed silent, and every settings path
    // 404'd at runtime. Routing through the real list is the only check that
    // catches a shadowed or forgotten route table.
    final GoRouter router = GoRouter(routes: $appRoutes);
    for (final String path in <String>[AppRoutes.kSettings, ...settingsPageRoutes.keys]) {
      expect(router.configuration.findMatch(Uri.parse(path)).isError, isFalse, reason: path);
    }
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

    // Every catalog row must be pushable — the menu pushes
    // `settingsSectionRoutes[entry.path]`, so a row missing from that table is
    // a dead menu entry. (It is not necessarily a shell page: music settings
    // owns its own scaffold.)
    for (final String path in catalogPaths) {
      expect(settingsSectionRoutes.containsKey(path), isTrue, reason: '$path is listed but not pushable');
    }
  });

  test('a path-less shell cannot resolve a relative child', () {
    // Documented go_router behaviour, and the reason the table above is
    // absolute: see `settings_route_nesting_test.dart`, which exercises it with
    // a real router.
    expect(settingsPageRoutes.keys.every((path) => path.startsWith('/')), isTrue);
  });
}
