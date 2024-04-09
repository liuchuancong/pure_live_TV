import 'package:get/get.dart';
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
                focusNode: AppFocusNode(),
                iconData: Icons.arrow_back,
                text: "返回",
                //autofocus: true,
                onTap: () {
                  Get.back();
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
                  child: SizedBox(
                    width: 48.w,
                    height: 48.w,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 4.w,
                    ),
                  ),
                ),
              ),
              AppStyle.hGap24,
              AppStyle.hGap48,
            ],
          ),
          AppStyle.vGap24,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 36.w,
            children: Sites()
                .availableSites()
                .map((e) => Obx(() => HighlightButton(
                      icon: Image.asset(
                        e.logo,
                        width: 48.w,
                        height: 48.w,
                      ),
                      text: e.name,
                      selected: controller.siteId.value == e.id,
                      focusNode: AppFocusNode(),
                      onTap: () {
                        controller.setSite(e.id);
                      },
                    )))
                .toList(),
          ),
          AppStyle.vGap32,
          Expanded(
            child: Obx(
              () => MasonryGridView.count(
                padding: AppStyle.edgeInsetsA48,
                itemCount: controller.list.length,
                crossAxisCount: 5,
                crossAxisSpacing: 48.w,
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
