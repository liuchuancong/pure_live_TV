import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart';
import 'package:pure_live/utils/text_util.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:pure_live/widgets/tv_tab_bar.dart';
import 'package:pure_live/widgets/tv_tab_view.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/hot/hot_provider.dart';
import 'package:pure_live/modules/hot/hot_all_provider.dart';
import 'package:pure_live/pagination/base_paged_tv_view.dart';
import 'package:pure_live/modules/hot/hot_fixed_provider.dart';
import 'package:pure_live/modules/hot/hot_local_provider.dart';
import 'package:pure_live/modules/hot/hot_remote_provider.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/pagination/models/base_paged_state.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class HotPage extends ConsumerStatefulWidget {
  const HotPage({super.key});

  @override
  ConsumerState<HotPage> createState() => _HotPageState();
}

class _HotPageState extends ConsumerState<HotPage> {
  final Map<int, bool> _activatedTabs = {};

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
                          if (!isActivated) {
                            return const SizedBox.shrink();
                          }
                          return HotPlatformGridBridge(site: tabsState.sites[tabIndex]);
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
  ConsumerState<HotPlatformGridBridge> createState() => _HotPlatformGridBridgeState();
}

class _HotPlatformGridBridgeState extends ConsumerState<HotPlatformGridBridge> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.site.id == Sites.iptvSite) {
        ref.read(hotLocalProvider(widget.site.id).notifier).loadFirstTime();
      } else if (widget.site.id == Sites.kuaishouSite) {
        ref.read(hotAllProvider(widget.site.id).notifier).loadFirstTime();
      } else if (widget.site.id == Sites.douyuSite ||
          widget.site.id == Sites.huyaSite ||
          widget.site.id == Sites.douyinSite) {
        ref.read(hotFixedProvider(widget.site.id).notifier).loadFirstTime();
      } else {
        ref.read(hotRemoteProvider(widget.site.id).notifier).loadFirstTime();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.site.id == Sites.iptvSite) {
      final provider = hotLocalProvider(widget.site.id);
      return _buildRealPagedGrid(provider, ref.read(provider.notifier));
    }

    if (widget.site.id == Sites.kuaishouSite) {
      final provider = hotAllProvider(widget.site.id);
      return _buildRealPagedGrid(provider, ref.read(provider.notifier));
    }

    if (widget.site.id == Sites.douyuSite || widget.site.id == Sites.huyaSite || widget.site.id == Sites.douyinSite) {
      final provider = hotFixedProvider(widget.site.id);
      return _buildRealPagedGrid(provider, ref.read(provider.notifier));
    }

    final provider = hotRemoteProvider(widget.site.id);
    return _buildRealPagedGrid(provider, ref.read(provider.notifier));
  }

  Widget _buildRealPagedGrid(ProviderBase<BasePagedState<LiveRoom>> provider, dynamic notifier) {
    return BasePagedTvView<LiveRoom>(
      provider: provider,
      notifier: notifier,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16.sp,
        crossAxisSpacing: 16.sp,
        childAspectRatio: 1.3,
      ),
      itemBuilder: (context, room, index) {
        return _buildLiveCard(room);
      },
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
