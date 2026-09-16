import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/features/settings/tv_settings_page.dart';

/// Every settings section page takes its title from the location its shell
/// receives, so the location the router hands over has to be the full path.
///
/// The regression this pins: `GoRouterState.matchedLocation` reports only the
/// relative segment of a relative child match — `general` for
/// `/settings/general` — so `settingsSectionTitleKey` never matched a row or a
/// sub-page and *every* section page showed the generic "系统设置".
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final routerSource = File('lib/app/router/app_router.dart').readAsStringSync();
  final routesSource = File('lib/app/router/app_routes.dart').readAsStringSync();

  final constants = <String, String>{
    for (final RegExpMatch m in RegExp(r'static const (k\w+) = "([^"]+)";').allMatches(routesSource)) m.group(1)!: m.group(2)!,
  };

  // The settings block, up to the standalone picker routes (which own their
  // scaffold and therefore their title).
  final settingsBranch = routerSource.substring(
    routerSource.indexOf('path: AppRoutes.kSettings'),
    routerSource.indexOf('path: AppRoutes.kSettingsIconPicker'),
  );

  // `/settings/<module>` — relative children of the nested shell.
  final relativePaths = <String>[
    for (final RegExpMatch m in RegExp(r"GoRoute\(path: '([a-z_]+)'").allMatches(settingsBranch)) '/settings/${m.group(1)!}',
  ];

  // The pages the desktop app also gives a named route: absolute children of
  // the second shell.
  final secondShell = settingsBranch.substring(settingsBranch.lastIndexOf('ShellRoute('));
  final absolutePaths = <String>[
    for (final RegExpMatch m in RegExp(r'GoRoute\(path: AppRoutes\.(k\w+)').allMatches(secondShell))
      if (constants[m.group(1)!] != null) constants[m.group(1)!]!,
  ];

  final allPaths = <String>[...relativePaths, ...absolutePaths];

  test('the router hands the settings shell an absolute location', () {
    expect(settingsBranch, contains('SettingsSectionScaffold'), reason: 'the extracted block must be the real one');
    expect(settingsBranch, contains("ShellRoute("));
    // What the relative form resolves to: nothing, hence the generic title.
    expect(settingsSectionTitleKey('general'), 'ui_settings');
    expect(settingsSectionTitleKey('/settings/general'), isNot('ui_settings'));
    expect(
      settingsBranch.contains('location: state.matchedLocation'),
      isFalse,
      reason: 'a relative child match reports "general", not "/settings/general"',
    );
    expect(settingsBranch.contains('location: state.uri.path'), isTrue);
    expect(allPaths.length, greaterThan(20), reason: 'the settings table registers every page');
    expect(relativePaths, contains('/settings/general'));
    expect(absolutePaths, contains('/iptv'));
  });

  testWidgets('every settings section resolves a real title from that location', (WidgetTester tester) async {
    final seen = <String>{};

    final router = GoRouter(
      initialLocation: '/settings',
      routes: [
        GoRoute(
          path: '/settings',
          builder: (context, state) => const SizedBox.shrink(),
          routes: [
            ShellRoute(
              builder: (context, state, child) {
                seen.add(state.uri.path);
                return child;
              },
              routes: [
                for (final String path in relativePaths)
                  GoRoute(
                    path: path.substring('/settings/'.length),
                    builder: (context, state) => const SizedBox.shrink(),
                  ),
              ],
            ),
          ],
        ),
        ShellRoute(
          builder: (context, state, child) {
            seen.add(state.uri.path);
            return child;
          },
          routes: [
            for (final String path in absolutePaths) GoRoute(path: path, builder: (context, state) => const SizedBox.shrink()),
          ],
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    for (final String path in allPaths) {
      router.go(path);
      await tester.pumpAndSettle();

      expect(seen, contains(path), reason: '$path never reached a settings shell');
      expect(settingsSectionTitleKey(path), isNot('ui_settings'), reason: '$path would show the generic title');
    }
  });
}
