import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/modules/home/home_controller.dart';
import 'package:pure_live/common/widgets/button/home_big_button.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';

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
        Get.toNamed(RoutePath.kSearch);
        break;
      case 4:
        Get.toNamed(RoutePath.kHistory);
        break;
      case 5:
        Get.toNamed(RoutePath.kHistory);
        break;
      default:
    }
  }

  Widget buildViews() {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: GroupButton(
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
              children: [
                buildViews(),
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
                          visible: controller.settingsService.favoriteRooms.isNotEmpty,
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
                                "更新状态中...",
                                style: AppStyle.textStyleWhite,
                              ),
                            ],
                          ),
                        ),
                      ),
                      AppStyle.hGap16,
                      HighlightButton(
                        focusNode: AppFocusNode(),
                        iconData: Icons.settings,
                        text: "管理",
                        onTap: () {},
                      ),
                      AppStyle.hGap32,
                      HighlightButton(
                        focusNode: controller.focusNodes.last,
                        iconData: Icons.refresh,
                        text: "刷新",
                        onTap: () {
                          controller.currentNodeIndex.value = controller.focusNodes.length - 1;
                        },
                      ),
                    ],
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
