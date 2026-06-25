import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/widgets/tv_tab_bar.dart';
import 'package:pure_live/widgets/tv_tab_view.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/areas/area_grid_view.dart';
import 'package:pure_live/core/models/live_area/live_area.dart';
import 'package:pure_live/modules/areas/category_provider.dart';
import 'package:pure_live/modules/areas/platform_provider.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class AreasPage extends ConsumerStatefulWidget {
  const AreasPage({super.key});

  @override
  ConsumerState<AreasPage> createState() => _AreasPageState();
}

class _AreasPageState extends ConsumerState<AreasPage> {
  @override
  Widget build(BuildContext context) {
    final platformState = ref.watch(platformTabProvider);
    if (platformState.siteList.isEmpty) {
      return const SizedBox.shrink();
    }

    final List<TvTabItemData> tabItems = platformState.siteList.map((site) {
      return TvTabItemData(
        title: site.name,
        icon: Image.asset(site.logo, width: 24.sp, height: 24.sp, fit: BoxFit.contain),
      );
    }).toList();

    final currentSite = platformState.siteList[platformState.currentPlatformIndex];

    return TvScaffold(
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TvTabBar(
                  tabs: tabItems,
                  currentIndex: platformState.currentPlatformIndex,
                  onTabChange: (index) {
                    ref.read(platformTabProvider.notifier).switchPlatform(index);
                  },
                ),
                SizedBox(height: 16.sp),
                Expanded(
                  child: TvTabView(
                    memoryKey: "areas_tab_view_content_${platformState.currentPlatformIndex}",
                    verticalEdge: DpadEdgeBehavior.leave,
                    horizontalEdge: DpadEdgeBehavior.stop,
                    child: AreasPlatformGridBridge(key: ValueKey('site_${currentSite.id}'), site: currentSite),
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

class AreasPlatformGridBridge extends ConsumerStatefulWidget {
  final Site site;
  const AreasPlatformGridBridge({super.key, required this.site});

  @override
  ConsumerState<AreasPlatformGridBridge> createState() => AreasPlatformGridBridgeState();
}

class AreasPlatformGridBridgeState extends ConsumerState<AreasPlatformGridBridge> {
  void triggerRefreshFromOuter() {
    ref.invalidate(getSiteCategoriesProvider(widget.site.id));
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(getSiteCategoriesProvider(widget.site.id));

    return categoriesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 3)),
      error: (err, stack) {
        return Center(
          child: Text("加载失败: $err", style: const TextStyle(color: Colors.redAccent)),
        );
      },
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(child: Text("该平台暂无分类数据"));
        }

        final List<String> labels = categories.map((e) => e.name).toList();
        final List<List<LiveArea>> areaList = categories.map((e) => e.children).toList();
        return AreaGridView(labels: labels, areas: areaList);
      },
    );
  }
}
