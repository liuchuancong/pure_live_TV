import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:pure_live/modules/popular/popular_grid_controller.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class PopularPage extends GetView<PopularGridController> {
  const PopularPage({super.key});

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
                focusNode: controller.focusNodes.first,
                iconData: Icons.arrow_back,
                text: "返回",
                //autofocus: true,
                onTap: () {
                  Navigator.of(Get.context!).pop();
                },
              ),
              AppStyle.hGap32,
              Text(
                "热门直播",
                style: AppStyle.titleStyleWhite.copyWith(
                  fontSize: 36.w,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppStyle.hGap24,
              const Spacer(),
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
              AppStyle.hGap24,
              HighlightButton(
                focusNode: AppFocusNode(),
                iconData: Icons.refresh,
                text: "刷新",
                onTap: () {
                  controller.scrollToTopOrRefresh();
                },
              ),
              AppStyle.hGap48,
            ],
          ),
          AppStyle.vGap24,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 36.w,
            children: List.generate(
                Sites().availableSites().length,
                (index) => Obx(() => HighlightButton(
                      icon: Image.asset(
                        Sites().availableSites()[index].logo,
                        width: 48.w,
                        height: 48.w,
                      ),
                      text: Sites().availableSites()[index].name,
                      selected: controller.siteId.value == Sites().availableSites()[index].id,
                      focusNode: controller.focusNodes[index + 1],
                      onTap: () {
                        controller.setSite(Sites().availableSites()[index].id);
                      },
                    ))).toList(),
          ),
          AppStyle.vGap32,
          Expanded(
            child: Obx(
              () => Sites().availableSites().isNotEmpty
                  ? MasonryGridView.count(
                      padding: AppStyle.edgeInsetsA48,
                      itemCount: controller.list.length,
                      crossAxisCount: 5,
                      crossAxisSpacing: 24.w,
                      mainAxisSpacing: 48.w,
                      controller: controller.scrollController,
                      itemBuilder: (_, i) {
                        var item = controller.list[i];
                        if (i == 0) {
                          Future.delayed(Duration.zero, () {
                            if (controller.currentPage == 2) {
                              item.focusNode.requestFocus();
                            }
                          });
                        }
                        return RoomCard(
                          room: item,
                          dense: true,
                          focusNode: item.focusNode,
                          roomTypePage: EnterRoomTypePage.popularPage,
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          LottieBuilder.asset(
                            'assets/lotties/empty.json',
                            width: 160.w,
                            height: 160.w,
                            repeat: false,
                          ),
                          AppStyle.vGap24,
                          Text(
                            "暂无热门直播\n请打开设置展示平台",
                            textAlign: TextAlign.center,
                            style: AppStyle.textStyleWhite,
                          )
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
