import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class FavoritePage extends GetView<FavoriteController> {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      bool showAction = constraint.maxWidth <= 680;
      return Scaffold(
        appBar: AppBar(
          centerTitle: true,
          scrolledUnderElevation: 0,
          leading: showAction ? const MenuButton() : null,
          actions: showAction ? [const SearchButton()] : null,
          title: TabBar(
            controller: controller.tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.center,
            labelStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            labelPadding: const EdgeInsets.symmetric(horizontal: 12),
            indicatorSize: TabBarIndicatorSize.label,
            tabs: [
              Tab(text: S.of(context).online_room_title),
              Tab(text: S.of(context).offline_room_title),
            ],
          ),
        ),
        body: TabBarView(
          controller: controller.tabController,
          children: [
            _RoomOnlineGridView(),
            _RoomOfflineGridView(),
          ],
        ),
      );
    });
  }
}

class _RoomOnlineGridView extends GetView<FavoriteController> {
  _RoomOnlineGridView();

  final refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );
  final dense = Get.find<SettingsService>().enableDenseFavorites.value;

  Future onRefresh() async {
    bool result = await controller.onRefresh();
    if (!result) {
      refreshController.finishRefresh(IndicatorResult.success);
      refreshController.resetFooter();
    } else {
      refreshController.finishRefresh(IndicatorResult.fail);
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      final width = constraint.maxWidth;
      int crossAxisCount = width > 1280 ? 4 : (width > 960 ? 3 : (width > 640 ? 2 : 1));
      if (dense) {
        crossAxisCount = width > 1280 ? 5 : (width > 960 ? 4 : (width > 640 ? 3 : 2));
      }
      return Obx(() => EasyRefresh(
            controller: refreshController,
            onRefresh: onRefresh,
            onLoad: () {
              refreshController.finishLoad(IndicatorResult.success);
            },
            child: controller.onlineRooms.isNotEmpty
                ? MasonryGridView.count(
                    padding: const EdgeInsets.all(5),
                    controller: ScrollController(),
                    crossAxisCount: crossAxisCount,
                    itemCount: controller.onlineRooms.length,
                    itemBuilder: (context, index) => RoomCard(room: controller.onlineRooms[index], dense: dense),
                  )
                : EmptyView(
                    icon: Icons.favorite_rounded,
                    title: S.of(context).empty_favorite_online_title,
                    subtitle: S.of(context).empty_favorite_online_subtitle,
                  ),
          ));
    });
  }
}

class _RoomOfflineGridView extends GetView<FavoriteController> {
  _RoomOfflineGridView();

  final refreshController = EasyRefreshController();
  final dense = Get.find<SettingsService>().enableDenseFavorites.value;

  Future onRefresh() async {
    await controller.onRefresh();
    refreshController.finishRefresh(IndicatorResult.success);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      final width = constraint.maxWidth;
      int crossAxisCount = width > 1280 ? 4 : (width > 960 ? 3 : (width > 640 ? 2 : 1));
      if (dense) {
        crossAxisCount = width > 1280 ? 5 : (width > 960 ? 4 : (width > 640 ? 3 : 2));
      }

      return Obx(() => EasyRefresh(
            controller: refreshController,
            onRefresh: onRefresh,
            onLoad: () {
              refreshController.finishLoad(IndicatorResult.noMore);
            },
            child: controller.offlineRooms.isNotEmpty
                ? MasonryGridView.count(
                    padding: const EdgeInsets.all(5),
                    controller: ScrollController(),
                    crossAxisCount: crossAxisCount,
                    itemCount: controller.offlineRooms.length,
                    itemBuilder: (context, index) => RoomCard(
                      room: controller.offlineRooms[index],
                      dense: dense,
                    ),
                  )
                : EmptyView(
                    icon: Icons.favorite_rounded,
                    title: S.of(context).empty_favorite_offline_title,
                    subtitle: S.of(context).empty_favorite_offline_subtitle,
                  ),
          ));
    });
  }
}
