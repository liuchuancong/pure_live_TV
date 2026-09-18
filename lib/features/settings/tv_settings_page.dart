import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/app_update/app_update_service.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/app/router/app_router.dart';

/// One settings destination: its route, translation keys and icon.
typedef SettingsEntry = ({String path, String titleKey, String? subtitleKey, IconData icon});

/// A titled group of entries — the "big group, small rows" layout.
typedef SettingsGroup = ({String titleKey, List<SettingsEntry> entries});

/// The settings menu.
///
/// Groups, rows, order, labels and icons follow the desktop settings menu
/// (`pure_live/lib/modules/settings/settings_page.dart`). Pages that the
/// desktop app hosts inside one of these pages are not rows here; they are
/// reached from their parent page, exactly as there.
final List<SettingsGroup> settingsCatalog = <SettingsGroup>[
  (
    titleKey: 'theme_settings',
    entries: <SettingsEntry>[
      (
        path: AppRoutes.kSettingsTheme,
        titleKey: 'theme_customization',
        subtitleKey: 'theme_customization_desc',
        icon: Remix.palette_line,
      ),
    ],
  ),
  (
    titleKey: 'iptv_settings',
    entries: <SettingsEntry>[
      (path: AppRoutes.kIptv, titleKey: 'iptv_settings', subtitleKey: 'manage_iptv_sources', icon: Remix.tv_line),
    ],
  ),
  (
    titleKey: 'refresh_settings',
    entries: <SettingsEntry>[
      (
        path: AppRoutes.kSettingsRefresh,
        titleKey: 'refresh_settings',
        subtitleKey: 'refresh_settings_subtitle',
        icon: Remix.refresh_line,
      ),
    ],
  ),
  (
    titleKey: 'video_settings',
    entries: <SettingsEntry>[
      (path: AppRoutes.kSettingsVideo, titleKey: 'video', subtitleKey: 'video_desc', icon: Remix.film_line),
    ],
  ),
  (
    titleKey: 'player_kernel_settings',
    entries: <SettingsEntry>[
      (
        path: AppRoutes.kSettingsPlayerKernel,
        titleKey: 'player_kernel',
        subtitleKey: 'player_kernel_desc',
        icon: Remix.cpu_line,
      ),
    ],
  ),
  (
    titleKey: 'network_proxy_settings',
    entries: <SettingsEntry>[
      (
        path: AppRoutes.kSettingsProxy,
        titleKey: 'custom_network_proxy',
        subtitleKey: 'custom_network_proxy_desc',
        icon: Remix.global_line,
      ),
    ],
  ),
  (
    titleKey: 'general_settings',
    entries: <SettingsEntry>[
      (path: AppRoutes.kSettingsGeneral, titleKey: 'general', subtitleKey: 'general_desc', icon: Remix.settings_4_line),
      (
        path: AppRoutes.kSettingsNavigation,
        titleKey: 'navigation_display_settings',
        subtitleKey: 'navigation_display_settings_desc',
        icon: Remix.menu_line,
      ),
      (
        path: AppRoutes.kSettingsPlatform,
        titleKey: 'platform_settings',
        subtitleKey: 'platform_settings_desc',
        icon: Remix.apps_2_line,
      ),
    ],
  ),
  (
    titleKey: 'data_manage',
    entries: <SettingsEntry>[
      (
        path: AppRoutes.kSettingsCache,
        titleKey: 'cache_and_data',
        subtitleKey: 'cache_and_data_desc',
        icon: Remix.database_2_line,
      ),
    ],
  ),
  (
    titleKey: 'backup_manage',
    entries: <SettingsEntry>[
      (path: AppRoutes.kBackup, titleKey: 'backup_recover', subtitleKey: 'backup_recover_desc', icon: Remix.cloud_line),
    ],
  ),
  // The desktop app reaches 关于 from its overflow menu; this app has no such
  // menu, so the row stays here to keep the page reachable.
  (
    titleKey: 'about',
    entries: <SettingsEntry>[
      (
        path: AppRoutes.kAbout,
        titleKey: 'ui_pure_live_tv',
        subtitleKey: 'check_update',
        icon: Icons.info_outline_rounded,
      ),
    ],
  ),
];

