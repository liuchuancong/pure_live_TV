import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/areas/area_grid_view.dart';
import 'package:pure_live/features/areas/category_provider.dart';
import 'package:pure_live/features/areas/platform_provider.dart';

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

    final List<TvTabItemData> tabItems = platformState.siteList.map(TvTabItemData.site).toList();

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
      loading: () => const Center(child: AppStatusView(type: AppStatusType.loading)),
      error: (err, stack) => Center(
        child: AppStatusView(
          type: AppStatusType.error,
          title: i18n('load_failed'),
          subtitle: '$err',
          icon: Remix.error_warning_line,
        ),
      ),
      data: (categories) {
        if (categories.isEmpty) {
          return Center(
            child: AppStatusView(
              type: AppStatusType.empty,
              title: i18n('area_no_category_data'),
              subtitle: "",
              icon: Remix.apps_2_line,
            ),
          );
        }

        final List<String> labels = categories.map((e) => e.name).toList();
        final List<List<LiveArea>> areaList = categories.map((e) => e.children).toList();
        return AreaGridView(labels: labels, areas: areaList);
      },
    );
  }
}
