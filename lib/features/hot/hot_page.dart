import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/hot/hot_provider.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/app/router/app_router.dart';

class HotPage extends ConsumerStatefulWidget {
  const HotPage({super.key});

  @override
  ConsumerState<HotPage> createState() => _HotPageState();
}

class _HotPageState extends ConsumerState<HotPage> {
  final Map<String, PagingParam<LiveRoom>> _pagingParamsCache = {};

  /// The reference's popular-grid rule (`popular_grid_controller`): a
  /// recommend API answered with something other than JSON — risk control, a
  /// session gate — crashes the parser with a NoSuchMethodError. That crash,
  /// on *this platform's own* recommend fetch, means the platform hid its
  /// data behind a login and is reported as such; the rewrite lives here and
  /// not in the shared error classifier, so a parsing bug on any other page
  /// still reads as an ordinary error.
  Future<List<LiveRoom>> _fetchRecommend(LiveSite liveSite, {required int page, required int pageSize}) async {
    try {
      return await liveSite.getRecommendRooms(page: page, pageSize: pageSize);
    } catch (e) {
      if (e.toString().contains("NoSuchMethodError") && e.toString().contains("'[]'")) {
        throw Exception("loginRequired");
      }
      rethrow;
    }
  }

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
        fetchAll: () async => _fetchRecommend(liveSite, page: 1, pageSize: 999),
      );
    } else if (siteId == Sites.douyuSite || siteId == Sites.huyaSite || siteId == Sites.douyinSite) {
      int fixedSize = siteId == Sites.douyuSite ? 40 : (siteId == Sites.huyaSite ? 120 : 20);
      param = PagingParam<LiveRoom>(
        mode: PagingMode.serverFixedSize,
        pageSize: 12,
        fixedServerSize: fixedSize,
        fetchFixed: (bigPage, size) async => _fetchRecommend(liveSite, page: bigPage, pageSize: size),
        keepAlive: true,
      );
    } else {
      param = PagingParam<LiveRoom>(
        mode: PagingMode.serverRemote,
        pageSize: 12,
        fetchRemote: (page, size) async => _fetchRecommend(liveSite, page: page, pageSize: size),
        keepAlive: true,
      );
    }

    _pagingParamsCache[siteId] = param;
    return param;
  }

  @override
  Widget build(BuildContext context) {
    final tabsState = ref.watch(hotTabsProvider);

    if (tabsState.sites.isEmpty) {
      return const SizedBox.shrink();
    }

    // column/row spacing are an offset from the 6.0 design default, so the untouched
    // default reproduces the original 32 design-pixel gap.
    final themeState = ref.watch(themeSettingsControllerProvider);
    final double crossSpacing = themeState.crossAxisSpacing;
    final double mainSpacing = themeState.mainAxisSpacing;

    final List<TvTabItemData> tabItems = tabsState.sites.map(TvTabItemData.site).toList();

    final currentSite = tabsState.sites[tabsState.currentIndex];
    final currentParam = _getOrCreateParam(currentSite.id);

    // The rooms this tab has loaded so far. The player takes it as the up/down
    // channel list and fills the playlist panel with it, so a room opened from
    // the popular list switches within the popular list instead of falling back
    // to watch history.
    final List<LiveRoom> rooms = ref.watch(pagingCoreProvider(currentParam).select((state) => state.items));

    // What the bar's progress line follows: the core's own loading state, which
    // covers a refetch this page did not start (the empty state's retry, the
    // first load of a platform tab) as well as the double press on the bar.
    final bool refreshing = ref.watch(
      pagingCoreProvider(currentParam).select((state) => state.controllerState.pageLoading),
    );

    return TvScaffold(
      child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TvTabBar(
                    tabs: tabItems,
                    currentIndex: tabsState.currentIndex,
                    refreshing: refreshing,
                    onTabChange: (index) {
                      ref.read(hotTabsProvider.notifier).changeTab(index);
                    },
                    // The returned future keeps the bar's progress line up for as
                    // long as the refetch runs.
                    onTabRefresh: (index) => ref.read(pagingCoreProvider(currentParam).notifier).refresh(),
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
                        emptyScene: EmptyScene.hot,
                        onGoLogin: () => const AccountSettingsRoute().push(context),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: themeState.denseRoomLayout,
                          mainAxisSpacing: mainSpacing.w,
                          crossAxisSpacing: crossSpacing.w,
                          childAspectRatio: ThemeSettingsController.roomCardAspectRatio(themeState.denseRoomLayout),
                        ),
                        itemBuilder: (context, room, index) => TvRoomCard(
                          room: room,
                          index: index,
                          playlist: rooms,
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
    );
  }
}
