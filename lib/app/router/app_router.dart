import 'package:go_router/go_router.dart';
import 'package:pure_live/features/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/app/bootstrap/app_navigator.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/services/startup/startup_controller.dart';
import 'package:pure_live/features/wallpaper/wallpaper_page.dart';
import 'package:pure_live/features/wallpaper/wallpaper_preview_page.dart';

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

      // 设置模块。
      //
      // 侧边栏（TvSettingsShell.modules）跳转的是 /settings/<section>，所以每个
      // 分区必须注册成同名路由；这里直接从 modules 派生，新增分区无需再改路由表。
      // 之前用的是「无 path 的 ShellRoute」+ 相对路径，实际注册成了 /general，
      // 与侧边栏的 /settings/general 对不上，点任何一项都会 no routes。
      GoRoute(
        path: AppRoutes.kSettings,
        redirect: (context, state) =>
            state.uri.path == AppRoutes.kSettings ? '${AppRoutes.kSettings}/general' : null,
      ),
      for (final module in TvSettingsShell.modules)
        GoRoute(path: module.path, builder: (context, state) => TvSettingsShell(child: module.page)),

      // 壁纸 / 背景：播放页「背景设置」入口，以及全屏预览。
      GoRoute(path: AppRoutes.kWallpaperPage, builder: (context, state) => const WallpaperPage()),
      GoRoute(path: AppRoutes.kWallpaperPreview, builder: (context, state) => const WallpaperPreviewPage()),

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
