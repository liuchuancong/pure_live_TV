import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/utils/text_util.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:pure_live/widgets/tv_tab_bar.dart';
import 'package:pure_live/widgets/tv_tab_view.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:pure_live/pagination/pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/hot/hot_provider.dart';
import 'package:pure_live/core/sites/interface/live_site.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class HotPage extends ConsumerStatefulWidget {
  const HotPage({super.key});

  @override
  ConsumerState<HotPage> createState() => _HotPageState();
}

class _HotPageState extends ConsumerState<HotPage> {
  final Map<int, bool> _activatedTabs = {};
  final Map<int, GlobalKey<HotPlatformGridBridgeState>> _bridgeKeys = {};
  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final tabsState = ref.watch(hotTabsProvider);

    if (tabsState.sites.isEmpty) {
      return const SizedBox.shrink();
    }

    _activatedTabs[tabsState.currentIndex] = true;

    final List<TvTabItemData> tabItems = tabsState.sites.map((site) {
      return TvTabItemData(
        title: site.name,
        icon: Image.asset(site.logo, width: 24.sp, height: 24.sp, fit: BoxFit.contain),
      );
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
                    tabs: tabItems,
                    currentIndex: tabsState.currentIndex,
                    onTabChange: (index) {
                      ref.read(hotTabsProvider.notifier).changeTab(index);
                    },
                    onTabRefresh: (index) => _bridgeKeys[index]?.currentState?.triggerRefreshFromOuter(),
                  ),
                  SizedBox(height: 16.sp),
                  Expanded(
                    child: TvTabView(
                      memoryKey: "hot_tab_view_content",
                      verticalEdge: DpadEdgeBehavior.leave,
                      horizontalEdge: DpadEdgeBehavior.stop,
                      child: IndexedStack(
                        index: tabsState.currentIndex,
                        children: List.generate(tabsState.sites.length, (tabIndex) {
                          final isActivated = _activatedTabs[tabIndex] ?? false;
                          final childKey = _bridgeKeys.putIfAbsent(
                            tabIndex,
                            () => GlobalKey<HotPlatformGridBridgeState>(),
                          );
                          if (!isActivated) {
                            return const SizedBox.shrink();
                          }
                          return HotPlatformGridBridge(key: childKey, site: tabsState.sites[tabIndex]);
                        }),
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

class HotPlatformGridBridge extends ConsumerStatefulWidget {
  final Site site;
  const HotPlatformGridBridge({super.key, required this.site});

  @override
  ConsumerState<HotPlatformGridBridge> createState() => HotPlatformGridBridgeState();
}

class HotPlatformGridBridgeState extends ConsumerState<HotPlatformGridBridge> {
  late final LiveSite site;
  late final PagingParam<LiveRoom> _param;

  @override
  void initState() {
    super.initState();
    site = Sites.of(widget.site.id).liveSite;
    _param = _createParam();
  }

  Future<List<LiveRoom>> _fetchAllRooms() async {
    return await site.getRecommendRooms(page: 1, pageSize: 999);
  }

  Future<List<LiveRoom>> _fetchFixedRooms(int bigPage, int size) async {
    return await site.getRecommendRooms(page: bigPage, pageSize: size);
  }

  Future<List<LiveRoom>> _fetchRemoteRooms(int page, int size) async {
    return await site.getRecommendRooms(page: page, pageSize: size);
  }

  void triggerRefreshFromOuter() {
    ref.read(pagingCoreProvider(_param).notifier).refresh();
  }

  PagingParam<LiveRoom> _createParam() {
    final String siteId = widget.site.id;
    if (siteId == Sites.kuaishouSite) {
      return PagingParam<LiveRoom>(mode: PagingMode.serverAll, pageSize: 12, fetchAll: _fetchAllRooms);
    } else if (siteId == Sites.douyuSite || siteId == Sites.huyaSite || siteId == Sites.douyinSite) {
      int fixedSize = siteId == Sites.douyuSite ? 40 : (siteId == Sites.huyaSite ? 120 : 20);
      return PagingParam<LiveRoom>(
        mode: PagingMode.serverFixedSize,
        pageSize: 12,
        fixedServerSize: fixedSize,
        fetchFixed: _fetchFixedRooms,
        keepAlive: true,
      );
    } else {
      return PagingParam<LiveRoom>(
        mode: PagingMode.serverRemote,
        pageSize: 12,
        fetchRemote: _fetchRemoteRooms,
        keepAlive: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BasePagedTvView<LiveRoom>(
      param: _param,
      getNotifier: () => ref.read(pagingCoreProvider(_param).notifier),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16.sp,
        crossAxisSpacing: 16.sp,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, room, index) => _buildLiveCard(room),
    );
  }

  Widget _buildLiveCard(LiveRoom room) {
    final currentTvTheme = context.tvTheme;
    return TvButton(
      title: "",
      size: TvButtonSize.large,
      onTap: () {},
      icon: Container(
        padding: EdgeInsets.all(8.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: currentTvTheme.cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8.sp),
                ),
                child: CachedNetworkImage(
                  imageUrl: room.cover,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  placeholder: (context, url) => Center(
                    child: Icon(Icons.play_circle_outline, size: 36.sp, color: currentTvTheme.secondaryTextColor),
                  ),
                  errorWidget: (context, url, error) => Center(
                    child: Icon(Icons.broken_image_outlined, size: 36.sp, color: currentTvTheme.secondaryTextColor),
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              room.title,
              style: AppTextStyles.t16W500.copyWith(color: currentTvTheme.primaryTextColor),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Row(
              children: [
                Expanded(
                  child: Text(
                    room.nick,
                    style: AppTextStyles.t14.copyWith(color: currentTvTheme.secondaryTextColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(readableCount(room.watching), style: AppTextStyles.t14.copyWith(color: currentTvTheme.focusColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
