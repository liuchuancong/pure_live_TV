import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/hot/hot_provider.dart';

class HotPage extends ConsumerStatefulWidget {
  const HotPage({super.key});

  @override
  ConsumerState<HotPage> createState() => _HotPageState();
}

class _HotPageState extends ConsumerState<HotPage> {
  final Map<String, PagingParam<LiveRoom>> _pagingParamsCache = {};

  PagingParam<LiveRoom> _getOrCreateParam(String siteId) {
    if (_pagingParamsCache.containsKey(siteId)) {
      return _pagingParamsCache[siteId]!;
    }

    final liveSite = Sites.of(siteId).liveSite;
    final PagingParam<LiveRoom> param;

    if (siteId == Sites.kuaishouSite) {
      param = PagingParam<LiveRoom>(
        mode: PagingMode.serverAll,
        pageSize: 12,
        fetchAll: () async => await liveSite.getRecommendRooms(page: 1, pageSize: 999),
      );
    } else if (siteId == Sites.douyuSite || siteId == Sites.huyaSite || siteId == Sites.douyinSite) {
      int fixedSize = siteId == Sites.douyuSite ? 40 : (siteId == Sites.huyaSite ? 120 : 20);
      param = PagingParam<LiveRoom>(
        mode: PagingMode.serverFixedSize,
        pageSize: 12,
        fixedServerSize: fixedSize,
        fetchFixed: (bigPage, size) async => await liveSite.getRecommendRooms(page: bigPage, pageSize: size),
        keepAlive: true,
      );
    } else {
      param = PagingParam<LiveRoom>(
        mode: PagingMode.serverRemote,
        pageSize: 12,
        fetchRemote: (page, size) async => await liveSite.getRecommendRooms(page: page, pageSize: size),
        keepAlive: true,
      );
    }

    _pagingParamsCache[siteId] = param;
    return param;
  }

  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final tabsState = ref.watch(hotTabsProvider);

    if (tabsState.sites.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<TvTabItemData> tabItems = tabsState.sites.map(TvTabItemData.site).toList();

    final currentSite = tabsState.sites[tabsState.currentIndex];
    final currentParam = _getOrCreateParam(currentSite.id);

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
                    tabs: tabItems,
                    currentIndex: tabsState.currentIndex,
                    onTabChange: (index) {
                      ref.read(hotTabsProvider.notifier).changeTab(index);
                    },
                    onTabRefresh: (index) {
                      ref.read(pagingCoreProvider(currentParam).notifier).refresh();
                    },
                  ),
                  SizedBox(height: 16.sp),
                  Expanded(
                    child: TvTabView(
                      memoryKey: "hot_tab_view_content_${tabsState.currentIndex}",
                      verticalEdge: DpadEdgeBehavior.leave,
                      horizontalEdge: DpadEdgeBehavior.stop,
                      child: BasePagedTvView<LiveRoom>(
                        key: ValueKey('hot_site_${currentSite.id}'),
                        param: currentParam,
                        getNotifier: () => ref.read(pagingCoreProvider(currentParam).notifier),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 4,
                          mainAxisSpacing: 32.sp,
                          crossAxisSpacing: 32.sp,
                          childAspectRatio: 1.3,
                        ),
                        itemBuilder: (context, room, index) => TvRoomCard(
                          room: room,
                          onLongPress: () => FavOperateUtil.toggleRoomFollowDialog(context, room),
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
