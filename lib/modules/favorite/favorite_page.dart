import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class FavoritePage extends GetView<FavoriteController> {
  const FavoritePage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Column(
        children: [
          AppStyle.vGap32,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppStyle.hGap48,
              HighlightButton(
                focusNode: AppFocusNode(),
                iconData: Icons.arrow_back,
                text: "返回",
                autofocus: true,
                onTap: () {
                  Get.back();
                },
              ),
              AppStyle.hGap32,
              Text(
                "我的关注",
                style: AppStyle.titleStyleWhite.copyWith(
                  fontSize: 36.w,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppStyle.hGap24,
              const Spacer(),
              Obx(
                () => Visibility(
                  visible: controller.loading.value,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 48.w,
                        height: 48.w,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 4.w,
                        ),
                      ),
                      AppStyle.hGap16,
                      Text(
                        "正在更新...",
                        style: AppStyle.textStyleWhite,
                      ),
                    ],
                  ),
                ),
              ),
              AppStyle.hGap32,
              HighlightButton(
                focusNode: AppFocusNode(),
                iconData: Icons.refresh,
                text: "刷新",
                onTap: () {
                  controller.onRefresh();
                },
              ),
              AppStyle.hGap48,
            ],
          ),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 36.w,
            children: [
              HighlightButton(
                text: "已开播",
                focusNode: controller.onlineRoomsNodes,
                onTap: () {
                  final SettingsService settingsService = Get.find<SettingsService>();
                  settingsService.currentPlayList.value = controller.onlineRooms;
                  settingsService.currentPlayListNodeIndex.value = 0;
                  controller.tabBottomIndex.value = 0;
                  controller.onlineRoomsNodes.requestFocus();
                },
              ),
              HighlightButton(
                text: "未开播",
                focusNode: controller.offlineRoomsNodes,
                onTap: () {
                  final SettingsService settingsService = Get.find<SettingsService>();
                  settingsService.currentPlayList.value = controller.offlineRooms;
                  settingsService.currentPlayListNodeIndex.value = 0;
                  controller.tabBottomIndex.value = 1;
                  controller.offlineRoomsNodes.requestFocus();
                },
              )
            ],
          ),
          AppStyle.vGap48,
          Expanded(
            child: Obx(
              () => MasonryGridView.count(
                padding: AppStyle.edgeInsetsH48,
                itemCount: controller.tabBottomIndex.value == 0
                    ? controller.onlineRooms.length
                    : controller.offlineRooms.length,
                crossAxisCount: 5,
                crossAxisSpacing: 48.w,
                mainAxisSpacing: 40.w,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (_, i) {
                  var item =
                      controller.tabBottomIndex.value == 0 ? controller.onlineRooms[i] : controller.offlineRooms[i];
                  return RoomCard(
                    focusNode: item.focusNode,
                    room: item,
                    useDefaultLongTapEvent: false,
                    dense: controller.settings.enableDenseFavorites.value,
                    onLongTap: () {
                      controller.handleFollowLongTap(item);
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