/// Catalog entry owning [location], or null when nothing matches.
///
/// Matches whole path segments so `/settings/fonts` cannot be attributed to
/// the `/settings/font` entry.
SettingsEntry? settingsEntryForLocation(String location) {
  for (final SettingsGroup group in settingsCatalog) {
    for (final SettingsEntry entry in group.entries) {
      if (location == entry.path || location.startsWith('${entry.path}/')) {
        return entry;
      }
    }
  }
  return null;
}

/// Grouped settings list: a heading per group, focusable rows inside a card.
class SettingsCatalogView extends ConsumerWidget {
  const SettingsCatalogView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The 关于 row trades its static subtitle for the 发现新版本 hint while an
    // update is pending — the menu is the first screen a user looking for "what
    // changed" lands on.
    final updateState = ref.watch(appUpdateControllerProvider);
    final bool hasUpdate = updateState.phase == AppUpdatePhase.available && updateState.latestVersion.isNotEmpty;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
      children: [
        for (final SettingsGroup group in settingsCatalog) ...[
          TvSettingsGroupTitle(title: i18n(group.titleKey)),
          TvSettingsCard(
            children: [
              for (final SettingsEntry entry in group.entries)
                TvSettingsNavTile(
                  title: i18n(entry.titleKey),
                  subtitle: hasUpdate && entry.path == AppRoutes.kAbout
                      ? '${i18n('new_version_found')} v${updateState.latestVersion}'
                      : (entry.subtitleKey == null ? null : i18n(entry.subtitleKey!)),
                  icon: entry.icon,
                  trailing: hasUpdate && entry.path == AppRoutes.kAbout
                      ? Text(
                          i18n('new_version_found'),
                          style: TextStyle(fontSize: 13.sp, color: context.tvTheme.focusColor),
                        )
                      : null,
                  onTap: () => settingsSectionRoutes[entry.path]?.push(context),
                ),
            ],
          ),
          SizedBox(height: 20.sp),
        ],
        SizedBox(height: 24.sp),
      ],
    );
  }
}

/// Titles for the pages that are reached from inside a parent page (or from
/// the desktop app's own routes) and therefore are not menu rows.
const Map<String, String> settingsSectionTitleKeys = <String, String>{
  AppRoutes.kIptvResources: 'iptv_resource_list',
  AppRoutes.kIptvImport: 'iptv_import_source',
  AppRoutes.kIptvSync: 'auto_sync_settings',
  AppRoutes.kIptvHeaders: 'iptv_headers_settings',
  AppRoutes.kSettingsThemePicker: 'ui_theme',
  AppRoutes.kSettingsLoadingStyle: 'change_loading_style',
  AppRoutes.kSettingsColorPicker: 'ui_choose_color',
  AppRoutes.kSettingsIconPicker: 'ui_choose_icon',
  AppRoutes.kSettingsPage: 'page_settings',
  AppRoutes.kSettingsFont: 'font_settings_title',
  AppRoutes.kSettingsFontFamily: 'font_family_settings',
  // The danmaku-only font manager is the same page in its danmaku scope; without
  // its own entry it falls back to the generic 系统设置 title.
  AppRoutes.kSettingsFontFamilyDanmaku: 'font_family_settings',
  // The page's own title (`online_update`), or the shell would call it 系统设置.
  AppRoutes.kAppUpdate: 'online_update',
  AppRoutes.kUpdateHistory: 'version_history',
  AppRoutes.kSettingsDecoder: 'hardware_decoder',
  AppRoutes.kSettingsRenderer: 'video_output_driver',
  AppRoutes.kSettingsAudioOutput: 'audio_output_driver',
  AppRoutes.kSettingsDanmaku: 'danmaku_settings',
  AppRoutes.kSettingsAudience: 'audience_metric_settings',
  AppRoutes.kSettingsLocalBackup: 'local_backup',
  AppRoutes.kSettingsDeviceSync: 'remote_sync_receive',
  AppRoutes.kSettingsConfigPreview: 'config_preview',
  AppRoutes.kSettingsDanmuShield: 'danmaku_keyword_block',
  AppRoutes.kSettingsHotAreas: 'platform_display',
  AppRoutes.kSettingsAccount: 'third_party_auth',
  AppRoutes.kSettingsAccountBilibili: 'site_bilibili',
  AppRoutes.kSettingsAccountHuya: 'site_huya',
  AppRoutes.kSettingsAccountYy: 'site_yy',
  AppRoutes.kSettingsAccountDouyin: 'site_douyin',
  AppRoutes.kSettingsAccountKuaishou: 'site_kuaishou',
  AppRoutes.kSettingsAccountTwitch: 'site_twitch',
  AppRoutes.kSettingsAccountSoop: 'site_soop',
  AppRoutes.kSettingsTags: 'tag_management',
  // The three 导航与显示设置 sub-pages are titled like the rows that open them.
  AppRoutes.kSettingsNavVisibility: 'navigation_visibility',
  AppRoutes.kSettingsNavOrder: 'navigation_order',
  AppRoutes.kSettingsNavIcons: 'navigation_icons',
  // Same for the two 平台显示 sub-pages.
  AppRoutes.kSettingsHotAreasVisibility: 'platform_display_visibility',
  AppRoutes.kSettingsHotAreasOrder: 'platform_display_order',
  // Pages whose *menu row* has a different label from their page title.
  //
  // The mobile app's menu says 视频 / 播放器内核 / 自定义网络代理 while the pages
  // themselves are titled 视频设置 / 播放内核设置 / 网络与代理设置; taking the
  // title from the menu row made the TV app bars disagree with the phone's.
  AppRoutes.kSettingsVideo: 'video_settings',
  AppRoutes.kSettingsPlayerKernel: 'player_kernel_settings',
  AppRoutes.kSettingsProxy: 'network_proxy_settings',
};

