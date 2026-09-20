// Typed go_router routes. Every destination is a GoRouteData class; the tree
// is built from the generated $appRoutes. Navigation uses those classes
// (`const IptvRoute().push(context)`), so path/argument mistakes are compile
// errors. AppRoutes owns the path strings shared with the web router.

import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/features/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/app/bootstrap/app_navigator.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/services/startup/startup_controller.dart';
import 'package:pure_live/features/settings/pages/app_download_page.dart';
import 'package:pure_live/features/settings/pages/app_update_page.dart';
import 'package:pure_live/features/settings/pages/update_history_page.dart';
import 'package:pure_live/features/settings/pages/nav_order_section.dart';
import 'package:pure_live/features/settings/pages/nav_icons_section.dart';
import 'package:pure_live/features/settings/pages/navigation_section.dart';
import 'package:pure_live/features/settings/pages/device_sync_section.dart';
import 'package:pure_live/features/settings/pages/account_cookie_page.dart';
import 'package:pure_live/features/settings/pages/backup_manage_section.dart';
import 'package:pure_live/features/settings/pages/account_bilibili_page.dart';
import 'package:pure_live/features/settings/pages/danmaku_shield_section.dart';
import 'package:pure_live/features/settings/pages/danmaku_user_shield_section.dart';
import 'package:pure_live/features/settings/pages/tag_management_section.dart';
import 'package:pure_live/features/settings/pages/nav_visibility_section.dart';
import 'package:pure_live/features/settings/pages/audience_metric_section.dart';
import 'package:pure_live/features/settings/pages/account_settings_section.dart';
import 'package:pure_live/features/settings/pages/font_family_manager_section.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/features/settings/pages/platform_display_order_section.dart';
import 'package:pure_live/features/settings/pages/platform_display_visibility_section.dart';
import 'package:pure_live/features/iptv/pages/iptv_manage_section.dart';
import 'package:pure_live/features/iptv/pages/iptv_resources_section.dart';
import 'package:pure_live/features/iptv/pages/iptv_import_section.dart';
import 'package:pure_live/features/iptv/pages/iptv_sync_section.dart';
import 'package:pure_live/features/iptv/pages/iptv_headers_section.dart';

part 'app_router.g.dart';

