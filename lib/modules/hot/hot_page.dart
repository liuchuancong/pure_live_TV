import 'hot_provider.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/widgets/index.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class HotPage extends ConsumerStatefulWidget {
  const HotPage({super.key});

  @override
  ConsumerState<HotPage> createState() => _HotPageState();
}

class _HotPageState extends ConsumerState<HotPage> {
  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final tabsState = ref.watch(hotTabsProvider);

    if (tabsState.sites.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<TvTabItemData> tabItems = tabsState.sites.map((site) {
      return TvTabItemData(
        title: site.name,
        icon: Image.asset(site.logo, width: 30.sp, height: 30.sp, fit: BoxFit.contain),
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
                        children: List.generate(
                          tabsState.sites.length,
                          (tabIndex) => _buildLiveGrid(tabsState.sites[tabIndex]),
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

  Widget _buildLiveGrid(Site site) {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16.sp,
        crossAxisSpacing: 16.sp,
        childAspectRatio: 1.3,
      ),
      itemCount: 12,
      itemBuilder: (context, index) {
        return _buildLiveCard("${site.name} 直播间 $index");
      },
    );
  }

  Widget _buildLiveCard(String roomName) {
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
                decoration: BoxDecoration(
                  color: currentTvTheme.cardColor.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8.sp),
                ),
                child: Center(
                  child: Icon(Icons.play_circle_outline, size: 36.sp, color: currentTvTheme.secondaryTextColor),
                ),
              ),
            ),
            SizedBox(height: 8.sp),
            Text(
              roomName,
              style: TextStyle(fontSize: 16.sp, color: currentTvTheme.primaryTextColor, fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              "主播昵称",
              style: TextStyle(fontSize: 12.sp, color: currentTvTheme.secondaryTextColor),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
