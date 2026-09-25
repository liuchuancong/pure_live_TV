import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/areas/platform_provider.dart';
import 'package:pure_live/features/areas/category_provider.dart';
import 'package:pure_live/app/router/router.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class AreaGridView extends ConsumerStatefulWidget {
  final List<String> labels;
  final List<List<LiveArea>> areas;

  /// Flat mode: the whole site renders one list ([labels]/[areas] each carry a
  /// single entry with an empty label) and no sub-category tab bar.
  final bool flat;

  const AreaGridView({super.key, required this.labels, required this.areas, this.flat = false});

  @override
  ConsumerState<AreaGridView> createState() => _AreaGridViewState();
}

class _AreaGridViewState extends ConsumerState<AreaGridView> {
  late List<PagingParam<LiveArea>> _pagingParams;

  @override
  void initState() {
    super.initState();
    _initPagingParams();
  }

  @override
  void didUpdateWidget(covariant AreaGridView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.labels != oldWidget.labels || widget.areas != oldWidget.areas) {
      _initPagingParams();
    }
  }

  void _initPagingParams() {
    _pagingParams = List.generate(widget.labels.length, (subIndex) {
      final currentSubAreas = widget.areas.isNotEmpty && subIndex < widget.areas.length
          ? widget.areas[subIndex]
          : <LiveArea>[];

      return PagingParam<LiveArea>(
        mode: PagingMode.serverAll,
        pageSize: 12,
        keepAlive: true,
        fetchAll: () async => currentSubAreas,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentCategoryIndex = ref.watch(categoryTabProvider);
    final platformState = ref.watch(platformTabProvider);
    final currentSite = platformState.siteList[platformState.currentPlatformIndex];
    if (widget.labels.isEmpty || currentCategoryIndex >= widget.labels.length) {
      return const SizedBox.shrink();
    }

    final List<TvTabItemData> secondTabItems = widget.labels.map((name) {
      return TvTabItemData(title: name);
    }).toList();

    final currentParam = _pagingParams[currentCategoryIndex];
    // column/row spacing are an offset from the 6.0 design default, so the untouched
    // default reproduces the original 32 design-pixel gap.
    final themeState = ref.watch(themeSettingsControllerProvider);
    final double crossSpacing = themeState.crossAxisSpacing;
    final double mainSpacing = themeState.mainAxisSpacing;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labels.isNotEmpty && !widget.flat)
          TvTabBar(
            tabs: secondTabItems,
            currentIndex: currentCategoryIndex,
            onTabChange: (index) {
              ref.read(categoryTabProvider.notifier).switchCategory(index);
            },
            // Local reload: the platform's catalogue was fetched whole, so this
            // re-slices the categories already in memory — the bar's own line
            // covers its minimum visible time. The catalogue reload itself is not
            // reflected here: that one shows on the platform bar above, and one
            // refresh lights one line.
            onTabRefresh: (index) => ref.read(pagingCoreProvider(currentParam).notifier).refresh(),
          ),
        SizedBox(height: 20.sp),
        Expanded(
          child: TvTabView(
            memoryKey: widget.flat ? "areas_flat_view" : "areas_sub_category_view_$currentCategoryIndex",
            verticalEdge: DpadEdgeBehavior.leave,
            horizontalEdge: DpadEdgeBehavior.stop,
            child: BasePagedTvView<LiveArea>(
              key: ValueKey('page_$currentCategoryIndex'),
              param: currentParam,
              getNotifier: () => ref.read(pagingCoreProvider(currentParam).notifier),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: mainSpacing.w,
                crossAxisSpacing: crossSpacing.w,
                childAspectRatio: 1.3,
              ),
              itemBuilder: (context, area, index) => TvAreaCard(
                area: area,
                onTap: () {
                  context.pushPage(
                    AppRoutes.kAreaRooms,
                    extra: AreaRoomsArgs(site: currentSite, subCategory: area),
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
    );
  }
}
