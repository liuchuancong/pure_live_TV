import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/favorite/favorite_provider.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class FavoritePage extends ConsumerStatefulWidget {
  const FavoritePage({super.key});

  @override
  ConsumerState<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends ConsumerState<FavoritePage> {
  /// PagingParam identity is the paging family key: constructing a fresh one
  /// per build (closures compare by identity) tore down the PagingCore,
  /// refetched and reset the grid to page 1 on every unrelated rebuild — the
  /// spacing sliders, any settings toggle, every favourite emission.
  final Map<String, PagingParam<LiveRoom>> _pagingParamsCache = {};

  /// The param the grid is currently built from. Following a room pushes fresh
  /// data into this param's core (see [_listenToFavoriteChanges]).
  PagingParam<LiveRoom>? _activeParam;
  bool _poolPushScheduled = false;

  PagingParam<LiveRoom> _getOrCreateParam(String key) {
    return _pagingParamsCache.putIfAbsent(key, () {
      return PagingParam<LiveRoom>(
        mode: PagingMode.localReactive,
        pageSize: 12,
        keepAlive: false,
        fetchAll: () async {
          return ref.read(favoriteProvider.notifier).getFilteredRooms();
        },
        localRefresh: () async {},
      );
    });
  }

  /// Keeps the grid in step with the followed rooms.
  ///
  /// The grid's data lives in the PagingCore, and a favourite change
  /// deliberately does NOT rebuild the view — its identity is only the
  /// tab/tag selection, so that following a room no longer throws away the
  /// focus and the scroll position. That also meant nothing told the core the
  /// list had changed, so a room followed in the player only showed up after a
  /// tab switch or a restart. Pushing the fresh pool into the live core keeps
  /// both: the grid updates, the view is never torn down.
  void _listenToFavoriteChanges() {
    ref.listen(favoriteProvider, (previous, next) {
      final param = _activeParam;
      if (param == null || _poolPushScheduled) return;
      _poolPushScheduled = true;
      // Provider writes during a build phase throw, so the push lands on the
      // next frame; the identity guard drops it if the user switched tabs in
      // the meantime.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _poolPushScheduled = false;
        if (!mounted || !identical(_activeParam, param)) return;
        ref.read(pagingCoreProvider(param).notifier).updateLocalPool(
          ref.read(favoriteProvider.notifier).getFilteredRooms(),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final favoriteState = ref.watch(favoriteProvider);
    // column/row spacing are an offset from the 6.0 design default, so the untouched
    // default reproduces the original 32 design-pixel gap.
    final themeState = ref.watch(themeSettingsControllerProvider);
    final double crossSpacing = themeState.crossAxisSpacing;
    final double mainSpacing = themeState.mainAxisSpacing;

    // The playlist the player gets from this page is the 已开播 list — a room
    // opened from 回放/离线 must still switch between rooms that are live.
    final liveRooms = ref.read(favoriteProvider.notifier).getLiveRooms();

    final currentParam = _getOrCreateParam(
      'fav_${favoriteState.tabOnlineIndex}_${favoriteState.tabSiteIndex}_${favoriteState.selectedTagId}',
    );
    _activeParam = currentParam;
    _listenToFavoriteChanges();

    final List<TvTabItemData> statusTabs = [
      TvTabItemData(title: i18n('live')),
      TvTabItemData(title: i18n('ui_replaying')),
      TvTabItemData(title: i18n('offline_room_title')),
    ];

    final availableSitesList = Sites().availableSites(containsAll: true);
    final List<TvTabItemData> siteTabs = availableSitesList.map(TvTabItemData.site).toList();

    return TvScaffold(
      child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvTabBar(
                    tabs: statusTabs,
                    currentIndex: favoriteState.tabOnlineIndex,
                    onTabChange: (index) {
                      ref.read(favoriteProvider.notifier).changeOnlineTab(index);
                    },
                    onTabRefresh: (index) {
                      ref.read(favoriteProvider.notifier).refreshData();
                    },
                  ),
                  SizedBox(height: 12.sp),
                  TvTabBar(
                    tabs: siteTabs,
                    currentIndex: favoriteState.tabSiteIndex,
                    onTabChange: (index) {
                      ref.read(favoriteProvider.notifier).changeSelectedTag('all');
                      ref.read(favoriteProvider.notifier).changeSiteTab(index);
                    },
                    // OK twice on the platform tab refetches this list, like the
                    // status bar above it.
                    onTabRefresh: (index) => ref.read(favoriteProvider.notifier).refreshData(),
                  ),
                  SizedBox(height: 12.sp),
                  if (favoriteState.visibleTags.isNotEmpty)
                    Container(
                      height: 44.sp,
                      padding: EdgeInsets.symmetric(horizontal: 8.sp),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: favoriteState.visibleTags.length + 1,
                        itemBuilder: (context, index) {
                          final bool isAllTag = index == 0;
                          final bool isSelected = isAllTag
                              ? favoriteState.selectedTagId == 'all'
                              : favoriteState.selectedTagId == favoriteState.visibleTags[index - 1].id;

                          return Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.sp),
                            key: ValueKey(isAllTag ? 'tag_all' : 'tag_${favoriteState.visibleTags[index - 1].id}'),
                            child: TvButton(
                              title: isAllTag ? i18n('recorder_tab_all') : favoriteState.visibleTags[index - 1].name,
                              size: TvButtonSize.mini,
                              isSecondary: !isSelected,
                              onTap: () {
                                if (isAllTag) {
                                  ref.read(favoriteProvider.notifier).changeSelectedTag('all');
                                } else {
                                  ref
                                      .read(favoriteProvider.notifier)
                                      .changeSelectedTag(favoriteState.visibleTags[index - 1].id);
                                }
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  SizedBox(height: 16.sp),
                  Expanded(
                    child: TvTabView(
                      // Identity is the tab/tag selection only. Including the
                      // room count here meant that following or unfollowing a
                      // single room rebuilt the view and dropped both the focus
                      // memory and the scroll position the user was on.
                      memoryKey:
                          "fav_tv_view_${favoriteState.tabOnlineIndex}_${favoriteState.tabSiteIndex}_${favoriteState.selectedTagId}",
                      verticalEdge: DpadEdgeBehavior.leave,
                      horizontalEdge: DpadEdgeBehavior.stop,
                      child: BasePagedTvView<LiveRoom>(
                        key: ValueKey(
                          'fav_grid_${favoriteState.tabOnlineIndex}_${favoriteState.tabSiteIndex}_${favoriteState.selectedTagId}',
                        ),
                        param: currentParam,
                        getNotifier: () => ref.read(pagingCoreProvider(currentParam).notifier),
                        emptyScene: EmptyScene.favorite,
                        onEmptyGoSearch: () => ref.read(sideMenuIndexProvider.notifier).changeIndex(TvMenuType.search.value),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: themeState.denseRoomLayout,
                          mainAxisSpacing: mainSpacing.w,
                          crossAxisSpacing: crossSpacing.w,
                          childAspectRatio: ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout),
                        ),
                        itemBuilder: (context, room, index) => TvRoomCard(
                          room: room,
                          playlist: liveRooms,
                          onLongPress: () {
                            FavOperateUtil.showRoomActionDialog(context, room);
                          },
                          showFollowedMark: false,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
    );
  }
}
