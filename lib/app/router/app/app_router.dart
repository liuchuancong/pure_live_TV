import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/features/index.dart';
import 'package:pure_live/modules/vod/index.dart';
import 'package:pure_live/modules/live/index.dart';
import 'package:pure_live/modules/music/index.dart';
import 'package:pure_live/modules/video/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/app/router/app/app_routes.dart';
import 'package:pure_live/app/bootstrap/app_navigator.dart';
import 'package:pure_live/core/widgets/tv_focus_restorer.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/services/startup/startup_controller.dart';
import 'package:pure_live/app/router/observers/wallpaper_route_observer.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/features/settings/pages/app_update_page.dart';
import 'package:pure_live/features/settings/pages/app_download_page.dart';
import 'package:pure_live/features/settings/pages/nav_order_section.dart';
import 'package:pure_live/features/settings/pages/nav_icons_section.dart';
import 'package:pure_live/modules/live/iptv/pages/iptv_sync_section.dart';
import 'package:pure_live/features/settings/pages/navigation_section.dart';
import 'package:pure_live/features/settings/pages/update_history_page.dart';
import 'package:pure_live/features/settings/pages/device_sync_section.dart';
import 'package:pure_live/features/settings/pages/account_cookie_page.dart';
import 'package:pure_live/modules/live/iptv/pages/iptv_manage_section.dart';
import 'package:pure_live/modules/live/iptv/pages/iptv_import_section.dart';
import 'package:pure_live/modules/live/iptv/pages/iptv_headers_section.dart';
import 'package:pure_live/features/settings/pages/backup_manage_section.dart';
import 'package:pure_live/features/settings/pages/account_bilibili_page.dart';
import 'package:pure_live/features/settings/pages/danmaku_shield_section.dart';
import 'package:pure_live/features/settings/pages/tag_management_section.dart';
import 'package:pure_live/features/settings/pages/nav_visibility_section.dart';
import 'package:pure_live/modules/live/iptv/pages/iptv_resources_section.dart';
import 'package:pure_live/features/settings/pages/audience_metric_section.dart';
import 'package:pure_live/features/settings/pages/account_settings_section.dart';
import 'package:pure_live/features/settings/pages/font_family_manager_section.dart';
import 'package:pure_live/features/settings/pages/platform_display_order_section.dart';
import 'package:pure_live/features/settings/pages/platform_display_visibility_section.dart';

// The settings routes live in a `part` on purpose: go_router_builder emits one
// `$appRoutes` per *library*, so a separate `settings_routes.dart` library would
// generate a second, competing `$appRoutes` — and the local one silently shadows
// it, leaving every settings path unregistered.
part 'app_router.g.dart';
part '../settings/settings_routes.dart';

/// The home shell: side menu plus the tab the user picked.
@TypedGoRoute<HomeRoute>(path: AppRoutes.kInitial)
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

/// `/settings` — the menu itself, not a section.
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
@TypedGoRoute<LivePlayRoute>(path: AppRoutes.kLivePlay, name: AppRoutes.kLivePlayName)
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

/// The music-mode track list of one archive. `$extra` carries the archive the
/// grid card had; the page fetches the parts itself before anything plays.
@TypedGoRoute<MusicArchiveRoute>(path: AppRoutes.kMusicArchive)
class MusicArchiveRoute extends GoRouteData with $MusicArchiveRoute {
  MusicArchiveRoute(this.$extra);

  final Object $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final extra = $extra;
    return extra is MusicArchive ? MusicArchivePage(archive: extra) : const SizedBox.shrink();
  }
}

/// The music-mode full-screen player. Playback state lives in the
/// music-player controller, so the route carries nothing.
@TypedGoRoute<MusicPlayerRoute>(path: AppRoutes.kMusicPlayer)
class MusicPlayerRoute extends GoRouteData with $MusicPlayerRoute {
  const MusicPlayerRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const MusicPlayerPage();
}

/// The video-mode detail page of one archive. `$extra` carries the archive the
/// grid card had; parts and related videos are fetched by the page itself.
@TypedGoRoute<VideoDetailRoute>(path: AppRoutes.kVideoDetail)
class VideoDetailRoute extends GoRouteData with $VideoDetailRoute {
  VideoDetailRoute(this.$extra);

  final Object $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final extra = $extra;
    return extra is MusicArchive ? VideoDetailPage(archive: extra) : const SizedBox.shrink();
  }
}

/// The video-mode full-screen player (newBV layer scheme).
@TypedGoRoute<VideoPlayerRoute>(path: AppRoutes.kVideoPlayer)
class VideoPlayerRoute extends GoRouteData with $VideoPlayerRoute {
  const VideoPlayerRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const VideoPlayerPage();
}

/// One PGC season's episode page. `$extra` is the feed card the tile had.
@TypedGoRoute<VideoSeasonRoute>(path: AppRoutes.kVideoSeason)
class VideoSeasonRoute extends GoRouteData with $VideoSeasonRoute {
  VideoSeasonRoute(this.$extra);

  final Object $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final extra = $extra;
    return extra is PgcItem ? VideoSeasonPage(item: extra) : const SizedBox.shrink();
  }
}

/// One archive tag's search results, reached from a detail-page tag chip.
@TypedGoRoute<VideoTagSearchRoute>(path: AppRoutes.kVideoTagSearch)
class VideoTagSearchRoute extends GoRouteData with $VideoTagSearchRoute {
  VideoTagSearchRoute(this.keyword);

  final String keyword;

  @override
  Widget build(BuildContext context, GoRouterState state) => VideoTagSearchPage(keyword: keyword);
}

/// The shared comments page over one archive's oid.
@TypedGoRoute<UgcCommentsRoute>(path: AppRoutes.kUgcComments)
class UgcCommentsRoute extends GoRouteData with $UgcCommentsRoute {
  UgcCommentsRoute(this.$extra);

  final Object $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final extra = $extra;
    return extra is UgcCommentsArgs
        ? UgcCommentsPage(oid: extra.oid, type: extra.type, title: extra.title)
        : const SizedBox.shrink();
  }
}

/// The shared user-space page over one UP's mid.
@TypedGoRoute<UgcUserSpaceRoute>(path: AppRoutes.kUgcUserSpace)
class UgcUserSpaceRoute extends GoRouteData with $UgcUserSpaceRoute {
  UgcUserSpaceRoute(this.mid, this.name);

  final int mid;
  final String name;

  @override
  Widget build(BuildContext context, GoRouterState state) => UgcUserSpacePage(mid: mid, name: name);
}

/// One synced playlist's track table. `$extra` is the folder card.
@TypedGoRoute<MusicFavDetailRoute>(path: AppRoutes.kMusicFavDetail)
class MusicFavDetailRoute extends GoRouteData with $MusicFavDetailRoute {
  MusicFavDetailRoute(this.$extra);

  final Object $extra;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final extra = $extra;
    return extra is FavFolder ? MusicFavDetailPage(folder: extra) : const SizedBox.shrink();
  }
}

/// The arguments [UgcCommentsRoute] carries through `$extra`.
class UgcCommentsArgs {
  const UgcCommentsArgs({required this.oid, required this.title, this.type = 1});

  final int oid;
  final String title;
  final int type;
}

final routerProvider = Provider<GoRouter>((ref) {
  final isFirstInApp = ref.watch(startupControllerProvider);

  return GoRouter(
    navigatorKey: appNavigatorKey,
    // Lets every page know when it is covered and uncovered again, so focus can
    // return to the item the user acted on after a pop.
    observers: [tvRouteObserver, wallpaperRouteObserver],
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
