import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/favorite/favorite_provider.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

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
    // 列间距/行间距 are an offset from the 6.0 design default, so the untouched
    // default reproduces the original 32 design-pixel gap.
    final themeState = ref.watch(themeSettingsControllerProvider);
    final double crossSpacing = 32 + themeState.crossAxisSpacing - ThemeSettingsController.defaultSpacing;
    final double mainSpacing = 32 + themeState.mainAxisSpacing - ThemeSettingsController.defaultSpacing;

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
    final List<TvTabItemData> siteTabs = availableSitesList.map(TvTabItemData.site).toList();

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
                      // Identity is the tab/tag selection only. Including the
                      // room count here meant that following or unfollowing a
                      // single room rebuilt the view and dropped both the focus
                      // memory and the scroll position the user was on.
                      memoryKey: "fav_tv_view_${favoriteState.tabOnlineIndex}_${favoriteState.tabSiteIndex}_${favoriteState.selectedTagId}",
                      verticalEdge: DpadEdgeBehavior.leave,
                      horizontalEdge: DpadEdgeBehavior.stop,
                      child: BasePagedTvView<LiveRoom>(
                        key: ValueKey(
                          'fav_grid_${favoriteState.tabOnlineIndex}_${favoriteState.tabSiteIndex}_${favoriteState.selectedTagId}',
                        ),
                        param: currentParam,
                        getNotifier: () => ref.read(pagingCoreProvider(currentParam).notifier),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: favoriteState.denseLayout ? 5 : 4,
                          mainAxisSpacing: mainSpacing.w,
                          crossAxisSpacing: crossSpacing.w,
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