/// Every settings page by full path; the route classes delegate here so each
/// page is declared once. online update/version history build their own
/// scaffold and are standalone routes instead.
final Map<String, WidgetBuilder> settingsPageRoutes = <String, WidgetBuilder>{
  AppRoutes.kSettingsTheme: (context) => const ThemeSettingsSectionPage(),
  AppRoutes.kSettingsThemePicker: (context) => const ThemePickerSectionPage(),
  AppRoutes.kSettingsGridSpacing: (context) => const GridSpacingSectionPage(),
  AppRoutes.kSettingsRefresh: (context) => const RefreshSettingsSectionPage(),
  AppRoutes.kSettingsVideo: (context) => const VideoSettingsSectionPage(),
  AppRoutes.kSettingsPlayerKernel: (context) => const PlayerKernelSettingsSectionPage(),
  AppRoutes.kSettingsProxy: (context) => const ProxySettingsSectionPage(),
  AppRoutes.kSettingsGeneral: (context) => const GeneralSettingsSectionPage(),
  AppRoutes.kSettingsNavigation: (context) => const NavigationSectionPage(),
  AppRoutes.kSettingsNavVisibility: (context) => const NavVisibilitySectionPage(),
  AppRoutes.kSettingsNavOrder: (context) => const NavOrderSectionPage(),
  AppRoutes.kSettingsNavIcons: (context) => const NavIconsSectionPage(),
  AppRoutes.kSettingsPlatform: (context) => const PlatformSettingsSectionPage(),
  AppRoutes.kSettingsCache: (context) => const CacheSettingsSectionPage(),
  AppRoutes.kSettingsConfigPreview: (context) => const LocalConfigPreviewSectionPage(),
  AppRoutes.kSettingsDecoder: (context) => const DecoderSettingsSectionPage(),
  AppRoutes.kSettingsRenderer: (context) => const RendererSettingsSectionPage(),
  AppRoutes.kSettingsAudioOutput: (context) => const AudioOutputSettingsSectionPage(),
  AppRoutes.kSettingsDanmaku: (context) => const DanmakuSettingsSectionPage(),
  AppRoutes.kSettingsFont: (context) => const FontSettingsSectionPage(),
  AppRoutes.kSettingsFontFamily: (context) => const FontFamilyManagerSectionPage(),
  AppRoutes.kSettingsFontFamilyDanmaku: (context) => const FontFamilyManagerSectionPage(danmaku: true),
  AppRoutes.kSettingsPage: (context) => const PageSettingsSectionPage(),
  AppRoutes.kSettingsAudience: (context) => const AudienceMetricSectionPage(),
  AppRoutes.kSettingsLocalBackup: (context) => const BackupManageSectionPage(),
  AppRoutes.kSettingsDeviceSync: (context) => const DeviceSyncSectionPage(),
  AppRoutes.kIptv: (context) => const IptvManageSectionPage(),
  AppRoutes.kIptvResources: (context) => const IptvResourcesSectionPage(),
  AppRoutes.kIptvImport: (context) => const IptvImportSectionPage(),
  AppRoutes.kIptvSync: (context) => const IptvSyncSectionPage(),
  AppRoutes.kIptvHeaders: (context) => const IptvHeadersSectionPage(),
  AppRoutes.kSettingsHotAreas: (context) => const PlatformDisplaySectionPage(),
  AppRoutes.kSettingsHotAreasVisibility: (context) => const PlatformDisplayVisibilitySectionPage(),
  AppRoutes.kSettingsHotAreasOrder: (context) => const PlatformDisplayOrderSectionPage(),
  AppRoutes.kSettingsAccount: (context) => const AccountSettingsSectionPage(),
  AppRoutes.kSettingsAccountBilibili: (context) => const AccountBilibiliPage(),
  AppRoutes.kSettingsAccountHuya: (context) => AccountCookiePage(platform: cookiePlatformFor(AppRoutes.kSettingsAccountHuya)),
  AppRoutes.kSettingsAccountYy: (context) => AccountCookiePage(platform: cookiePlatformFor(AppRoutes.kSettingsAccountYy)),
  AppRoutes.kSettingsAccountDouyin: (context) => AccountCookiePage(platform: cookiePlatformFor(AppRoutes.kSettingsAccountDouyin)),
  AppRoutes.kSettingsAccountKuaishou: (context) => AccountCookiePage(platform: cookiePlatformFor(AppRoutes.kSettingsAccountKuaishou)),
  AppRoutes.kSettingsAccountTwitch: (context) => AccountCookiePage(platform: cookiePlatformFor(AppRoutes.kSettingsAccountTwitch)),
  AppRoutes.kSettingsAccountSoop: (context) => AccountCookiePage(platform: cookiePlatformFor(AppRoutes.kSettingsAccountSoop)),
  AppRoutes.kSettingsTags: (context) => const TagManagementSectionPage(),
  AppRoutes.kBackup: (context) => const BackupSettingsSectionPage(),
  AppRoutes.kSettingsDanmuShield: (context) => const DanmakuShieldSectionPage(),
  AppRoutes.kSettingsDanmuUsers: (context) => const DanmakuUserShieldSectionPage(),
  AppRoutes.kAbout: (context) => const AboutSettingsSectionPage(),
};


