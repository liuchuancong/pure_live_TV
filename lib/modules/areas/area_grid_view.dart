import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/routes/router.dart';
import 'package:pure_live/widgets/index.dart';
import 'package:pure_live/pagination/pagination.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/areas/platform_provider.dart';
import 'package:pure_live/core/models/live_area/live_area.dart';
import 'package:pure_live/modules/areas/category_provider.dart';
import 'package:pure_live/core/utils/favorite_operation_util.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class AreaGridView extends ConsumerStatefulWidget {
  final List<String> labels;
  final List<List<LiveArea>> areas;

  const AreaGridView({super.key, required this.labels, required this.areas});

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.labels.isNotEmpty)
          TvTabBar(
            tabs: secondTabItems,
            currentIndex: currentCategoryIndex,
            onTabChange: (index) {
              ref.read(categoryTabProvider.notifier).switchCategory(index);
            },
            onTabRefresh: (index) {
              ref.read(pagingCoreProvider(currentParam).notifier).refresh();
            },
          ),
        SizedBox(height: 20.sp),
        Expanded(
          child: TvTabView(
            memoryKey: "areas_sub_category_view_$currentCategoryIndex",
            verticalEdge: DpadEdgeBehavior.leave,
            horizontalEdge: DpadEdgeBehavior.stop,
            child: BasePagedTvView<LiveArea>(
              key: ValueKey('page_$currentCategoryIndex'),
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
