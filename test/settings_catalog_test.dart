import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/app/router/app_router.dart';
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

    expect(settingsCatalog.map((group) => group.entries.length).toList(), <int>[1, 1, 1, 1, 1, 1, 3, 1, 1, 1]);
  });

  test('menu rows use the desktop paths and labels', () {
    expect(catalogPaths(), <String>[
      AppRoutes.kSettingsTheme,
      AppRoutes.kIptv,
      AppRoutes.kSettingsRefresh,
      AppRoutes.kSettingsVideo,
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
    // The page titles the mobile app uses, not the generic TV ones.
    expect(settingsSectionTitleKey(AppRoutes.kSettingsDecoder), 'hardware_decoder');
    expect(settingsSectionTitleKey(AppRoutes.kSettingsRenderer), 'video_output_driver');
    expect(settingsSectionTitleKey(AppRoutes.kSettingsAudioOutput), 'audio_output_driver');
    expect(settingsSectionTitleKey(AppRoutes.kSettingsDanmuShield), 'danmaku_keyword_block');
    expect(settingsSectionTitleKey(AppRoutes.kSettingsFont), 'font_settings_title');
    expect(settingsSectionTitleKey(AppRoutes.kWebDavPage), 'webdav');
    expect(settingsSectionTitleKey(AppRoutes.kSettingsHotAreas), 'platform_display');

    // A page may be titled differently from the menu row that opens it.
    expect(settingsSectionTitleKey(AppRoutes.kSettingsVideo), 'video_settings');
    expect(settingsSectionTitleKey(AppRoutes.kSettingsPlayerKernel), 'player_kernel_settings');
    expect(settingsSectionTitleKey(AppRoutes.kSettingsProxy), 'network_proxy_settings');

    // A page that is not in the table falls back to its menu row.
    expect(settingsSectionTitleKey(AppRoutes.kBackup), 'backup_recover');

    // The most specific path wins, so a platform page is not named after 三方认证.
    expect(settingsSectionTitleKey(AppRoutes.kSettingsAccount), 'third_party_auth');
    expect(settingsSectionTitleKey(AppRoutes.kSettingsAccountHuya), 'site_huya');
  });

  test('every settings route has a real title, never the fallback', () {
    // A sub-page whose title falls back to the generic one shows "系统设置" in
    // its title bar, which tells the user nothing about where they are.
    const List<String> routes = <String>[
      AppRoutes.kSettingsTheme,
      AppRoutes.kSettingsThemePicker,
      AppRoutes.kSettingsLoadingStyle,
      AppRoutes.kSettingsColorPicker,
      AppRoutes.kSettingsIconPicker,
      AppRoutes.kSettingsRefresh,
      AppRoutes.kSettingsVideo,
      AppRoutes.kSettingsPlayerKernel,
      AppRoutes.kSettingsProxy,
      AppRoutes.kSettingsGeneral,
      AppRoutes.kSettingsNavigation,
      AppRoutes.kSettingsPlatform,
      AppRoutes.kSettingsCache,
      AppRoutes.kSettingsConfigPreview,
      AppRoutes.kSettingsDecoder,
      AppRoutes.kSettingsRenderer,
      AppRoutes.kSettingsAudioOutput,
      AppRoutes.kSettingsDanmaku,
      AppRoutes.kSettingsFont,
      AppRoutes.kSettingsFontFamily,
      AppRoutes.kSettingsPage,
      AppRoutes.kSettingsAudience,
      AppRoutes.kSettingsLocalBackup,
      AppRoutes.kIptv,
      AppRoutes.kSettingsHotAreas,
      AppRoutes.kSettingsAccount,
      AppRoutes.kSettingsTags,
      AppRoutes.kBackup,
      AppRoutes.kWebDavPage,
      AppRoutes.kSettingsDanmuShield,
      AppRoutes.kAbout,
    ];

    for (final String route in routes) {
      expect(settingsSectionTitleKey(route), isNot('ui_settings'), reason: route);
    }
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

    // The page table the single settings shell iterates. It is imported rather
    // than scraped out of the router source, so this test cannot drift from the
    // real table (it used to parse two separate route blocks).
    final registered = <String>{AppRoutes.kSettings, ...settingsPageRoutes.keys};
    expect(registered.length, greaterThan(20), reason: 'the settings table should register every page');

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
