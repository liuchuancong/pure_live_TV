import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/favorite/favorite_provider.dart';
import 'package:pure_live/features/favorite/model/favorite_state.dart';
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
  /// does not rebuild the view — its identity is only the
  /// tab/tag selection, so that following a room no longer throws away the
  /// focus and the scroll position. That also meant nothing told the core the
  /// list had changed, so a room followed in the player only showed up after a
  /// tab switch or a restart. Pushing the fresh pool into the live core keeps
  /// both: the grid updates, the view is never torn down.
  /// The favorite grid's empty state, layered like the mobile reference's
  /// `_FavoriteEmptyState`:
  ///
  /// * nothing followed at all -> an empty live list with a plain refresh;
  /// * this platform tab holds no rooms → its own hint;
  /// * rooms exist but the tag filter empties the list -> a "data still there"
  ///   user knows the follows are safe;
  ///   hint, so the user knows filtering - not unfollowing - emptied it;
  ///
  /// Both retry buttons run the provider's `refreshData` - the reference's
  /// `controller.refreshData`, a network revalidation of the followed rooms —
  /// not the paging core's local re-slice, which on an empty list is a no-op.
  ///
  /// * the offline tab holds rooms the current tab hides -> a jump to it.
///
/// Under every layer sits a search jump: the reference keeps search reachable
  /// from this page through its app-bar menu, and an empty favorites page is
  /// exactly where the user needs a way *to* rooms they don't follow yet.
  /// retry: a full network revalidation of the followed rooms,
  /// not the paging core's local re-slice.
  Future<void> _retryRefresh() => ref.read(favoriteProvider.notifier).refreshData();

  Widget _buildFavoriteEmpty(BuildContext context, FavoriteState favoriteState, VoidCallback onRefresh) {
    final List<Site> sites = ref.read(favoriteProvider.notifier).siteTabs;
    final String siteId = sites.isEmpty
        ? Sites.allSite
        : sites[favoriteState.tabSiteIndex.clamp(0, sites.length - 1)].id;
    bool onSite(LiveRoom room) => siteId == Sites.allSite || room.normalizedPlatformId == siteId.trim().toLowerCase();

    final int globalTotal = favoriteState.onlineRooms.length + favoriteState.replayRooms.length + favoriteState.offlineRooms.length;
    final int totalForSite = siteId == Sites.allSite
        ? globalTotal
        : favoriteState.onlineRooms.where(onSite).length +
              favoriteState.replayRooms.where(onSite).length +
              favoriteState.offlineRooms.where(onSite).length;
    final int offlineForSite = favoriteState.offlineRooms.where(onSite).length;

    // The second way out of the empty state: both branches offer search next to
    // their own action.
    final String searchLabel = i18n('empty_favorite_action');
    final Widget searchIcon = Icon(Icons.search_rounded, size: 24.sp);
    void goSearch() => ref.read(sideMenuIndexProvider.notifier).changeIndex(TvMenuType.search.value);

    final AppStatusView status;
    if (globalTotal == 0) {
      status = AppStatusView(
        type: AppStatusType.empty,
        icon: Remix.heart_3_fill,
        title: i18n('empty_favorite_online_title'),
        subtitle: i18n('empty_favorite_online_subtitle'),
        buttonText: i18n('retry'),
        onTap: _retryRefresh,
        secondaryButtonText: searchLabel,
        secondaryButtonIcon: searchIcon,
        onSecondaryTap: goSearch,
      );
    } else {
      final String title = switch (favoriteState.tabOnlineIndex) {
        1 => i18n('favorite_empty_recording_title'),
        2 => i18n('favorite_empty_offline_title'),
        _ => i18n('favorite_empty_online_title'),
      };
      final String subtitle = totalForSite == 0
          ? i18n('favorite_empty_platform_subtitle')
          : i18n('favorite_empty_filter_subtitle', args: {'count': '$totalForSite'});
      final bool canShowOffline = favoriteState.tabOnlineIndex != 2 && offlineForSite > 0;

      status = AppStatusView(
        type: AppStatusType.empty,
        icon: Remix.heart_3_fill,
        title: title,
        subtitle: subtitle,
        buttonText: canShowOffline ? i18n('favorite_show_offline') : i18n('retry'),
        onTap: canShowOffline ? () => ref.read(favoriteProvider.notifier).changeOnlineTab(2) : _retryRefresh,
        secondaryButtonText: searchLabel,
        secondaryButtonIcon: searchIcon,
        onSecondaryTap: goSearch,
      );
    }

    return status;
  }

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

    // The playlist this page hands the player is the live-only list - a room
    // opened from the replay or offline tab still switches between live rooms.
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

    // "All" plus the platforms that actually have a followed room, like the
    // mobile reference: a platform nobody follows is not a tab.
    final availableSitesList = ref.read(favoriteProvider.notifier).siteTabs;
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
                              // `selected` keeps the accent on the tag
                              // that filters the grid. Without it the active tag
                              // was only ever highlighted while the remote was on
                              // it, so moving to another tag looked like the
                              // highlight had been lost (the reference paints its
                              // selected chip with the primary colour).
                              selected: isSelected,
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
                        emptyBuilder: (context, onRefresh) => _buildFavoriteEmpty(context, favoriteState, onRefresh),
                        // The builder above draws its own empty state (with the
                        // search action next to 刷新); EmptyScene.favorite stays as
                        // the fallback for any path that reaches the view without it.
                        emptyScene: EmptyScene.favorite,
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
