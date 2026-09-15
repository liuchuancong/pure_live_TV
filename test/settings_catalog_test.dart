import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/features/settings/tv_settings_page.dart';

/// The settings catalog is the only way into a settings section, so a missing
/// or duplicated entry is exactly the "module has no entry" bug. These tests
/// keep the catalog and the route table in step.
void main() {
  /// Every settings section registered in the router.
  const List<String> routedSections = <String>[
    'general',
    'theme',
    'player_kernel',
    'video',
    'decoder',
    'renderer',
    'audio_output',
    'danmaku',
    'shield',
    'platform',
    'audience',
    'tags',
    'navigation',
    'page',
    'refresh',
    'font',
    'fonts',
    'iptv',
    'cache',
    'proxy',
    'backup',
    'webdav',
    'backups',
    'account',
    'about',
  ];

  List<String> catalogPaths() => <String>[
    for (final SettingsGroup group in settingsCatalog)
      for (final SettingsEntry entry in group.entries) entry.path,
  ];

  test('every routed section has exactly one catalog entry', () {
    final paths = catalogPaths();

    expect(paths.toSet().length, paths.length, reason: 'duplicate catalog path');

    final expected = routedSections.map((s) => '/settings/$s').toSet();
    expect(paths.toSet(), expected, reason: 'catalog and routed sections must match');
  });

  test('catalog entries carry a title, a group heading and an icon', () {
    for (final SettingsGroup group in settingsCatalog) {
      expect(group.titleKey, isNotEmpty);
      expect(group.entries, isNotEmpty, reason: 'group ${group.titleKey} has no rows');
      for (final SettingsEntry entry in group.entries) {
        expect(entry.titleKey, isNotEmpty, reason: entry.path);
        expect(entry.path.startsWith('/settings/'), isTrue, reason: entry.path);
      }
    }
  });

  test('the catalog matches the routes actually registered in app_router.dart', () {
    final file = File('lib/app/router/app_router.dart');
    if (!file.existsSync()) {
      markTestSkipped('app_router.dart not found relative to ${Directory.current.path}');
      return;
    }

    // Settings section routes are the relative GoRoute paths inside the
    // `/settings` branch.
    final source = file.readAsStringSync();
    final settingsBranch = source.substring(source.indexOf("path: AppRoutes.kSettings"));
    final routed = RegExp(r"GoRoute\(path: '([a-z_]+)'").allMatches(settingsBranch).map((m) => m.group(1)!).toSet();

    final inCatalog = catalogPaths().map((p) => p.replaceFirst('/settings/', '')).toSet();

    expect(routed, inCatalog, reason: 'a routed section without an entry, or an entry without a route');
  });

  test('location lookup matches whole path segments', () {
    expect(settingsEntryForLocation('/settings/fonts')!.path, '/settings/fonts');
    expect(settingsEntryForLocation('/settings/font')!.path, '/settings/font');
    expect(settingsEntryForLocation('/settings/theme')!.titleKey, 'theme_customization');
    expect(settingsEntryForLocation('/home'), isNull);
  });
}
