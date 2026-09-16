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
import 'package:pure_live/features/settings/pages/account_settings_section.dart';
import 'package:pure_live/features/settings/pages/danmaku_shield_section.dart';
import 'package:pure_live/features/settings/pages/audience_metric_section.dart';
import 'package:pure_live/features/settings/pages/tag_management_section.dart';
import 'package:pure_live/features/settings/pages/navigation_section.dart';
import 'package:pure_live/features/settings/pages/font_family_manager_section.dart';
import 'package:pure_live/features/iptv/pages/iptv_manage_section.dart';


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
      //
      // A ShellRoute that owns no path cannot resolve relative children (see
      // test/settings_route_nesting_test.dart), which is why `/settings/...`
      // children hang off this GoRoute and the named pages use absolute paths.
      GoRoute(
        path: AppRoutes.kSettings,
        builder: (context, state) => const TvSettingsRoutePage(),
        routes: [
          ShellRoute(
            builder: (context, state, child) =>
                SettingsSectionScaffold(location: state.matchedLocation, child: child),
            routes: [
              GoRoute(path: 'theme', builder: (context, state) => const ThemeSettingsSectionPage()),
              GoRoute(path: 'theme_picker', builder: (context, state) => const ThemePickerSectionPage()),
              GoRoute(path: 'refresh', builder: (context, state) => const RefreshSettingsSectionPage()),
              GoRoute(path: 'video', builder: (context, state) => const VideoSettingsSectionPage()),
              GoRoute(path: 'player_kernel', builder: (context, state) => const PlayerKernelSettingsSectionPage()),
              GoRoute(path: 'proxy', builder: (context, state) => const ProxySettingsSectionPage()),
              GoRoute(path: 'general', builder: (context, state) => const GeneralSettingsSectionPage()),
              GoRoute(path: 'navigation', builder: (context, state) => const NavigationSectionPage()),
              GoRoute(path: 'platform', builder: (context, state) => const PlatformSettingsSectionPage()),
              GoRoute(path: 'cache', builder: (context, state) => const CacheSettingsSectionPage()),
              GoRoute(path: 'config_preview', builder: (context, state) => const LocalConfigPreviewSectionPage()),
              GoRoute(path: 'decoder', builder: (context, state) => const DecoderSettingsSectionPage()),
              GoRoute(path: 'renderer', builder: (context, state) => const RendererSettingsSectionPage()),
              GoRoute(path: 'audio_output', builder: (context, state) => const AudioOutputSettingsSectionPage()),
              GoRoute(path: 'danmaku', builder: (context, state) => const DanmakuSettingsSectionPage()),
              GoRoute(path: 'font', builder: (context, state) => const FontSettingsSectionPage()),
              GoRoute(path: 'fonts', builder: (context, state) => const FontFamilyManagerSectionPage()),
              GoRoute(path: 'page', builder: (context, state) => const PageSettingsSectionPage()),
              GoRoute(path: 'audience', builder: (context, state) => const AudienceMetricSectionPage()),
              GoRoute(path: 'backups', builder: (context, state) => const BackupManageSectionPage()),
            ],
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) =>
            SettingsSectionScaffold(location: state.matchedLocation, child: child),
        routes: [
          GoRoute(path: AppRoutes.kIptv, builder: (context, state) => const IptvManageSectionPage()),
          GoRoute(path: AppRoutes.kSettingsHotAreas, builder: (context, state) => const PlatformDisplaySectionPage()),
          GoRoute(path: AppRoutes.kSettingsAccount, builder: (context, state) => const AccountSettingsSectionPage()),
          GoRoute(path: AppRoutes.kSettingsTags, builder: (context, state) => const TagManagementSectionPage()),
          GoRoute(path: AppRoutes.kBackup, builder: (context, state) => const BackupSettingsSectionPage()),
          GoRoute(path: AppRoutes.kWebDavPage, builder: (context, state) => const WebDavSettingsSectionPage()),
          GoRoute(path: AppRoutes.kSettingsDanmuShield, builder: (context, state) => const DanmakuShieldSectionPage()),
          GoRoute(path: AppRoutes.kAbout, builder: (context, state) => const AboutSettingsSectionPage()),
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

