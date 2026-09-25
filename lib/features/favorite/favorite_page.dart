import 'dart:developer';
import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/features/favorite/favorite_provider.dart';
import 'package:pure_live/features/favorite/model/favorite_state.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class FavoritePage extends ConsumerStatefulWidget {
  const FavoritePage({super.key});

  @override
  ConsumerState<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends ConsumerState<FavoritePage> with RouteAware {
  /// One grid's identity inside this page: the status tab, platform tab and tag
  /// its paging core holds, plus the core itself.
  ///
  /// PagingParam identity is the paging family key: constructing a fresh one
  /// per build (closures compare by identity) tore down the PagingCore,
  /// refetched and reset the grid to page 1 on every unrelated rebuild — the
  /// spacing sliders, any settings toggle, every favourite emission.
  final Map<String, ({_FavoriteGridSpec spec, PagingParam<LiveRoom> param})> _grids = {};

  bool _poolPushScheduled = false;

  PagingParam<LiveRoom> _getOrCreateParam(_FavoriteGridSpec spec) {
    return _grids
        .putIfAbsent(
          spec.key,
          () => (
            spec: spec,
            param: PagingParam<LiveRoom>(
              mode: PagingMode.localReactive,
              pageSize: 12,
              keepAlive: false,
              // The slice is asked for by this grid's own tab/platform/tag, so a
              // re-slice can never fill an off-screen grid with another
              // platform's rooms.
              fetchAll: () async => ref
                  .read(favoriteProvider.notifier)
                  .roomsFor(tabIndex: spec.tabIndex, siteId: spec.siteId, tagId: spec.tagId),
              localRefresh: () async {},
            ),
          ),
        )
        .param;
  }

  /// Keeps every grid in step with the followed rooms.
  ///
  /// A grid's data lives in its own PagingCore, and a favourite change does not
  /// rebuild the view — its identity is only the tab/tag selection, so that
  /// following a room no longer throws away the focus and the scroll position.
  /// That also meant nothing told the cores the list had changed, so a room
  /// followed in the player only showed up after a tab switch or a restart.
  /// Pushing fresh slices into the cores keeps both: the grids update, the view
  /// is never torn down.
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

    final int globalTotal =
        favoriteState.onlineRooms.length + favoriteState.replayRooms.length + favoriteState.offlineRooms.length;
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
      _pushPoolToPagingCore();
    });
  }

  /// Re-slices the paging pools from the current favourite state.
  ///
  /// The room-detail write-back from an opened room lands while this page sits
  /// covered under the player route, and the pool then kept the visited card in
  /// its old status bucket (an offline room stayed under 直播中 after returning).
  /// This is called from three places, because any one of them can be silent:
  /// the favourite listener (which may not reach a covered page), [didPopNext]
  /// (which depends on the observer and on this page's own route) and the page's
  /// own build — a painted page has to show current data, whatever muted the
  /// other two.
  ///
  /// Every cached grid is re-aligned, not only the one on screen. They each have
  /// their own core, and a grid that is not the visible one kept the pool it was
  /// last given — so a card that changed status was still listed under its old
  /// group the moment the viewer switched to that tab.
  void _pushPoolToPagingCore() {
    if (_poolPushScheduled) return;
    _poolPushScheduled = true;
    // Provider writes during a build phase throw, so the push lands on the
    // next frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _poolPushScheduled = false;
      if (!mounted) return;

      // Reading the provider is what makes these slices current: a write-back
      // invalidated it, and `ref.read(provider.notifier)` does not recompute an
      // invalidated provider, so asking the notifier alone re-sliced from the
      // buckets as they were before the write-back.
      ref.read(favoriteProvider);

      final notifier = ref.read(favoriteProvider.notifier);
      final reAligned = <String>[];

      for (final grid in _grids.values) {
        final rooms = notifier.roomsFor(
          tabIndex: grid.spec.tabIndex,
          siteId: grid.spec.siteId,
          tagId: grid.spec.tagId,
        );

        final core = ref.read(pagingCoreProvider(grid.param));

        // A push resets the grid to its first page, so a grid that would render
        // the same cards is left exactly as it is - that is what keeps an
        // unrelated rebuild from throwing away the viewer's scroll position.
        if (_rendersSameCards(core.allLocalItems, rooms)) continue;

        ref.read(pagingCoreProvider(grid.param).notifier).updateLocalPool(rooms);
        reAligned.add('${grid.spec.key}=${rooms.length}');
      }

      if (reAligned.isNotEmpty) {
        log('grids re-aligned: ${reAligned.join(', ')}', name: 'FavoritePage');
      }
    });
  }

  /// Whether two slices would paint the same cards.
  ///
  /// [LiveRoom]'s own `==` compares identity alone, and a write-back can change a
  /// card's title, badge or audience without moving it between groups.
  static bool _rendersSameCards(List<LiveRoom> left, List<LiveRoom> right) {
    if (left.length != right.length) return false;

    for (var index = 0; index < left.length; index++) {
      final LiveRoom a = left[index];
      final LiveRoom b = right[index];

      if (a.identityKey != b.identityKey ||
          a.title != b.title ||
          a.nick != b.nick ||
          a.avatar != b.avatar ||
          a.cover != b.cover ||
          a.liveStatus != b.liveStatus ||
          a.isRecord != b.isRecord ||
          a.status != b.status ||
          a.watching != b.watching) {
        return false;
      }
    }

    return true;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ModalRoute<void>? route = ModalRoute.of(context);
    if (route != null) tvRouteObserver.subscribe(this, route);
  }

  @override
  void didPopNext() {
    // Returning from the player (or any pushed route): the write-back already
    // updated the favourite entries under cover, so re-align the grid now.
    _pushPoolToPagingCore();
  }

  @override
  void dispose() {
    tvRouteObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final favoriteState = ref.watch(favoriteProvider);
    // column/row spacing are an offset from the 6.0 design default, so the untouched
    // default reproduces the original 32 design-pixel gap.
    final themeState = ref.watch(themeSettingsControllerProvider);
    final double crossSpacing = themeState.crossAxisSpacing;
    final double mainSpacing = themeState.mainAxisSpacing;

    // The playlist mirrors the page's source: live, then replay, then offline,
    // scoped to the platform tab — so up/down walks the same groups the page
    // shows instead of only the live slice.
    final favorites = ref.read(favoriteProvider.notifier);
    final liveRooms = favorites.getPlaylistRooms();

    final currentParam = _getOrCreateParam(
      _FavoriteGridSpec(
        tabIndex: favoriteState.tabOnlineIndex,
        siteId: favorites.activeSiteId,
        tagId: favoriteState.selectedTagId,
      ),
    );
    _listenToFavoriteChanges();

    // Third trigger, and the one that cannot be muted: a page that is being
    // painted must show the rooms as they are now. The push is idempotent and
    // leaves grids whose cards did not change alone, so it costs a comparison.
    _pushPoolToPagingCore();

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
                  // Both bars refresh the same list, so only the one above the
                  // grid carries the line: pressing this one still reloads, the
                  // line just shows up next to the list instead of lighting a
                  // second one here.
                  showRefreshLine: false,
                  onTabChange: (index) {
                    ref.read(favoriteProvider.notifier).changeOnlineTab(index);
                  },
                  onTabRefresh: (index) => ref.read(favoriteProvider.notifier).refreshData(),
                ),
                SizedBox(height: 12.sp),
                TvTabBar(
                  tabs: siteTabs,
                  currentIndex: favoriteState.tabSiteIndex,
                  // The provider's own flag, not only the double press: the
                  // auto-refresh timer, an import's verification pass and the
                  // empty state's retry all revalidate the same rooms, and the
                  // line belongs on the bar in every one of those cases.
                  refreshing: favoriteState.isLoading,
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
                      // search action next to the refresh one); EmptyScene.favorite stays as
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
                        index: index,
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

/// Which slice one grid of the favourites page holds.
///
/// The page keeps a paging core per combination (status tab × platform tab ×
/// tag), and this is what identifies one: it keys the cache and it is what a
/// re-slice asks the notifier for, so a grid is always filled from its own
/// slice rather than from whichever one the page happens to be showing.
class _FavoriteGridSpec {
  const _FavoriteGridSpec({required this.tabIndex, required this.siteId, required this.tagId});

  final int tabIndex;
  final String siteId;
  final String tagId;

  String get key => 'fav_${tabIndex}_${siteId}_$tagId';
}
