import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/features/settings/tv_settings_page.dart';

/// The settings menu mirrors the desktop app
/// (`pure_live/lib/modules/settings/settings_page.dart`) and every page must be
/// reachable: either as a menu row or from inside its parent page. These tests
/// keep that true, because an unreachable settings page is the "module has no
/// entry" bug.
void main() {
  List<String> catalogPaths() => <String>[
    for (final SettingsGroup group in settingsCatalog)
      for (final SettingsEntry entry in group.entries) entry.path,
  ];

  test('the menu has the desktop groups, in order', () {
    expect(settingsCatalog.map((group) => group.titleKey).toList(), <String>[
      'theme_settings',
      'iptv_settings',
      'refresh_settings',
      'video_settings',
      'player_kernel_settings',
      'network_proxy_settings',
      'general_settings',
      'data_manage',
      'backup_manage',
      'about',
    ]);

    expect(settingsCatalog.map((group) => group.entries.length).toList(), <int>[1, 1, 1, 2, 1, 1, 3, 1, 1, 1]);
  });

  test('menu rows use the desktop paths and labels', () {
    expect(catalogPaths(), <String>[
      AppRoutes.kSettingsTheme,
      AppRoutes.kIptv,
      AppRoutes.kSettingsRefresh,
      AppRoutes.kSettingsVideo,
      AppRoutes.kSettingsPipDanmaku,
      AppRoutes.kSettingsPlayerKernel,
      AppRoutes.kSettingsProxy,
      AppRoutes.kSettingsGeneral,
      AppRoutes.kSettingsNavigation,
      AppRoutes.kSettingsPlatform,
      AppRoutes.kSettingsCache,
      AppRoutes.kBackup,
      AppRoutes.kAbout,
    ]);

    expect(settingsEntryForLocation(AppRoutes.kSettingsVideo)?.titleKey, 'video');
    expect(settingsEntryForLocation(AppRoutes.kIptv)?.titleKey, 'iptv_settings');
    expect(settingsEntryForLocation('/home'), isNull);
  });

  test('sub-page titles resolve for pages that are not menu rows', () {
    expect(settingsSectionTitleKey(AppRoutes.kSettingsDecoder), 'ui_decoder_settings');
    expect(settingsSectionTitleKey(AppRoutes.kSettingsDanmuShield), 'block_list');
    expect(settingsSectionTitleKey(AppRoutes.kWebDavPage), 'webdav');
    expect(settingsSectionTitleKey(AppRoutes.kSettingsHotAreas), 'platform_display');
    // A menu row wins over the sub-page table.
    expect(settingsSectionTitleKey(AppRoutes.kBackup), 'backup_recover');
  });

  test('no settings route is an orphan', () {
    final routesFile = File('lib/app/router/app_routes.dart');
    final routerFile = File('lib/app/router/app_router.dart');
    if (!routesFile.existsSync() || !routerFile.existsSync()) {
      markTestSkipped('router sources not found relative to ${Directory.current.path}');
      return;
    }

    // Constant name -> path, from AppRoutes.
    final constants = <String, String>{};
    for (final match in RegExp(r'static const (k\w+) = "([^"]+)";').allMatches(routesFile.readAsStringSync())) {
      constants[match.group(1)!] = match.group(2)!;
    }

    // The settings block of the router: from `/settings` up to the next
    // unrelated route.
    final routerSource = routerFile.readAsStringSync();
    final start = routerSource.indexOf('path: AppRoutes.kSettings');
    final end = routerSource.indexOf('path: AppRoutes.kAreaRooms');
    final settingsBranch = start < 0 ? '' : routerSource.substring(start, end < 0 ? routerSource.length : end);

    final registered = <String>{AppRoutes.kSettings};
    for (final match in RegExp(r"GoRoute\(path: '([a-z_]+)'").allMatches(settingsBranch)) {
      registered.add('/settings/${match.group(1)!}');
    }
    for (final match in RegExp(r'GoRoute\(path: AppRoutes\.(k\w+)').allMatches(settingsBranch)) {
      final path = constants[match.group(1)!];
      if (path != null) registered.add(path);
    }
    expect(registered.length, greaterThan(20), reason: 'the settings block should register every page');

    // Every registered path must be referenced by its constant somewhere in the
    // feature code (menu row or parent-page row).
    final referenced = StringBuffer();
    for (final directory in <String>['lib/features', 'lib/app']) {
      final dir = Directory(directory);
      if (!dir.existsSync()) continue;
      for (final file in dir.listSync(recursive: true).whereType<File>()) {
        if (file.path.endsWith('.dart')) referenced.write(file.readAsStringSync());
      }
    }
    final references = referenced.toString();

    final pathToName = <String, String>{for (final entry in constants.entries) entry.value: entry.key};
    final orphans = <String>[];
    for (final path in registered) {
      final name = pathToName[path];
      if (name == null) continue; // paths built from a relative child
      if (!references.contains('AppRoutes.$name')) orphans.add('$name ($path)');
    }

    expect(orphans, isEmpty, reason: 'settings routes with no entry anywhere');
  });
}
