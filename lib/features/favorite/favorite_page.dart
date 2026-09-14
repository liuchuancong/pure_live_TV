import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/favorite/favorite_provider.dart';

class FavoritePage extends ConsumerStatefulWidget {
  const FavoritePage({super.key});

  @override
  ConsumerState<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends ConsumerState<FavoritePage> {
  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final favoriteState = ref.watch(favoriteProvider);

    final currentRooms = ref.read(favoriteProvider.notifier).getFilteredRooms();

    final currentParam = PagingParam<LiveRoom>(
      mode: PagingMode.localReactive,
      pageSize: 12,
      keepAlive: false,
      fetchAll: () async {
        return ref.read(favoriteProvider.notifier).getFilteredRooms();
      },
      localRefresh: () async {},
    );

    final List<TvTabItemData> statusTabs = [
      TvTabItemData(title: i18n('live')),
      TvTabItemData(title: i18n('ui_replaying')),
      TvTabItemData(title: i18n('offline_room_title')),
    ];

    final availableSitesList = Sites().availableSites(containsAll: true);
    final List<TvTabItemData> siteTabs = availableSitesList.map((site) {
      return TvTabItemData(title: site.name);
    }).toList();

    return TvScaffold(
      child: Container(
        color: currentTvTheme.backgroundColor,
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
                      memoryKey:
                          "fav_tv_view_${favoriteState.tabOnlineIndex}_${favoriteState.tabSiteIndex}_${favoriteState.selectedTagId}_${currentRooms.length}",
                      verticalEdge: DpadEdgeBehavior.leave,
                      horizontalEdge: DpadEdgeBehavior.stop,
                      child: BasePagedTvView<LiveRoom>(
                        key: ValueKey(
                          'fav_grid_${favoriteState.tabOnlineIndex}_${favoriteState.tabSiteIndex}_${favoriteState.selectedTagId}_${currentRooms.length}',
                        ),
                        param: currentParam,
                        getNotifier: () => ref.read(pagingCoreProvider(currentParam).notifier),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: favoriteState.denseLayout ? 5 : 4,
                          mainAxisSpacing: 32.sp,
                          crossAxisSpacing: 32.sp,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, room, index) => TvRoomCard(
                          room: room,
                          playlist: currentRooms,
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
      ),
    );
  }
}
