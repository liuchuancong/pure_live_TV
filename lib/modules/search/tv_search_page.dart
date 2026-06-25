import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/widgets/tv_tab_bar.dart';
import 'package:pure_live/widgets/tv_tab_view.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/widgets/tv_room_card.dart';
import 'package:pure_live/pagination/pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/widgets/tv_qwer_keyboard.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/modules/search/tv_search_provider.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvSearchPage extends ConsumerStatefulWidget {
  const TvSearchPage({super.key});

  @override
  ConsumerState<TvSearchPage> createState() => _TvSearchPageState();
}

class _TvSearchPageState extends ConsumerState<TvSearchPage> {
  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final searchState = ref.watch(tvSearchNotifierProvider);

    final currentParam = PagingParam<LiveRoom>(
      mode: PagingMode.localReactive,
      pageSize: 12,
      keepAlive: false,
      fetchAll: () async => searchState.searchResults,
      localRefresh: () async {},
    );

    final availableSitesList = Sites().availableSites(containsAll: false);
    final List<TvTabItemData> siteTabs = availableSitesList.map((site) {
      return TvTabItemData(title: site.name);
    }).toList();

    return TvScaffold(
      child: Container(
        color: currentTvTheme.backgroundColor,
        padding: EdgeInsets.all(24.sp),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 320.sp,
              margin: EdgeInsets.only(right: 24.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 56.sp,
                    padding: EdgeInsets.symmetric(horizontal: 16.sp),
                    decoration: BoxDecoration(
                      color: currentTvTheme.cardColor,
                      borderRadius: BorderRadius.circular(16.sp),
                    ),
                    alignment: Alignment.centerLeft,
                    child: Text(
                      searchState.keyword.isEmpty ? '请输入简拼/数字' : searchState.keyword,
                      style: TextStyle(
                        color: searchState.keyword.isEmpty
                            ? currentTvTheme.secondaryTextColor
                            : currentTvTheme.primaryTextColor,
                        fontSize: 22.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 20.sp),
                  Expanded(
                    child: SingleChildScrollView(
                      child: TvQwerKeyboard(
                        onKeyTap: (char) => ref.read(tvSearchNotifierProvider.notifier).appendChar(char),
                        onDeleteTap: () => ref.read(tvSearchNotifierProvider.notifier).deleteChar(),
                        onClearTap: () => ref.read(tvSearchNotifierProvider.notifier).clearKeyword(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvTabBar(
                    tabs: siteTabs,
                    currentIndex: searchState.tabSiteIndex,
                    onTabChange: (index) {
                      ref.read(tvSearchNotifierProvider.notifier).changeSiteTab(index);
                    },
                  ),
                  SizedBox(height: 20.sp),
                  Expanded(
                    child: TvTabView(
                      memoryKey:
                          "tv_search_view_${searchState.tabSiteIndex}_${searchState.keyword}_${searchState.searchResults.length}",
                      verticalEdge: DpadEdgeBehavior.leave,
                      horizontalEdge: DpadEdgeBehavior.stop,
                      child: BasePagedTvView<LiveRoom>(
                        key: ValueKey(
                          'search_grid_${searchState.tabSiteIndex}_${searchState.keyword}_${searchState.searchResults.length}',
                        ),
                        param: currentParam,
                        getNotifier: () => ref.read(pagingCoreProvider(currentParam).notifier),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 24.sp,
                          crossAxisSpacing: 24.sp,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, room, index) => TvRoomCard(room: room, onLongPress: () {}, onTap: () {}),
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
