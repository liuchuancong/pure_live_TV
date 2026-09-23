import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/app/router/router.dart';
import 'package:pure_live/features/favorite_areas/favorite_areas_provider.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class FavoriteAreasPage extends ConsumerStatefulWidget {
  const FavoriteAreasPage({super.key});

  @override
  ConsumerState<FavoriteAreasPage> createState() => _FavoriteAreasPageState();
}

class _FavoriteAreasPageState extends ConsumerState<FavoriteAreasPage> {
  @override
  Widget build(BuildContext context) {
    final areasState = ref.watch(favoriteAreasProvider);
    // column/row spacing are an offset from the 6.0 design default, so the untouched
    // default reproduces the original 32 design-pixel gap.
    final themeState = ref.watch(themeSettingsControllerProvider);
    final double crossSpacing = themeState.crossAxisSpacing;
    final double mainSpacing = themeState.mainAxisSpacing;

    final currentParam = PagingParam<LiveArea>(
      mode: PagingMode.localReactive,
      pageSize: 12,
      keepAlive: false,
      fetchAll: () async {
        return ref.read(favoriteAreasProvider).areas;
      },
      localRefresh: () async {},
    );

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
                    tabs: siteTabs,
                    currentIndex: areasState.tabSiteIndex,
                    onTabChange: (index) {
                      ref.read(favoriteAreasProvider.notifier).changeSiteTab(index);
                    },
                    // OK twice on a tab refetches it.
                    onTabRefresh: (index) => ref.read(pagingCoreProvider(currentParam).notifier).refresh(),
                  ),
                  SizedBox(height: 16.sp),
                  Expanded(
                    child: TvTabView(
                      // Stable identity: the area count used to be part of the
                      // key, so following or unfollowing one category rebuilt
                      // the view and reset focus and scroll position.
                      memoryKey: "fav_areas_tv_view_${areasState.tabSiteIndex}",
                      verticalEdge: DpadEdgeBehavior.leave,
                      horizontalEdge: DpadEdgeBehavior.stop,
                      child: BasePagedTvView<LiveArea>(
                        key: ValueKey('fav_areas_grid_${areasState.tabSiteIndex}'),
                        param: currentParam,
                        getNotifier: () => ref.read(pagingCoreProvider(currentParam).notifier),
                        emptyScene: EmptyScene.favoriteAreas,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          mainAxisSpacing: mainSpacing.w,
                          crossAxisSpacing: crossSpacing.w,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, area, index) => TvAreaCard(
                          area: area,
                          // A followed category is a shortcut into the same room
                          // list the 分区 tab opens: pressing OK used to do
                          // nothing here, so the page was a dead end. The
                          // category carries its own platform, which is what the
                          // "全部" tab needs (the grid then spans platforms).
                          onTap: () {
                            context.pushPage(
                              AppRoutes.kAreaRooms,
                              extra: AreaRoomsArgs(site: Sites.of(area.platform), subCategory: area),
                            );
                          },
                          onLongPress: () {
                            FavOperateUtil.toggleAreaFollowDialog(context, area);
                          },
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
