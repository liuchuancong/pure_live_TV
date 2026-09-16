import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/features/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/app/bootstrap/app_navigator.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/services/startup/startup_controller.dart';
import 'package:pure_live/features/settings/pages/webdav_settings_section.dart';
import 'package:pure_live/features/settings/pages/backup_manage_section.dart';
import 'package:pure_live/features/settings/pages/device_sync_section.dart';
import 'package:pure_live/features/settings/pages/account_settings_section.dart';
import 'package:pure_live/features/settings/pages/account_cookie_page.dart';
import 'package:pure_live/features/settings/pages/account_bilibili_page.dart';
import 'package:pure_live/features/settings/pages/danmaku_shield_section.dart';
import 'package:pure_live/features/settings/pages/audience_metric_section.dart';
import 'package:pure_live/features/settings/pages/tag_management_section.dart';
import 'package:pure_live/features/settings/pages/navigation_section.dart';
import 'package:pure_live/features/settings/pages/nav_visibility_section.dart';
import 'package:pure_live/features/settings/pages/nav_order_section.dart';
import 'package:pure_live/features/settings/pages/nav_icons_section.dart';
import 'package:pure_live/features/settings/pages/platform_display_visibility_section.dart';
import 'package:pure_live/features/settings/pages/platform_display_order_section.dart';
import 'package:pure_live/features/settings/pages/font_family_manager_section.dart';
import 'package:pure_live/features/iptv/pages/iptv_manage_section.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';


/// Every settings page, by its full path — the one list the settings shell
/// iterates.
///
/// Absolute paths only: the app's own `/settings/...` destinations plus the ones
/// the mobile app names (`/iptv`, `/backup`, `/settings_account`, ...). Keeping
/// them in one table is what makes a single shell possible, and it keeps the
/// page list next to the paths instead of spread over two route blocks.
final Map<String, WidgetBuilder> settingsPageRoutes = <String, WidgetBuilder>{
  AppRoutes.kSettingsTheme: (context) => const ThemeSettingsSectionPage(),
  AppRoutes.kSettingsThemePicker: (context) => const ThemePickerSectionPage(),
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
  AppRoutes.kSettingsPage: (context) => const PageSettingsSectionPage(),
  AppRoutes.kSettingsAudience: (context) => const AudienceMetricSectionPage(),
  AppRoutes.kSettingsLocalBackup: (context) => const BackupManageSectionPage(),
  AppRoutes.kSettingsDeviceSync: (context) => const DeviceSyncSectionPage(),
  // Pages the mobile app gives its own path.
  AppRoutes.kIptv: (context) => const IptvManageSectionPage(),
  AppRoutes.kSettingsHotAreas: (context) => const PlatformDisplaySectionPage(),
  AppRoutes.kSettingsHotAreasVisibility: (context) => const PlatformDisplayVisibilitySectionPage(),
  AppRoutes.kSettingsHotAreasOrder: (context) => const PlatformDisplayOrderSectionPage(),
  AppRoutes.kSettingsAccount: (context) => const AccountSettingsSectionPage(),
  // One page per platform: the mobile app gives every platform its own cookie
  // page, and each of these carries both ways in (扫码 + 手动输入).
  AppRoutes.kSettingsAccountBilibili: (context) => const AccountBilibiliPage(),
  AppRoutes.kSettingsAccountHuya: (context) =>
      AccountCookiePage(platform: cookiePlatformFor(AppRoutes.kSettingsAccountHuya)),
  AppRoutes.kSettingsAccountYy: (context) =>
      AccountCookiePage(platform: cookiePlatformFor(AppRoutes.kSettingsAccountYy)),
  AppRoutes.kSettingsAccountDouyin: (context) =>
      AccountCookiePage(platform: cookiePlatformFor(AppRoutes.kSettingsAccountDouyin)),
  AppRoutes.kSettingsAccountKuaishou: (context) =>
      AccountCookiePage(platform: cookiePlatformFor(AppRoutes.kSettingsAccountKuaishou)),
  AppRoutes.kSettingsAccountTwitch: (context) =>
      AccountCookiePage(platform: cookiePlatformFor(AppRoutes.kSettingsAccountTwitch)),
  AppRoutes.kSettingsAccountSoop: (context) =>
      AccountCookiePage(platform: cookiePlatformFor(AppRoutes.kSettingsAccountSoop)),
  AppRoutes.kSettingsTags: (context) => const TagManagementSectionPage(),
  AppRoutes.kBackup: (context) => const BackupSettingsSectionPage(),
  AppRoutes.kWebDavPage: (context) => const WebDavSettingsSectionPage(),
  AppRoutes.kSettingsDanmuShield: (context) => const DanmakuShieldSectionPage(),
  AppRoutes.kAbout: (context) => const AboutSettingsSectionPage(),
};