/// The same table as typed route instances, keyed by path.
final Map<String, GoRouteData> settingsSectionRoutes = <String, GoRouteData>{
  AppRoutes.kSettingsTheme: const ThemeSettingsRoute(),
  AppRoutes.kSettingsThemePicker: const ThemePickerRoute(),
  AppRoutes.kSettingsGridSpacing: const GridSpacingRoute(),
  AppRoutes.kSettingsRefresh: const RefreshSettingsRoute(),
  AppRoutes.kSettingsVideo: const VideoSettingsRoute(),
  AppRoutes.kSettingsPlayerKernel: const PlayerKernelSettingsRoute(),
  AppRoutes.kSettingsProxy: const ProxySettingsRoute(),
  AppRoutes.kSettingsGeneral: const GeneralSettingsRoute(),
  AppRoutes.kSettingsNavigation: const NavigationSettingsRoute(),
  AppRoutes.kSettingsNavVisibility: const NavVisibilityRoute(),
  AppRoutes.kSettingsNavOrder: const NavOrderRoute(),
  AppRoutes.kSettingsNavIcons: const NavIconsRoute(),
  AppRoutes.kSettingsPlatform: const PlatformSettingsRoute(),
  AppRoutes.kSettingsCache: const CacheSettingsRoute(),
  AppRoutes.kSettingsConfigPreview: const ConfigPreviewRoute(),
  AppRoutes.kSettingsDecoder: const DecoderSettingsRoute(),
  AppRoutes.kSettingsRenderer: const RendererSettingsRoute(),
  AppRoutes.kSettingsAudioOutput: const AudioOutputSettingsRoute(),
  AppRoutes.kSettingsDanmaku: const DanmakuSettingsRoute(),
  AppRoutes.kSettingsFont: const FontSettingsRoute(),
  AppRoutes.kSettingsFontFamily: const FontFamilyRoute(),
  AppRoutes.kSettingsFontFamilyDanmaku: const FontFamilyDanmakuRoute(),
  AppRoutes.kSettingsPage: const PageSettingsRoute(),
  AppRoutes.kSettingsAudience: const AudienceSettingsRoute(),
  AppRoutes.kSettingsLocalBackup: const LocalBackupRoute(),
  AppRoutes.kSettingsDeviceSync: const DeviceSyncRoute(),
  AppRoutes.kIptv: const IptvRoute(),
  AppRoutes.kIptvResources: const IptvResourcesRoute(),
  AppRoutes.kIptvImport: const IptvImportRoute(),
  AppRoutes.kIptvSync: const IptvSyncRoute(),
  AppRoutes.kIptvHeaders: const IptvHeadersRoute(),
  AppRoutes.kSettingsHotAreas: const PlatformDisplayRoute(),
  AppRoutes.kSettingsHotAreasVisibility: const PlatformDisplayVisibilityRoute(),
  AppRoutes.kSettingsHotAreasOrder: const PlatformDisplayOrderRoute(),
  AppRoutes.kSettingsAccount: const AccountSettingsRoute(),
  AppRoutes.kSettingsAccountBilibili: const AccountBilibiliRoute(),
  AppRoutes.kSettingsAccountHuya: const AccountHuyaRoute(),
  AppRoutes.kSettingsAccountYy: const AccountYyRoute(),
  AppRoutes.kSettingsAccountDouyin: const AccountDouyinRoute(),
  AppRoutes.kSettingsAccountKuaishou: const AccountKuaishouRoute(),
  AppRoutes.kSettingsAccountTwitch: const AccountTwitchRoute(),
  AppRoutes.kSettingsAccountSoop: const AccountSoopRoute(),
  AppRoutes.kSettingsTags: const TagsRoute(),
  AppRoutes.kBackup: const BackupRoute(),
  AppRoutes.kSettingsDanmuShield: const DanmuShieldRoute(),
  AppRoutes.kSettingsDanmuUsers: const DanmuUsersRoute(),
  AppRoutes.kAbout: const AboutRoute(),
};

/// The shell's page builder: the table entry for the route the shell is on,
/// inside the shell's scaffold.
///
/// The shell contributes no chrome of its own (see [SettingsShellRoute]); the
/// scaffold draws the page's title bar from the location it is given.
Widget settingsSection(BuildContext context, GoRouterState state) {
  final WidgetBuilder builder = settingsPageRoutes[state.uri.path]!;
  return SettingsSectionScaffold(location: state.uri.path, child: builder(context));
}

