import 'package:go_router/go_router.dart';
import 'package:pure_live/features/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/app/bootstrap/app_navigator.dart';
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
      ShellRoute(
      builder: (context, state, child) => TvSettingsShell(child: child),
      routes: [
        GoRoute(path: 'general', builder: (context, state) => GeneralSettingsSectionPage()),
        GoRoute(path: 'theme', builder: (context, state) => ThemeSettingsSectionPage()),
        GoRoute(path: 'player_kernel', builder: (context, state) => PlayerKernelSettingsSectionPage()),
        GoRoute(path: 'video', builder: (context, state) => VideoSettingsSectionPage()),
        GoRoute(path: 'decoder', builder: (context, state) => DecoderSettingsSectionPage()),
        GoRoute(path: 'renderer', builder: (context, state) => RendererSettingsSectionPage()),
        GoRoute(path: 'audio_output', builder: (context, state) => AudioOutputSettingsSectionPage()),
        GoRoute(path: 'danmaku', builder: (context, state) => DanmakuSettingsSectionPage()),
        GoRoute(path: 'platform', builder: (context, state) => PlatformSettingsSectionPage()),
        GoRoute(path: 'page', builder: (context, state) => PageSettingsSectionPage()),
        GoRoute(path: 'refresh', builder: (context, state) => RefreshSettingsSectionPage()),
        GoRoute(path: 'font', builder: (context, state) => FontSettingsSectionPage()),
        GoRoute(path: 'cache', builder: (context, state) => CacheSettingsSectionPage()),
        GoRoute(path: 'proxy', builder: (context, state) => ProxySettingsSectionPage()),
        GoRoute(path: 'backup', builder: (context, state) => BackupSettingsSectionPage()),
        GoRoute(path: 'webdav', builder: (context, state) => WebDavSettingsSectionPage()),
        GoRoute(path: 'backups', builder: (context, state) => BackupManageSectionPage()),
        GoRoute(path: 'account', builder: (context, state) => AccountSettingsSectionPage()),
        GoRoute(path: 'shield', builder: (context, state) => DanmakuShieldSectionPage()),
        GoRoute(path: 'audience', builder: (context, state) => AudienceMetricSectionPage()),
        GoRoute(path: 'tags', builder: (context, state) => TagManagementSectionPage()),
        GoRoute(path: 'navigation', builder: (context, state) => NavigationSectionPage()),
        GoRoute(path: 'fonts', builder: (context, state) => FontFamilyManagerSectionPage()),
        GoRoute(path: 'iptv', builder: (context, state) => IptvManageSectionPage()),
        GoRoute(path: 'about', builder: (context, state) => AboutSettingsSectionPage()),
      ],
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