/// Page title for a settings location.
///
/// The sub-page table wins over the menu row (a page may be titled differently
/// from the row that opens it), and the *longest* matching prefix wins so a
/// platform page under `/settings_account/` gets its own name instead of the
/// parent's.
String settingsSectionTitleKey(String location) {
  String? bestPath;
  String? bestTitle;
  for (final MapEntry<String, String> candidate in settingsSectionTitleKeys.entries) {
    if (location != candidate.key && !location.startsWith('${candidate.key}/')) continue;
    if (bestPath == null || candidate.key.length > bestPath.length) {
      bestPath = candidate.key;
      bestTitle = candidate.value;
    }
  }
  if (bestTitle != null) return bestTitle;

  final SettingsEntry? entry = settingsEntryForLocation(location);
  if (entry != null) return entry.titleKey;
  return 'ui_settings';
}

/// `/settings` — the menu as a full page, with the desktop app's
/// configuration-preview action in the app bar.
class TvSettingsRoutePage extends StatelessWidget {
  const TvSettingsRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    // The bar belongs to the page's chrome, not to its list: inside the list it would
    // scroll away, and `TvAppBar` draws a 返回 of its own — two back buttons under the
    // one `TvPageScaffold` also builds. Passing the title keeps `TvPageScaffold` in
    // charge of the bar and of the focus node that makes 返回 selectable.
    return TvPageScaffold(
      title: i18n('settings_title'),
      child: const SettingsCatalogView(),
    );
  }
}

/// Wraps one settings section route with a title, a back button and scrolling.
///
/// Sections are pushed as their own page, so they are full-screen rather than
/// content sitting next to a module column the d-pad could not leave.
class SettingsSectionScaffold extends StatelessWidget {
  const SettingsSectionScaffold({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return TvPageScaffold(
      title: i18n(settingsSectionTitleKey(location)),
      // Each settings page carries its own scaffold — its own app bar, its own 返回
      // button and its own focus wiring — inside its own route of the shell's nested
      // navigator. The shell deliberately contributes no chrome (see the route
      // table): a scaffold shared by every page never saw an inner push, so its 返回
      // button outlived the page it belonged to and stole the highlight.
      child: SingleChildScrollView(padding: EdgeInsets.all(16.sp), child: child),
    );
  }
}
