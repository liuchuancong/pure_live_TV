// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $settingsShellRoute,
  $homeRoute,
  $agreementPageRoute,
  $settingsMenuRoute,
  $settingsIconPickerRoute,
  $settingsLoadingStyleRoute,
  $settingsColorPickerRoute,
  $appUpdateRoute,
  $appDownloadRoute,
  $updateHistoryRoute,
  $areaRoomsRoute,
  $searchResultRoute,
  $wallpaperPageRoute,
  $wallpaperLibraryRoute,
  $wallpaperApiRoute,
  $wallpaperApiGroupRoute,
  $wallpaperGalleryRoute,
  $wallpaperItemsRoute,
  $wallpaperPreviewRoute,
  $livePlayRoute,
];

RouteBase get $settingsShellRoute => ShellRouteData.$route(
  factory: $SettingsShellRouteExtension._fromState,
  routes: [
    GoRouteData.$route(
      path: '/settings/theme',
      hasOverriddenOnExit: false,
      factory: $ThemeSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/theme_picker',
      hasOverriddenOnExit: false,
      factory: $ThemePickerRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/grid_spacing',
      hasOverriddenOnExit: false,
      factory: $GridSpacingRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/refresh',
      hasOverriddenOnExit: false,
      factory: $RefreshSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/video',
      hasOverriddenOnExit: false,
      factory: $VideoSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/player_kernel',
      hasOverriddenOnExit: false,
      factory: $PlayerKernelSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/proxy',
      hasOverriddenOnExit: false,
      factory: $ProxySettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/general',
      hasOverriddenOnExit: false,
      factory: $GeneralSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/navigation',
      hasOverriddenOnExit: false,
      factory: $NavigationSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/nav_visibility',
      hasOverriddenOnExit: false,
      factory: $NavVisibilityRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/nav_order',
      hasOverriddenOnExit: false,
      factory: $NavOrderRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/nav_icons',
      hasOverriddenOnExit: false,
      factory: $NavIconsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/platform',
      hasOverriddenOnExit: false,
      factory: $PlatformSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/cache',
      hasOverriddenOnExit: false,
      factory: $CacheSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/config_preview',
      hasOverriddenOnExit: false,
      factory: $ConfigPreviewRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/decoder',
      hasOverriddenOnExit: false,
      factory: $DecoderSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/renderer',
      hasOverriddenOnExit: false,
      factory: $RendererSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/audio_output',
      hasOverriddenOnExit: false,
      factory: $AudioOutputSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/danmaku',
      hasOverriddenOnExit: false,
      factory: $DanmakuSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/font',
      hasOverriddenOnExit: false,
      factory: $FontSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/fonts',
      hasOverriddenOnExit: false,
      factory: $FontFamilyRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settingsFontFamilyDanmaku',
      hasOverriddenOnExit: false,
      factory: $FontFamilyDanmakuRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/page',
      hasOverriddenOnExit: false,
      factory: $PageSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/audience',
      hasOverriddenOnExit: false,
      factory: $AudienceSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/backups',
      hasOverriddenOnExit: false,
      factory: $LocalBackupRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings/device_sync',
      hasOverriddenOnExit: false,
      factory: $DeviceSyncRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/iptv',
      hasOverriddenOnExit: false,
      factory: $IptvRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/iptv/resources',
      hasOverriddenOnExit: false,
      factory: $IptvResourcesRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/iptv/import',
      hasOverriddenOnExit: false,
      factory: $IptvImportRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/iptv/sync',
      hasOverriddenOnExit: false,
      factory: $IptvSyncRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/iptv/headers',
      hasOverriddenOnExit: false,
      factory: $IptvHeadersRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/hot_areas',
      hasOverriddenOnExit: false,
      factory: $PlatformDisplayRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/hot_areas/visibility',
      hasOverriddenOnExit: false,
      factory: $PlatformDisplayVisibilityRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/hot_areas/order',
      hasOverriddenOnExit: false,
      factory: $PlatformDisplayOrderRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings_account',
      hasOverriddenOnExit: false,
      factory: $AccountSettingsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings_account/bilibili',
      hasOverriddenOnExit: false,
      factory: $AccountBilibiliRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings_account/huya',
      hasOverriddenOnExit: false,
      factory: $AccountHuyaRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings_account/yy',
      hasOverriddenOnExit: false,
      factory: $AccountYyRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings_account/douyin',
      hasOverriddenOnExit: false,
      factory: $AccountDouyinRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings_account/kuaishou',
      hasOverriddenOnExit: false,
      factory: $AccountKuaishouRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings_account/twitch',
      hasOverriddenOnExit: false,
      factory: $AccountTwitchRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settings_account/soop',
      hasOverriddenOnExit: false,
      factory: $AccountSoopRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/settingTags',
      hasOverriddenOnExit: false,
      factory: $TagsRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/backup',
      hasOverriddenOnExit: false,
      factory: $BackupRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/shield',
      hasOverriddenOnExit: false,
      factory: $DanmuShieldRoute._fromState,
    ),
    GoRouteData.$route(
      path: '/about',
      hasOverriddenOnExit: false,
      factory: $AboutRoute._fromState,
    ),
  ],
);

