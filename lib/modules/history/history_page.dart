import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:pure_live/modules/history/history_rooms_controller.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HistoryPage extends GetView<HistoryPageController> {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsService settingsService = Get.find<SettingsService>();
    settingsService.currentPlayList.value = controller.list;
    settingsService.currentPlayListNodeIndex.value = 0;
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
                "观看记录",
                style: AppStyle.titleStyleWhite.copyWith(
                  fontSize: 36.w,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppStyle.hGap24,
              const Spacer(),
              HighlightButton(
                focusNode: AppFocusNode(),
                iconData: Icons.delete_outline_rounded,
                text: "清空",
                onTap: () {
                  controller.clean();
                },
              ),
              AppStyle.hGap48,
            ],
          ),
          AppStyle.vGap24,
          Expanded(
            child: Obx(
              () => MasonryGridView.count(
                padding: AppStyle.edgeInsetsA48,
                itemCount: controller.list.length,
                crossAxisCount: 5,
                crossAxisSpacing: 48.w,
                mainAxisSpacing: 40.w,
                controller: controller.scrollController,
                itemBuilder: (_, i) {
                  var item = controller.list[i];
                  return RoomCard(
                    room: item,
                    dense: true,
                    useDefaultLongTapEvent: false,
                    focusNode: controller.focusNodes[i],
                    onLongTap: () {
                      controller.removeItem(item);
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
