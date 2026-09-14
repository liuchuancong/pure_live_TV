import 'package:go_router/go_router.dart';
import 'package:pure_live/global/app_navigator.dart';
import 'package:pure_live/routes/app_routes.dart';
import 'package:pure_live/modules/home/home_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/agreement/agreement_page.dart';
import 'package:pure_live/modules/settings/tv_settings_page.dart';
import 'package:pure_live/modules/settings/pages/about_settings_section.dart';
import 'package:pure_live/modules/settings/pages/audio_output_settings_section.dart';
import 'package:pure_live/modules/settings/pages/backup_settings_section.dart';
import 'package:pure_live/modules/settings/pages/cache_settings_section.dart';
import 'package:pure_live/modules/settings/pages/danmaku_settings_section.dart';
import 'package:pure_live/modules/settings/pages/decoder_settings_section.dart';
import 'package:pure_live/modules/settings/pages/font_settings_section.dart';
import 'package:pure_live/modules/settings/pages/general_settings_section.dart';
import 'package:pure_live/modules/settings/pages/page_settings_section.dart';
import 'package:pure_live/modules/settings/pages/platform_settings_section.dart';
import 'package:pure_live/modules/settings/pages/player_kernel_settings_section.dart';
import 'package:pure_live/modules/settings/pages/proxy_settings_section.dart';
import 'package:pure_live/modules/settings/pages/refresh_settings_section.dart';
import 'package:pure_live/modules/settings/pages/renderer_settings_section.dart';
import 'package:pure_live/modules/settings/pages/theme_settings_section.dart';
import 'package:pure_live/modules/settings/pages/video_settings_section.dart';

import 'package:pure_live/modules/area_rooms/area_rooms_page.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/modules/live_play/models/live_play_args.dart';
import 'package:pure_live/modules/live_play/pages/live_play_page.dart';
import 'package:pure_live/services/startUp/startup_controller.dart';
import 'package:pure_live/modules/search/tv_search_result_page.dart';

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
        GoRoute(path: 'general', builder: (context, state) => const GeneralSettingsSectionPage()),
        GoRoute(path: 'theme', builder: (context, state) => const ThemeSettingsSectionPage()),
        GoRoute(path: 'player_kernel', builder: (context, state) => const PlayerKernelSettingsSectionPage()),
        GoRoute(path: 'video', builder: (context, state) => const VideoSettingsSectionPage()),
        GoRoute(path: 'decoder', builder: (context, state) => const DecoderSettingsSectionPage()),
        GoRoute(path: 'renderer', builder: (context, state) => const RendererSettingsSectionPage()),
        GoRoute(path: 'audio_output', builder: (context, state) => const AudioOutputSettingsSectionPage()),
        GoRoute(path: 'danmaku', builder: (context, state) => const DanmakuSettingsSectionPage()),
        GoRoute(path: 'platform', builder: (context, state) => const PlatformSettingsSectionPage()),
        GoRoute(path: 'page', builder: (context, state) => const PageSettingsSectionPage()),
        GoRoute(path: 'refresh', builder: (context, state) => const RefreshSettingsSectionPage()),
        GoRoute(path: 'font', builder: (context, state) => const FontSettingsSectionPage()),
        GoRoute(path: 'cache', builder: (context, state) => const CacheSettingsSectionPage()),
        GoRoute(path: 'proxy', builder: (context, state) => const ProxySettingsSectionPage()),
        GoRoute(path: 'backup', builder: (context, state) => const BackupSettingsSectionPage()),
        GoRoute(path: 'about', builder: (context, state) => const AboutSettingsSectionPage()),
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