extension $SettingsShellRouteExtension on SettingsShellRoute {
  static SettingsShellRoute _fromState(GoRouterState state) =>
      const SettingsShellRoute();
}

mixin $ThemeSettingsRoute on GoRouteData {
  static ThemeSettingsRoute _fromState(GoRouterState state) =>
      const ThemeSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/theme');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ThemePickerRoute on GoRouteData {
  static ThemePickerRoute _fromState(GoRouterState state) =>
      const ThemePickerRoute();

  @override
  String get location => GoRouteData.$location('/settings/theme_picker');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $GridSpacingRoute on GoRouteData {
  static GridSpacingRoute _fromState(GoRouterState state) =>
      const GridSpacingRoute();

  @override
  String get location => GoRouteData.$location('/settings/grid_spacing');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RefreshSettingsRoute on GoRouteData {
  static RefreshSettingsRoute _fromState(GoRouterState state) =>
      const RefreshSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/refresh');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $VideoSettingsRoute on GoRouteData {
  static VideoSettingsRoute _fromState(GoRouterState state) =>
      const VideoSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/video');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PlayerKernelSettingsRoute on GoRouteData {
  static PlayerKernelSettingsRoute _fromState(GoRouterState state) =>
      const PlayerKernelSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/player_kernel');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ProxySettingsRoute on GoRouteData {
  static ProxySettingsRoute _fromState(GoRouterState state) =>
      const ProxySettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/proxy');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $GeneralSettingsRoute on GoRouteData {
  static GeneralSettingsRoute _fromState(GoRouterState state) =>
      const GeneralSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/general');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NavigationSettingsRoute on GoRouteData {
  static NavigationSettingsRoute _fromState(GoRouterState state) =>
      const NavigationSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/navigation');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NavVisibilityRoute on GoRouteData {
  static NavVisibilityRoute _fromState(GoRouterState state) =>
      const NavVisibilityRoute();

  @override
  String get location => GoRouteData.$location('/settings/nav_visibility');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NavOrderRoute on GoRouteData {
  static NavOrderRoute _fromState(GoRouterState state) => const NavOrderRoute();

  @override
  String get location => GoRouteData.$location('/settings/nav_order');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $NavIconsRoute on GoRouteData {
  static NavIconsRoute _fromState(GoRouterState state) => const NavIconsRoute();

  @override
  String get location => GoRouteData.$location('/settings/nav_icons');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PlatformSettingsRoute on GoRouteData {
  static PlatformSettingsRoute _fromState(GoRouterState state) =>
      const PlatformSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/platform');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CacheSettingsRoute on GoRouteData {
  static CacheSettingsRoute _fromState(GoRouterState state) =>
      const CacheSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/cache');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $ConfigPreviewRoute on GoRouteData {
  static ConfigPreviewRoute _fromState(GoRouterState state) =>
      const ConfigPreviewRoute();

  @override
  String get location => GoRouteData.$location('/settings/config_preview');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DecoderSettingsRoute on GoRouteData {
  static DecoderSettingsRoute _fromState(GoRouterState state) =>
      const DecoderSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/decoder');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $RendererSettingsRoute on GoRouteData {
  static RendererSettingsRoute _fromState(GoRouterState state) =>
      const RendererSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/renderer');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AudioOutputSettingsRoute on GoRouteData {
  static AudioOutputSettingsRoute _fromState(GoRouterState state) =>
      const AudioOutputSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/audio_output');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DanmakuSettingsRoute on GoRouteData {
  static DanmakuSettingsRoute _fromState(GoRouterState state) =>
      const DanmakuSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/danmaku');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FontSettingsRoute on GoRouteData {
  static FontSettingsRoute _fromState(GoRouterState state) =>
      const FontSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/font');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FontFamilyRoute on GoRouteData {
  static FontFamilyRoute _fromState(GoRouterState state) =>
      const FontFamilyRoute();

  @override
  String get location => GoRouteData.$location('/settings/fonts');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $FontFamilyDanmakuRoute on GoRouteData {
  static FontFamilyDanmakuRoute _fromState(GoRouterState state) =>
      const FontFamilyDanmakuRoute();

  @override
  String get location => GoRouteData.$location('/settingsFontFamilyDanmaku');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PageSettingsRoute on GoRouteData {
  static PageSettingsRoute _fromState(GoRouterState state) =>
      const PageSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/page');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AudienceSettingsRoute on GoRouteData {
  static AudienceSettingsRoute _fromState(GoRouterState state) =>
      const AudienceSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings/audience');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $LocalBackupRoute on GoRouteData {
  static LocalBackupRoute _fromState(GoRouterState state) =>
      const LocalBackupRoute();

  @override
  String get location => GoRouteData.$location('/settings/backups');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DeviceSyncRoute on GoRouteData {
  static DeviceSyncRoute _fromState(GoRouterState state) =>
      const DeviceSyncRoute();

  @override
  String get location => GoRouteData.$location('/settings/device_sync');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $IptvRoute on GoRouteData {
  static IptvRoute _fromState(GoRouterState state) => const IptvRoute();

  @override
  String get location => GoRouteData.$location('/iptv');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $IptvResourcesRoute on GoRouteData {
  static IptvResourcesRoute _fromState(GoRouterState state) =>
      const IptvResourcesRoute();

  @override
  String get location => GoRouteData.$location('/iptv/resources');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $IptvImportRoute on GoRouteData {
  static IptvImportRoute _fromState(GoRouterState state) =>
      const IptvImportRoute();

  @override
  String get location => GoRouteData.$location('/iptv/import');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $IptvSyncRoute on GoRouteData {
  static IptvSyncRoute _fromState(GoRouterState state) => const IptvSyncRoute();

  @override
  String get location => GoRouteData.$location('/iptv/sync');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $IptvHeadersRoute on GoRouteData {
  static IptvHeadersRoute _fromState(GoRouterState state) =>
      const IptvHeadersRoute();

  @override
  String get location => GoRouteData.$location('/iptv/headers');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PlatformDisplayRoute on GoRouteData {
  static PlatformDisplayRoute _fromState(GoRouterState state) =>
      const PlatformDisplayRoute();

  @override
  String get location => GoRouteData.$location('/hot_areas');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PlatformDisplayVisibilityRoute on GoRouteData {
  static PlatformDisplayVisibilityRoute _fromState(GoRouterState state) =>
      const PlatformDisplayVisibilityRoute();

  @override
  String get location => GoRouteData.$location('/hot_areas/visibility');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $PlatformDisplayOrderRoute on GoRouteData {
  static PlatformDisplayOrderRoute _fromState(GoRouterState state) =>
      const PlatformDisplayOrderRoute();

  @override
  String get location => GoRouteData.$location('/hot_areas/order');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountSettingsRoute on GoRouteData {
  static AccountSettingsRoute _fromState(GoRouterState state) =>
      const AccountSettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings_account');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountBilibiliRoute on GoRouteData {
  static AccountBilibiliRoute _fromState(GoRouterState state) =>
      const AccountBilibiliRoute();

  @override
  String get location => GoRouteData.$location('/settings_account/bilibili');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountHuyaRoute on GoRouteData {
  static AccountHuyaRoute _fromState(GoRouterState state) =>
      const AccountHuyaRoute();

  @override
  String get location => GoRouteData.$location('/settings_account/huya');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountYyRoute on GoRouteData {
  static AccountYyRoute _fromState(GoRouterState state) =>
      const AccountYyRoute();

  @override
  String get location => GoRouteData.$location('/settings_account/yy');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountDouyinRoute on GoRouteData {
  static AccountDouyinRoute _fromState(GoRouterState state) =>
      const AccountDouyinRoute();

  @override
  String get location => GoRouteData.$location('/settings_account/douyin');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountKuaishouRoute on GoRouteData {
  static AccountKuaishouRoute _fromState(GoRouterState state) =>
      const AccountKuaishouRoute();

  @override
  String get location => GoRouteData.$location('/settings_account/kuaishou');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountTwitchRoute on GoRouteData {
  static AccountTwitchRoute _fromState(GoRouterState state) =>
      const AccountTwitchRoute();

  @override
  String get location => GoRouteData.$location('/settings_account/twitch');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AccountSoopRoute on GoRouteData {
  static AccountSoopRoute _fromState(GoRouterState state) =>
      const AccountSoopRoute();

  @override
  String get location => GoRouteData.$location('/settings_account/soop');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $TagsRoute on GoRouteData {
  static TagsRoute _fromState(GoRouterState state) => const TagsRoute();

  @override
  String get location => GoRouteData.$location('/settingTags');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $BackupRoute on GoRouteData {
  static BackupRoute _fromState(GoRouterState state) => const BackupRoute();

  @override
  String get location => GoRouteData.$location('/backup');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $DanmuShieldRoute on GoRouteData {
  static DanmuShieldRoute _fromState(GoRouterState state) =>
      const DanmuShieldRoute();

  @override
  String get location => GoRouteData.$location('/shield');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $AboutRoute on GoRouteData {
  static AboutRoute _fromState(GoRouterState state) => const AboutRoute();

  @override
  String get location => GoRouteData.$location('/about');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $homeRoute => GoRouteData.$route(
  path: '/home',
  hasOverriddenOnExit: false,
  factory: $HomeRoute._fromState,
);

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/home');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $agreementPageRoute => GoRouteData.$route(
  path: '/agreement_page',
  hasOverriddenOnExit: false,
  factory: $AgreementPageRoute._fromState,
);

mixin $AgreementPageRoute on GoRouteData {
  static AgreementPageRoute _fromState(GoRouterState state) =>
      const AgreementPageRoute();

  @override
  String get location => GoRouteData.$location('/agreement_page');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingsMenuRoute => GoRouteData.$route(
  path: '/settings',
  hasOverriddenOnExit: false,
  factory: $SettingsMenuRoute._fromState,
);

mixin $SettingsMenuRoute on GoRouteData {
  static SettingsMenuRoute _fromState(GoRouterState state) =>
      const SettingsMenuRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingsIconPickerRoute => GoRouteData.$route(
  path: '/settings/icon_picker',
  hasOverriddenOnExit: false,
  factory: $SettingsIconPickerRoute._fromState,
);

mixin $SettingsIconPickerRoute on GoRouteData {
  static SettingsIconPickerRoute _fromState(GoRouterState state) =>
      SettingsIconPickerRoute(state.extra as String?);

  SettingsIconPickerRoute get _self => this as SettingsIconPickerRoute;

  @override
  String get location => GoRouteData.$location('/settings/icon_picker');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $settingsLoadingStyleRoute => GoRouteData.$route(
  path: '/settings/loading_style',
  hasOverriddenOnExit: false,
  factory: $SettingsLoadingStyleRoute._fromState,
);

mixin $SettingsLoadingStyleRoute on GoRouteData {
  static SettingsLoadingStyleRoute _fromState(GoRouterState state) =>
      const SettingsLoadingStyleRoute();

  @override
  String get location => GoRouteData.$location('/settings/loading_style');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $settingsColorPickerRoute => GoRouteData.$route(
  path: '/settings/color_picker',
  hasOverriddenOnExit: false,
  factory: $SettingsColorPickerRoute._fromState,
);

mixin $SettingsColorPickerRoute on GoRouteData {
  static SettingsColorPickerRoute _fromState(GoRouterState state) =>
      SettingsColorPickerRoute(state.extra as Color?);

  SettingsColorPickerRoute get _self => this as SettingsColorPickerRoute;

  @override
  String get location => GoRouteData.$location('/settings/color_picker');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $appUpdateRoute => GoRouteData.$route(
  path: '/app_update',
  hasOverriddenOnExit: false,
  factory: $AppUpdateRoute._fromState,
);

mixin $AppUpdateRoute on GoRouteData {
  static AppUpdateRoute _fromState(GoRouterState state) =>
      const AppUpdateRoute();

  @override
  String get location => GoRouteData.$location('/app_update');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $appDownloadRoute => GoRouteData.$route(
  path: '/app_update/download',
  hasOverriddenOnExit: false,
  factory: $AppDownloadRoute._fromState,
);

mixin $AppDownloadRoute on GoRouteData {
  static AppDownloadRoute _fromState(GoRouterState state) =>
      const AppDownloadRoute();

  @override
  String get location => GoRouteData.$location('/app_update/download');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $updateHistoryRoute => GoRouteData.$route(
  path: '/update_history',
  hasOverriddenOnExit: false,
  factory: $UpdateHistoryRoute._fromState,
);

mixin $UpdateHistoryRoute on GoRouteData {
  static UpdateHistoryRoute _fromState(GoRouterState state) =>
      const UpdateHistoryRoute();

  @override
  String get location => GoRouteData.$location('/update_history');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $areaRoomsRoute => GoRouteData.$route(
  path: '/area_rooms',
  hasOverriddenOnExit: false,
  factory: $AreaRoomsRoute._fromState,
);

mixin $AreaRoomsRoute on GoRouteData {
  static AreaRoomsRoute _fromState(GoRouterState state) =>
      AreaRoomsRoute(state.extra as AreaRoomsArgs);

  AreaRoomsRoute get _self => this as AreaRoomsRoute;

  @override
  String get location => GoRouteData.$location('/area_rooms');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $searchResultRoute => GoRouteData.$route(
  path: '/search_result',
  hasOverriddenOnExit: false,
  factory: $SearchResultRoute._fromState,
);

mixin $SearchResultRoute on GoRouteData {
  static SearchResultRoute _fromState(GoRouterState state) =>
      SearchResultRoute(state.extra as SearchResultArgs);

  SearchResultRoute get _self => this as SearchResultRoute;

  @override
  String get location => GoRouteData.$location('/search_result');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $wallpaperPageRoute => GoRouteData.$route(
  path: '/wallpaper_page',
  hasOverriddenOnExit: false,
  factory: $WallpaperPageRoute._fromState,
);

mixin $WallpaperPageRoute on GoRouteData {
  static WallpaperPageRoute _fromState(GoRouterState state) =>
      const WallpaperPageRoute();

  @override
  String get location => GoRouteData.$location('/wallpaper_page');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $wallpaperLibraryRoute => GoRouteData.$route(
  path: '/wallpaper_library',
  hasOverriddenOnExit: false,
  factory: $WallpaperLibraryRoute._fromState,
);

mixin $WallpaperLibraryRoute on GoRouteData {
  static WallpaperLibraryRoute _fromState(GoRouterState state) =>
      const WallpaperLibraryRoute();

  @override
  String get location => GoRouteData.$location('/wallpaper_library');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $wallpaperApiRoute => GoRouteData.$route(
  path: '/wallpaper_api',
  hasOverriddenOnExit: false,
  factory: $WallpaperApiRoute._fromState,
);

mixin $WallpaperApiRoute on GoRouteData {
  static WallpaperApiRoute _fromState(GoRouterState state) =>
      const WallpaperApiRoute();

  @override
  String get location => GoRouteData.$location('/wallpaper_api');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $wallpaperApiGroupRoute => GoRouteData.$route(
  path: '/wallpaper_api_group',
  hasOverriddenOnExit: false,
  factory: $WallpaperApiGroupRoute._fromState,
);

mixin $WallpaperApiGroupRoute on GoRouteData {
  static WallpaperApiGroupRoute _fromState(GoRouterState state) =>
      WallpaperApiGroupRoute(state.extra as WallpaperApiGroup);

  WallpaperApiGroupRoute get _self => this as WallpaperApiGroupRoute;

  @override
  String get location => GoRouteData.$location('/wallpaper_api_group');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $wallpaperGalleryRoute => GoRouteData.$route(
  path: '/wallpaper_gallery',
  hasOverriddenOnExit: false,
  factory: $WallpaperGalleryRoute._fromState,
);

mixin $WallpaperGalleryRoute on GoRouteData {
  static WallpaperGalleryRoute _fromState(GoRouterState state) =>
      WallpaperGalleryRoute(state.extra as BackgroundSource);

  WallpaperGalleryRoute get _self => this as WallpaperGalleryRoute;

  @override
  String get location => GoRouteData.$location('/wallpaper_gallery');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $wallpaperItemsRoute => GoRouteData.$route(
  path: '/wallpaper_items',
  hasOverriddenOnExit: false,
  factory: $WallpaperItemsRoute._fromState,
);

mixin $WallpaperItemsRoute on GoRouteData {
  static WallpaperItemsRoute _fromState(GoRouterState state) =>
      WallpaperItemsRoute(state.extra as WallpaperItemsArgs);

  WallpaperItemsRoute get _self => this as WallpaperItemsRoute;

  @override
  String get location => GoRouteData.$location('/wallpaper_items');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $wallpaperPreviewRoute => GoRouteData.$route(
  path: '/wallpaper_preview',
  hasOverriddenOnExit: false,
  factory: $WallpaperPreviewRoute._fromState,
);

mixin $WallpaperPreviewRoute on GoRouteData {
  static WallpaperPreviewRoute _fromState(GoRouterState state) =>
      WallpaperPreviewRoute(state.extra as WallpaperPreviewArgs);

  WallpaperPreviewRoute get _self => this as WallpaperPreviewRoute;

  @override
  String get location => GoRouteData.$location('/wallpaper_preview');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}

RouteBase get $livePlayRoute => GoRouteData.$route(
  path: '/live_play',
  hasOverriddenOnExit: false,
  factory: $LivePlayRoute._fromState,
);

mixin $LivePlayRoute on GoRouteData {
  static LivePlayRoute _fromState(GoRouterState state) =>
      LivePlayRoute(state.extra as Object);

  LivePlayRoute get _self => this as LivePlayRoute;

  @override
  String get location => GoRouteData.$location('/live_play');

  @override
  void go(BuildContext context) => context.go(location, extra: _self.$extra);

  @override
  Future<T?> push<T>(BuildContext context) =>
      context.push<T>(location, extra: _self.$extra);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location, extra: _self.$extra);

  @override
  void replace(BuildContext context) =>
      context.replace(location, extra: _self.$extra);
}