final routerProvider = Provider<GoRouter>((ref) {
  final isFirstInApp = ref.watch(startupControllerProvider);

  return GoRouter(
    navigatorKey: appNavigatorKey,
    // Lets every TvScaffold know when it is covered and uncovered again, so
    // focus can return to the item the user acted on after a pop.
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
    routes: [
      GoRoute(path: AppRoutes.kInitial, builder: (context, state) => const HomePage()),
      GoRoute(path: AppRoutes.kAgreementPage, builder: (context, state) => const AgreementPage()),
      // Paths, grouping and order follow the desktop app
      // (`pure_live/lib/routes` + `lib/modules/settings`): `/settings` is the
      // menu, every page is pushed as its own screen with a back button, and
      // the pages the desktop app gives a named route keep that path here
      // (IPTV, backup, about, the block list, platform display, third-party
      // authorisation, tags, WebDAV).
      GoRoute(path: AppRoutes.kSettings, builder: (context, state) => const TvSettingsRoutePage()),
      // ONE shell for every settings page.
      //
      // It used to be two: a nested shell inside the `/settings` route for the
      // relative children, plus a second top-level shell for the pages with
      // absolute paths. Two shells meant the same scaffold was wired twice, the
      // page list lived in two places, and a pop could pass through both. The
      // page table below is keyed by the full path, so a single shell serves all
      // of them; `state.uri.path` (not `matchedLocation`, which reports only a
      // relative child's own segment) supplies the title key.
      ShellRoute(
        builder: (context, state, child) =>
            SettingsSectionScaffold(location: state.uri.path, child: child),
        routes: <RouteBase>[
          for (final MapEntry<String, WidgetBuilder> entry in settingsPageRoutes.entries)
            GoRoute(path: entry.key, builder: (context, state) => entry.value(context)),
        ],
      ),
      // The icon picker owns a grid, so it is a route of its own instead of a
      // section page inside the scrolling settings shell. The row that opens it
      // passes the icon it currently shows as `extra` and receives the choice
      // as the pop result.
      GoRoute(
        path: AppRoutes.kSettingsIconPicker,
        builder: (context, state) => IconPickerSectionPage(currentLabel: state.extra as String?),
      ),
      // Grid pickers own their scroll axis, so they are routes of their own
      // rather than sections inside the scrolling settings shell.
      GoRoute(
        path: AppRoutes.kSettingsLoadingStyle,
        builder: (context, state) => const LoadingStyleSectionPage(),
      ),
      GoRoute(
        path: AppRoutes.kSettingsColorPicker,
        builder: (context, state) => ColorPickerSectionPage(current: state.extra as Color?),
      ),
      GoRoute(
        path: AppRoutes.kAreaRooms,
        builder: (context, state) {
          final args = state.extra as AreaRoomsArgs;
          return AreaRoomsPage(site: args.site, subCategory: args.subCategory);
        },
      ),
      GoRoute(
        path: AppRoutes.kSearchResult,
        builder: (context, state) {
          final args = state.extra as SearchResultArgs;
          return TvSearchResultPage(keyword: args.keyword, site: args.site, searchType: args.searchType);
        },
      ),
      GoRoute(
        path: AppRoutes.kWallpaperPage,
        builder: (context, state) => const WallpaperPage(),
      ),
      GoRoute(
        path: AppRoutes.kWallpaperLibrary,
        builder: (context, state) => const WallpaperLibraryPage(),
      ),
      GoRoute(
        path: AppRoutes.kWallpaperApi,
        builder: (context, state) => const WallpaperApiPage(),
      ),
      GoRoute(
        path: AppRoutes.kWallpaperGallery,
        builder: (context, state) => WallpaperGalleryPage(source: state.extra as BackgroundSource),
      ),
      GoRoute(
        path: AppRoutes.kWallpaperItems,
        builder: (context, state) {
          final args = state.extra as WallpaperItemsArgs;
          return WallpaperItemsPage(sourceId: args.sourceId, categoryId: args.categoryId);
        },
      ),
      GoRoute(
        path: AppRoutes.kWallpaperPreview,
        builder: (context, state) => WallpaperPreviewPage(args: state.extra as WallpaperPreviewArgs),
      ),
      GoRoute(
        path: AppRoutes.kLivePlay,
        builder: (context, state) {
          final extra = state.extra;
          final args = extra is LiveRoom
              ? LivePlayArgs.fromRoom(extra)
              : (extra is LivePlayArgs ? extra : const LivePlayArgs(platform: '', roomId: ''));
          return LivePlayPage(args: args);
        },
      ),
    ],
  );
});

