// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $homeRoute,
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
  $musicArchiveRoute,
  $musicPlayerRoute,
  $videoDetailRoute,
  $videoPlayerRoute,
  $videoSeasonRoute,
  $ugcCommentsRoute,
  $ugcUserSpaceRoute,
  $musicFavDetailRoute,
];

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
  name: 'live_play',
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

RouteBase get $musicArchiveRoute => GoRouteData.$route(
  path: '/music_archive',
  hasOverriddenOnExit: false,
  factory: $MusicArchiveRoute._fromState,
);

mixin $MusicArchiveRoute on GoRouteData {
  static MusicArchiveRoute _fromState(GoRouterState state) =>
      MusicArchiveRoute(state.extra as Object);

  MusicArchiveRoute get _self => this as MusicArchiveRoute;

  @override
  String get location => GoRouteData.$location('/music_archive');

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

RouteBase get $musicPlayerRoute => GoRouteData.$route(
  path: '/music_player',
  hasOverriddenOnExit: false,
  factory: $MusicPlayerRoute._fromState,
);

mixin $MusicPlayerRoute on GoRouteData {
  static MusicPlayerRoute _fromState(GoRouterState state) =>
      const MusicPlayerRoute();

  @override
  String get location => GoRouteData.$location('/music_player');

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

RouteBase get $videoDetailRoute => GoRouteData.$route(
  path: '/video_detail',
  hasOverriddenOnExit: false,
  factory: $VideoDetailRoute._fromState,
);

mixin $VideoDetailRoute on GoRouteData {
  static VideoDetailRoute _fromState(GoRouterState state) =>
      VideoDetailRoute(state.extra as Object);

  VideoDetailRoute get _self => this as VideoDetailRoute;

  @override
  String get location => GoRouteData.$location('/video_detail');

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

RouteBase get $videoPlayerRoute => GoRouteData.$route(
  path: '/video_player',
  hasOverriddenOnExit: false,
  factory: $VideoPlayerRoute._fromState,
);

mixin $VideoPlayerRoute on GoRouteData {
  static VideoPlayerRoute _fromState(GoRouterState state) =>
      const VideoPlayerRoute();

  @override
  String get location => GoRouteData.$location('/video_player');

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

RouteBase get $videoSeasonRoute => GoRouteData.$route(
  path: '/video_season',
  hasOverriddenOnExit: false,
  factory: $VideoSeasonRoute._fromState,
);

mixin $VideoSeasonRoute on GoRouteData {
  static VideoSeasonRoute _fromState(GoRouterState state) =>
      VideoSeasonRoute(state.extra as Object);

  VideoSeasonRoute get _self => this as VideoSeasonRoute;

  @override
  String get location => GoRouteData.$location('/video_season');

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

RouteBase get $ugcCommentsRoute => GoRouteData.$route(
  path: '/ugc_comments',
  hasOverriddenOnExit: false,
  factory: $UgcCommentsRoute._fromState,
);

mixin $UgcCommentsRoute on GoRouteData {
  static UgcCommentsRoute _fromState(GoRouterState state) =>
      UgcCommentsRoute(state.extra as Object);

  UgcCommentsRoute get _self => this as UgcCommentsRoute;

  @override
  String get location => GoRouteData.$location('/ugc_comments');

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

RouteBase get $ugcUserSpaceRoute => GoRouteData.$route(
  path: '/ugc_user_space',
  hasOverriddenOnExit: false,
  factory: $UgcUserSpaceRoute._fromState,
);

mixin $UgcUserSpaceRoute on GoRouteData {
  static UgcUserSpaceRoute _fromState(GoRouterState state) => UgcUserSpaceRoute(
    int.parse(state.uri.queryParameters['mid']!),
    state.uri.queryParameters['name']!,
  );

  UgcUserSpaceRoute get _self => this as UgcUserSpaceRoute;

  @override
  String get location => GoRouteData.$location(
    '/ugc_user_space',
    queryParams: {'mid': _self.mid.toString(), 'name': _self.name},
  );

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

RouteBase get $musicFavDetailRoute => GoRouteData.$route(
  path: '/music_fav_detail',
  hasOverriddenOnExit: false,
  factory: $MusicFavDetailRoute._fromState,
);

mixin $MusicFavDetailRoute on GoRouteData {
  static MusicFavDetailRoute _fromState(GoRouterState state) =>
      MusicFavDetailRoute(state.extra as Object);

  MusicFavDetailRoute get _self => this as MusicFavDetailRoute;

  @override
  String get location => GoRouteData.$location('/music_fav_detail');

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