/// `kSettingsTheme`.
class ThemeSettingsRoute extends GoRouteData with $ThemeSettingsRoute {
  const ThemeSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsThemePicker`.
class ThemePickerRoute extends GoRouteData with $ThemePickerRoute {
  const ThemePickerRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsGridSpacing`.
class GridSpacingRoute extends GoRouteData with $GridSpacingRoute {
  const GridSpacingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsRefresh`.
class RefreshSettingsRoute extends GoRouteData with $RefreshSettingsRoute {
  const RefreshSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsVideo`.
class VideoSettingsRoute extends GoRouteData with $VideoSettingsRoute {
  const VideoSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsPlayerKernel`.
class PlayerKernelSettingsRoute extends GoRouteData with $PlayerKernelSettingsRoute {
  const PlayerKernelSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsProxy`.
class ProxySettingsRoute extends GoRouteData with $ProxySettingsRoute {
  const ProxySettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsGeneral`.
class GeneralSettingsRoute extends GoRouteData with $GeneralSettingsRoute {
  const GeneralSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsNavigation`.
class NavigationSettingsRoute extends GoRouteData with $NavigationSettingsRoute {
  const NavigationSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsNavVisibility`.
class NavVisibilityRoute extends GoRouteData with $NavVisibilityRoute {
  const NavVisibilityRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsNavOrder`.
class NavOrderRoute extends GoRouteData with $NavOrderRoute {
  const NavOrderRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsNavIcons`.
class NavIconsRoute extends GoRouteData with $NavIconsRoute {
  const NavIconsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsPlatform`.
class PlatformSettingsRoute extends GoRouteData with $PlatformSettingsRoute {
  const PlatformSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsCache`.
class CacheSettingsRoute extends GoRouteData with $CacheSettingsRoute {
  const CacheSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsConfigPreview`.
class ConfigPreviewRoute extends GoRouteData with $ConfigPreviewRoute {
  const ConfigPreviewRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsDecoder`.
class DecoderSettingsRoute extends GoRouteData with $DecoderSettingsRoute {
  const DecoderSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsRenderer`.
class RendererSettingsRoute extends GoRouteData with $RendererSettingsRoute {
  const RendererSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsAudioOutput`.
class AudioOutputSettingsRoute extends GoRouteData with $AudioOutputSettingsRoute {
  const AudioOutputSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsDanmaku`.
class DanmakuSettingsRoute extends GoRouteData with $DanmakuSettingsRoute {
  const DanmakuSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsFont`.
class FontSettingsRoute extends GoRouteData with $FontSettingsRoute {
  const FontSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsFontFamily`.
class FontFamilyRoute extends GoRouteData with $FontFamilyRoute {
  const FontFamilyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsFontFamilyDanmaku`.
class FontFamilyDanmakuRoute extends GoRouteData with $FontFamilyDanmakuRoute {
  const FontFamilyDanmakuRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsPage`.
class PageSettingsRoute extends GoRouteData with $PageSettingsRoute {
  const PageSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsAudience`.
class AudienceSettingsRoute extends GoRouteData with $AudienceSettingsRoute {
  const AudienceSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsLocalBackup`.
class LocalBackupRoute extends GoRouteData with $LocalBackupRoute {
  const LocalBackupRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsDeviceSync`.
class DeviceSyncRoute extends GoRouteData with $DeviceSyncRoute {
  const DeviceSyncRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kIptv`.
class IptvRoute extends GoRouteData with $IptvRoute {
  const IptvRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kIptvResources`.
class IptvResourcesRoute extends GoRouteData with $IptvResourcesRoute {
  const IptvResourcesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kIptvImport`.
class IptvImportRoute extends GoRouteData with $IptvImportRoute {
  const IptvImportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kIptvSync`.
class IptvSyncRoute extends GoRouteData with $IptvSyncRoute {
  const IptvSyncRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kIptvHeaders`.
class IptvHeadersRoute extends GoRouteData with $IptvHeadersRoute {
  const IptvHeadersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsHotAreas`.
class PlatformDisplayRoute extends GoRouteData with $PlatformDisplayRoute {
  const PlatformDisplayRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsHotAreasVisibility`.
class PlatformDisplayVisibilityRoute extends GoRouteData with $PlatformDisplayVisibilityRoute {
  const PlatformDisplayVisibilityRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsHotAreasOrder`.
class PlatformDisplayOrderRoute extends GoRouteData with $PlatformDisplayOrderRoute {
  const PlatformDisplayOrderRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsAccount`.
class AccountSettingsRoute extends GoRouteData with $AccountSettingsRoute {
  const AccountSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsAccountBilibili`.
class AccountBilibiliRoute extends GoRouteData with $AccountBilibiliRoute {
  const AccountBilibiliRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsAccountHuya`.
class AccountHuyaRoute extends GoRouteData with $AccountHuyaRoute {
  const AccountHuyaRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsAccountYy`.
class AccountYyRoute extends GoRouteData with $AccountYyRoute {
  const AccountYyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsAccountDouyin`.
class AccountDouyinRoute extends GoRouteData with $AccountDouyinRoute {
  const AccountDouyinRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsAccountKuaishou`.
class AccountKuaishouRoute extends GoRouteData with $AccountKuaishouRoute {
  const AccountKuaishouRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsAccountTwitch`.
class AccountTwitchRoute extends GoRouteData with $AccountTwitchRoute {
  const AccountTwitchRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsAccountSoop`.
class AccountSoopRoute extends GoRouteData with $AccountSoopRoute {
  const AccountSoopRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsTags`.
class TagsRoute extends GoRouteData with $TagsRoute {
  const TagsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kBackup`.
class BackupRoute extends GoRouteData with $BackupRoute {
  const BackupRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsDanmuShield`.
class DanmuShieldRoute extends GoRouteData with $DanmuShieldRoute {
  const DanmuShieldRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kSettingsDanmuUsers`.
class DanmuUsersRoute extends GoRouteData with $DanmuUsersRoute {
  const DanmuUsersRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// `kAbout`.
class AboutRoute extends GoRouteData with $AboutRoute {
  const AboutRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => settingsSection(context, state);
}

/// The settings shell: ONE shell for every settings page, and it contributes
/// **no chrome** — each page brings its own scaffold (its own app bar, its own
/// back button and its own focus wiring), which is what keeps the bar and the
/// highlight belonging to the page the user is looking at.
///
/// The shell used to hold one `TvScaffold` for all of them, so the app bar — and
/// the back button with it — belonged to the shell instead of to the page: an
/// inner push fired no route callback for that scaffold, its back button
/// survived every page change, and the highlight kept ending up on a screen the
/// user was not looking at.
@TypedShellRoute<SettingsShellRoute>(
  routes: <TypedRoute<RouteData>>[
    TypedGoRoute<ThemeSettingsRoute>(path: AppRoutes.kSettingsTheme),
    TypedGoRoute<ThemePickerRoute>(path: AppRoutes.kSettingsThemePicker),
    TypedGoRoute<GridSpacingRoute>(path: AppRoutes.kSettingsGridSpacing),
    TypedGoRoute<RefreshSettingsRoute>(path: AppRoutes.kSettingsRefresh),
    TypedGoRoute<VideoSettingsRoute>(path: AppRoutes.kSettingsVideo),
    TypedGoRoute<PlayerKernelSettingsRoute>(path: AppRoutes.kSettingsPlayerKernel),
    TypedGoRoute<ProxySettingsRoute>(path: AppRoutes.kSettingsProxy),
    TypedGoRoute<GeneralSettingsRoute>(path: AppRoutes.kSettingsGeneral),
    TypedGoRoute<NavigationSettingsRoute>(path: AppRoutes.kSettingsNavigation),
    TypedGoRoute<NavVisibilityRoute>(path: AppRoutes.kSettingsNavVisibility),
    TypedGoRoute<NavOrderRoute>(path: AppRoutes.kSettingsNavOrder),
    TypedGoRoute<NavIconsRoute>(path: AppRoutes.kSettingsNavIcons),
    TypedGoRoute<PlatformSettingsRoute>(path: AppRoutes.kSettingsPlatform),
    TypedGoRoute<CacheSettingsRoute>(path: AppRoutes.kSettingsCache),
    TypedGoRoute<ConfigPreviewRoute>(path: AppRoutes.kSettingsConfigPreview),
    TypedGoRoute<DecoderSettingsRoute>(path: AppRoutes.kSettingsDecoder),
    TypedGoRoute<RendererSettingsRoute>(path: AppRoutes.kSettingsRenderer),
    TypedGoRoute<AudioOutputSettingsRoute>(path: AppRoutes.kSettingsAudioOutput),
    TypedGoRoute<DanmakuSettingsRoute>(path: AppRoutes.kSettingsDanmaku),
    TypedGoRoute<FontSettingsRoute>(path: AppRoutes.kSettingsFont),
    TypedGoRoute<FontFamilyRoute>(path: AppRoutes.kSettingsFontFamily),
    TypedGoRoute<FontFamilyDanmakuRoute>(path: AppRoutes.kSettingsFontFamilyDanmaku),
    TypedGoRoute<PageSettingsRoute>(path: AppRoutes.kSettingsPage),
    TypedGoRoute<AudienceSettingsRoute>(path: AppRoutes.kSettingsAudience),
    TypedGoRoute<LocalBackupRoute>(path: AppRoutes.kSettingsLocalBackup),
    TypedGoRoute<DeviceSyncRoute>(path: AppRoutes.kSettingsDeviceSync),
    TypedGoRoute<IptvRoute>(path: AppRoutes.kIptv),
    TypedGoRoute<IptvResourcesRoute>(path: AppRoutes.kIptvResources),
    TypedGoRoute<IptvImportRoute>(path: AppRoutes.kIptvImport),
    TypedGoRoute<IptvSyncRoute>(path: AppRoutes.kIptvSync),
    TypedGoRoute<IptvHeadersRoute>(path: AppRoutes.kIptvHeaders),
    TypedGoRoute<PlatformDisplayRoute>(path: AppRoutes.kSettingsHotAreas),
    TypedGoRoute<PlatformDisplayVisibilityRoute>(path: AppRoutes.kSettingsHotAreasVisibility),
    TypedGoRoute<PlatformDisplayOrderRoute>(path: AppRoutes.kSettingsHotAreasOrder),
    TypedGoRoute<AccountSettingsRoute>(path: AppRoutes.kSettingsAccount),
    TypedGoRoute<AccountBilibiliRoute>(path: AppRoutes.kSettingsAccountBilibili),
    TypedGoRoute<AccountHuyaRoute>(path: AppRoutes.kSettingsAccountHuya),
    TypedGoRoute<AccountYyRoute>(path: AppRoutes.kSettingsAccountYy),
    TypedGoRoute<AccountDouyinRoute>(path: AppRoutes.kSettingsAccountDouyin),
    TypedGoRoute<AccountKuaishouRoute>(path: AppRoutes.kSettingsAccountKuaishou),
    TypedGoRoute<AccountTwitchRoute>(path: AppRoutes.kSettingsAccountTwitch),
    TypedGoRoute<AccountSoopRoute>(path: AppRoutes.kSettingsAccountSoop),
    TypedGoRoute<TagsRoute>(path: AppRoutes.kSettingsTags),
    TypedGoRoute<BackupRoute>(path: AppRoutes.kBackup),
    TypedGoRoute<DanmuShieldRoute>(path: AppRoutes.kSettingsDanmuShield),
    TypedGoRoute<DanmuUsersRoute>(path: AppRoutes.kSettingsDanmuUsers),
    TypedGoRoute<AboutRoute>(path: AppRoutes.kAbout),
  ],
)
class SettingsShellRoute extends ShellRouteData {
  const SettingsShellRoute();

  @override
  Widget builder(BuildContext context, GoRouterState state, Widget navigator) => navigator;
}

// --------------------------------------------------------------- home & menu

/// The home shell: side menu plus the tab the user picked.
@TypedGoRoute<HomeRoute>(path: AppRoutes.kInitial)
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

@TypedGoRoute<AgreementPageRoute>(path: AppRoutes.kAgreementPage)
class AgreementPageRoute extends GoRouteData with $AgreementPageRoute {
  const AgreementPageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const AgreementPage();
}

/// `/settings` — the menu itself, not a section.
@TypedGoRoute<SettingsMenuRoute>(path: AppRoutes.kSettings)
class SettingsMenuRoute extends GoRouteData with $SettingsMenuRoute {
  const SettingsMenuRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const TvSettingsRoutePage();
}

// ------------------------------------------------------ pickers, with `extra`

/// The icon picker owns a grid, so it is a route of its own instead of a
/// section inside the scrolling settings shell. The row that opens it passes the
/// icon it currently shows as `extra` and receives the choice as the pop result.
@TypedGoRoute<SettingsIconPickerRoute>(path: AppRoutes.kSettingsIconPicker)
class SettingsIconPickerRoute extends GoRouteData with $SettingsIconPickerRoute {
  SettingsIconPickerRoute([this.$extra]);

  final String? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) => IconPickerSectionPage(currentLabel: $extra);
}

/// The loading-animation picker (a grid of live previews) owns its scroll axis,
/// so it is a route of its own rather than a section in the shell.
@TypedGoRoute<SettingsLoadingStyleRoute>(path: AppRoutes.kSettingsLoadingStyle)
class SettingsLoadingStyleRoute extends GoRouteData with $SettingsLoadingStyleRoute {
  const SettingsLoadingStyleRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LoadingStyleSectionPage();
}

/// The colour picker, opened with the colour in force as `extra`.
@TypedGoRoute<SettingsColorPickerRoute>(path: AppRoutes.kSettingsColorPicker)
class SettingsColorPickerRoute extends GoRouteData with $SettingsColorPickerRoute {
  SettingsColorPickerRoute([this.$extra]);

  final Color? $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) => ColorPickerSectionPage(current: $extra);
}

// ------------------------------------------------- self-scaffolding settings

/// online update — it owns its app bar (with the check action), its scroll view and
/// its focus wiring, so it stays out of the settings shell.
@TypedGoRoute<AppUpdateRoute>(path: AppRoutes.kAppUpdate)
class AppUpdateRoute extends GoRouteData with $AppUpdateRoute {
  const AppUpdateRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const AppUpdatePage();
}

/// The download page behind 在线更新's 当前版本 row: per-ABI download sources
/// and the release notes as markdown. Owns its scaffold like [AppUpdateRoute].
@TypedGoRoute<AppDownloadRoute>(path: AppRoutes.kAppDownload)
class AppDownloadRoute extends GoRouteData with $AppDownloadRoute {
  const AppDownloadRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const AppDownloadPage();
}

@TypedGoRoute<UpdateHistoryRoute>(path: AppRoutes.kUpdateHistory)
class UpdateHistoryRoute extends GoRouteData with $UpdateHistoryRoute {
  const UpdateHistoryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const UpdateHistoryPage();
}

// ------------------------------------------------------------------ browsing

@TypedGoRoute<AreaRoomsRoute>(path: AppRoutes.kAreaRooms)
class AreaRoomsRoute extends GoRouteData with $AreaRoomsRoute {
  AreaRoomsRoute(this.$extra);

  final AreaRoomsArgs $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      AreaRoomsPage(site: $extra.site, subCategory: $extra.subCategory);
}

@TypedGoRoute<SearchResultRoute>(path: AppRoutes.kSearchResult)
class SearchResultRoute extends GoRouteData with $SearchResultRoute {
  SearchResultRoute(this.$extra);

  final SearchResultArgs $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      TvSearchResultPage(keyword: $extra.keyword, site: $extra.site, searchType: $extra.searchType);
}

// ------------------------------------------------------------------ wallpaper

@TypedGoRoute<WallpaperPageRoute>(path: AppRoutes.kWallpaperPage)
class WallpaperPageRoute extends GoRouteData with $WallpaperPageRoute {
  const WallpaperPageRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const WallpaperPage();
}

@TypedGoRoute<WallpaperLibraryRoute>(path: AppRoutes.kWallpaperLibrary)
class WallpaperLibraryRoute extends GoRouteData with $WallpaperLibraryRoute {
  const WallpaperLibraryRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const WallpaperLibraryPage();
}

@TypedGoRoute<WallpaperApiRoute>(path: AppRoutes.kWallpaperApi)
class WallpaperApiRoute extends GoRouteData with $WallpaperApiRoute {
  const WallpaperApiRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const WallpaperApiPage();
}

@TypedGoRoute<WallpaperApiGroupRoute>(path: AppRoutes.kWallpaperApiGroup)
class WallpaperApiGroupRoute extends GoRouteData with $WallpaperApiGroupRoute {
  WallpaperApiGroupRoute(this.$extra);

  final WallpaperApiGroup $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) => WallpaperApiGroupPage(group: $extra);
}

@TypedGoRoute<WallpaperGalleryRoute>(path: AppRoutes.kWallpaperGallery)
class WallpaperGalleryRoute extends GoRouteData with $WallpaperGalleryRoute {
  WallpaperGalleryRoute(this.$extra);

  final BackgroundSource $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) => WallpaperGalleryPage(source: $extra);
}

@TypedGoRoute<WallpaperItemsRoute>(path: AppRoutes.kWallpaperItems)
class WallpaperItemsRoute extends GoRouteData with $WallpaperItemsRoute {
  WallpaperItemsRoute(this.$extra);

  final WallpaperItemsArgs $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      WallpaperItemsPage(sourceId: $extra.sourceId, categoryId: $extra.categoryId);
}

@TypedGoRoute<WallpaperPreviewRoute>(path: AppRoutes.kWallpaperPreview)
class WallpaperPreviewRoute extends GoRouteData with $WallpaperPreviewRoute {
  WallpaperPreviewRoute(this.$extra);

  final WallpaperPreviewArgs $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) => WallpaperPreviewPage(args: $extra);
}

// ------------------------------------------------------------------ playback

/// Playback accepts either a resolved room (the normal push) or ready-made
/// [LivePlayArgs] (channel switching inside the player).
@TypedGoRoute<LivePlayRoute>(path: AppRoutes.kLivePlay)
class LivePlayRoute extends GoRouteData with $LivePlayRoute {
  LivePlayRoute(this.$extra);

  /// Non-nullable on purpose: every caller passes a room or ready-made args, and
  /// `state.extra as Object?` is the no-op cast the analyzer flags in the
  /// generated file.
  final Object $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final Object extra = $extra;
    final LivePlayArgs args = extra is LiveRoom
        ? LivePlayArgs.fromRoom(extra)
        : (extra is LivePlayArgs ? extra : const LivePlayArgs(platform: '', roomId: ''));
    return LivePlayPage(args: args);
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final isFirstInApp = ref.watch(startupControllerProvider);

  return GoRouter(
    navigatorKey: appNavigatorKey,
    // Lets every page know when it is covered and uncovered again, so focus can
    // return to the item the user acted on after a pop.
    observers: [tvRouteObserver],
    initialLocation: AppRoutes.kInitial,
    redirect: (context, state) {
      final location = state.uri.path;

      if (isFirstInApp && location != AppRoutes.kAgreementPage) {
        return AppRoutes.kAgreementPage;
      }

      if (!isFirstInApp && location == AppRoutes.kAgreementPage) {
        return AppRoutes.kInitial;
      }

      return null;
    },
    routes: $appRoutes,
  );
});
