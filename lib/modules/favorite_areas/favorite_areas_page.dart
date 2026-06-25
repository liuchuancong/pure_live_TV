import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/widgets/tv_tab_bar.dart';
import 'package:pure_live/widgets/tv_tab_view.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/widgets/tv_area_card.dart';
import 'package:pure_live/pagination/pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/core/models/live_area/live_area.dart';
import 'package:pure_live/core/utils/favorite_operation_util.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/favorite_areas/favorite_areas_provider.dart';

class FavoriteAreasPage extends ConsumerStatefulWidget {
  const FavoriteAreasPage({super.key});

  @override
  ConsumerState<FavoriteAreasPage> createState() => _FavoriteAreasPageState();
}

class _FavoriteAreasPageState extends ConsumerState<FavoriteAreasPage> {
  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final areasState = ref.watch(favoriteAreasProvider);
    final currentAreas = areasState.areas;

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
                    tabs: siteTabs,
                    currentIndex: areasState.tabSiteIndex,
                    onTabChange: (index) {
                      ref.read(favoriteAreasProvider.notifier).changeSiteTab(index);
                    },
                  ),
                  SizedBox(height: 16.sp),
                  Expanded(
                    child: TvTabView(
                      memoryKey: "fav_areas_tv_view_${areasState.tabSiteIndex}_${currentAreas.length}",
                      verticalEdge: DpadEdgeBehavior.leave,
                      horizontalEdge: DpadEdgeBehavior.stop,
                      child: BasePagedTvView<LiveArea>(
                        key: ValueKey('fav_areas_grid_${areasState.tabSiteIndex}_${currentAreas.length}'),
                        param: currentParam,
                        getNotifier: () => ref.read(pagingCoreProvider(currentParam).notifier),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 8,
                          mainAxisSpacing: 32.sp,
                          crossAxisSpacing: 32.sp,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, area, index) => TvAreaCard(
                          area: area,
                          onTap: () {},
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
      ),
    );
  }
}
