import 'dart:async';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/modules/home/home_controller.dart';
import 'package:pure_live/common/widgets/button/home_big_button.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({super.key});

  handleMainPageButtonTap(int index) {
    controller.currentNodeIndex.value = index + 1;
    controller.pageController.unselectAll();
    controller.pageController.selectIndex(index);
    switch (index) {
      case 0:
        Get.toNamed(RoutePath.kFavorite);
        break;
      case 1:
        Get.toNamed(RoutePath.kPopular);
        break;
      case 2:
        Get.toNamed(RoutePath.kAreas);
        break;
      case 3:
        showSearchDialog();
        break;
      case 4:
        Get.toNamed(RoutePath.kHistory);
        break;
      case 5:
        Get.toNamed(RoutePath.kDonate);
        break;
      default:
    }
  }

  Widget buildViews() {
    return GroupButton(
      controller: controller.pageController,
      isRadio: false,
      options: GroupButtonOptions(
        spacing: 48.w,
        runSpacing: 10,
        groupingType: GroupingType.wrap,
        direction: Axis.horizontal,
        borderRadius: BorderRadius.circular(4),
        mainGroupAlignment: MainGroupAlignment.start,
        crossGroupAlignment: CrossGroupAlignment.start,
        groupRunAlignment: GroupRunAlignment.start,
        textAlign: TextAlign.center,
        textPadding: EdgeInsets.zero,
        alignment: Alignment.center,
      ),
      buttons: HomeController.mainPageOptions,
      maxSelected: 1,
      buttonIndexedBuilder: (selected, index, context) => HomeBigButton(
        key: ValueKey(index),
        focusNode: controller.focusNodes[index + 1],
        text: HomeController.mainPageOptions[index],
        iconData: HomeController.mainPageIconOptions[index],
        onTap: () => handleMainPageButtonTap(index),
      ),
    );
  }

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
              Text(
                "纯粹直播",
                style: AppStyle.titleStyleWhite,
              ),
              AppStyle.hGap24,
              const Spacer(),
              Obx(() => Text(
                    controller.datetime.value,
                    style: AppStyle.titleStyleWhite.copyWith(fontSize: 36.w),
                  )),
              AppStyle.hGap32,
              HighlightButton(
                focusNode: controller.focusNodes.first,
                iconData: Icons.settings,
                text: "设置",
                onTap: () {
                  controller.currentNodeIndex.value = 0;
                  Get.toNamed(RoutePath.kSettings);
                },
              ),
              AppStyle.hGap48,
            ],
          ),
          Expanded(
            child: ListView(
              padding: AppStyle.edgeInsetsV32,
              children: [
                Padding(
                  padding: AppStyle.edgeInsetsH48,
                  child: SizedBox(
                    height: 200.h,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            buildViews(),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                AppStyle.vGap32,
                Padding(
                  padding: AppStyle.edgeInsetsH48,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 64.w,
                        height: 64.w,
                        child: Center(
                          child: Icon(
                            Icons.history,
                            color: Colors.white,
                            size: 56.w,
                          ),
                        ),
                      ),
                      AppStyle.hGap24,
                      Expanded(
                        child: Text(
                          "最近观看",
                          style: AppStyle.titleStyleWhite,
                        ),
                      ),
                      Obx(
                        () => Visibility(
                          visible: controller.loadding.value,
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
                        focusNode: controller.focusNodes.last,
                        iconData: Icons.refresh,
                        text: "刷新",
                        onTap: () {
                          controller.refreshData();
                          controller.currentNodeIndex.value = controller.focusNodes.length - 1;
                        },
                      ),
                    ],
                  ),
                ),
                Obx(() => MasonryGridView.count(
                      padding: AppStyle.edgeInsetsA48,
                      itemCount: controller.rooms.value.length,
                      crossAxisCount: 5,
                      crossAxisSpacing: 48.w,
                      mainAxisSpacing: 40.w,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemBuilder: (_, i) {
                        var item = controller.rooms.value[i];
                        return RoomCard(
                          room: item,
                          dense: true,
                          focusNode: controller.hisToryFocusNodes[i],
                        );
                      },
                    )),
                Obx(
                  () => Visibility(
                    visible: controller.rooms.isEmpty,
                    child: Column(
                      children: [
                        AppStyle.vGap24,
                        LottieBuilder.asset(
                          'assets/lotties/empty.json',
                          width: 160.w,
                          height: 160.w,
                          repeat: false,
                        ),
                        AppStyle.vGap24,
                        Text(
                          "暂无任何历史记录\n您可以从其他端同步数据到此处",
                          textAlign: TextAlign.center,
                          style: AppStyle.textStyleWhite,
                        ),
                        AppStyle.vGap16,
                        HighlightButton(
                          focusNode: controller.syncNode,
                          iconData: Icons.devices,
                          text: "同步数据",
                          onTap: () {
                            controller.toSync();
                          },
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  void showSearchDialog() {
    var textController = TextEditingController();
    var roomFocusNode = AppFocusNode()..isFoucsed.value = true;
    Timer(const Duration(milliseconds: 100), () {
      roomFocusNode.requestFocus();
    });
    showDialog(
      context: Get.context!,
      builder: (_) => AlertDialog(
        backgroundColor: Get.theme.cardColor,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppStyle.radius16,
        ),
        contentPadding: AppStyle.edgeInsetsA48,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: AppStyle.edgeInsetsR12,
                      child: Icon(
                        Icons.live_tv,
                        size: 40.w,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      '直播间搜索',
                      style: TextStyle(
                        fontSize: 28.w,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            AppStyle.vGap48,
            SizedBox(
              width: 700.w,
              child: TextField(
                controller: textController,
                focusNode: roomFocusNode,
                style: AppStyle.textStyleWhite,
                textInputAction: TextInputAction.search,
                onSubmitted: (e) {
                  if (e.isEmpty) {
                    return;
                  }
                  // 关闭键盘在关闭弹窗
                  Navigator.of(Get.context!).pop();
                  roomFocusNode.unfocus();
                  Timer(const Duration(milliseconds: 100), () {
                    Get.toNamed(RoutePath.kSearch, arguments: e);
                  });
                },
                decoration: InputDecoration(
                  hintText: "点击输入关键字搜索",
                  hintStyle: AppStyle.textStyleWhite,
                  border: OutlineInputBorder(
                    borderRadius: AppStyle.radius16,
                    borderSide: BorderSide(width: 4.w),
                  ),
                  filled: true,
                  isDense: true,
                  fillColor: Get.theme.primaryColor,
                  contentPadding: AppStyle.edgeInsetsA32,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
