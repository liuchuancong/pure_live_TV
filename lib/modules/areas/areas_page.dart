import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/routes/app_navigation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/common/widgets/highlight_widget.dart';
import 'package:pure_live/modules/areas/areas_list_controller.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';

class AreasPage extends GetView<AreasListController> {
  const AreasPage({super.key});

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
                "直播类目",
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
              HighlightButton(
                focusNode: AppFocusNode(),
                iconData: Icons.refresh,
                text: "刷新",
                onTap: () {
                  controller.refreshData();
                },
              ),
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
          AppStyle.vGap24,
          Expanded(
            child: Obx(
              () => ListView.builder(
                padding: AppStyle.edgeInsetsH48,
                itemCount: controller.list.length,
                controller: controller.scrollController,
                itemBuilder: (_, i) {
                  var item = controller.list[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: AppStyle.edgeInsetsV32,
                        child: Text(
                          item.name,
                          style: AppStyle.titleStyleWhite,
                        ),
                      ),
                      Obx(
                        () => GridView.count(
                          shrinkWrap: true,
                          padding: AppStyle.edgeInsetsV8,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 8,
                          crossAxisSpacing: 36.w,
                          mainAxisSpacing: 36.w,
                          children: item.showAll.value
                              ? (item.children.map((e) => buildSubCategory(e)).toList()
                                ..add(item.children.length > 19 ? buildShowLess(item) : Container()))
                              : (item.take15.map((e) => buildSubCategory(e)).toList()..add(buildShowMore(item))),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          AppStyle.vGap24,
        ],
      ),
    );
  }

  Widget buildSubCategory(LiveArea item) {
    return HighlightWidget(
      focusNode: item.focusNode,
      onTap: () {
        AppNavigator.toCategoryDetail(site: controller.site, category: item);
      },
      color: Colors.white10,
      borderRadius: AppStyle.radius16,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64.w,
            height: 64.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.w),
            ),
            child: CachedNetworkImage(
              imageUrl: item.areaPic!,
              cacheManager: CustomCacheManager.instance,
              fit: BoxFit.fill,
              errorWidget: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.live_tv_rounded,
                  size: 38,
                  color: item.focusNode.isFoucsed.value ? Colors.black : Colors.white,
                ),
              ),
            ),
          ),
          AppStyle.vGap12,
          Text(
            item.areaName!,
            maxLines: 1,
            textAlign: TextAlign.center,
            style: item.focusNode.isFoucsed.value ? AppStyle.textStyleBlack : AppStyle.textStyleWhite,
          ),
        ],
      ),
    );
  }

  Widget buildShowMore(AppLiveCategory item) {
    return HighlightWidget(
      focusNode: item.moreFocusNode,
      onTap: () {
        item.moreFocusNode.unfocus();
        item.showAll.value = true;
      },
      color: Colors.white10,
      borderRadius: AppStyle.radius16,
      child: Center(
        child: Text(
          "显示全部",
          maxLines: 1,
          textAlign: TextAlign.center,
          style: item.moreFocusNode.isFoucsed.value ? AppStyle.textStyleBlack : AppStyle.textStyleWhite,
        ),
      ),
    );
  }

  Widget buildShowLess(AppLiveCategory item) {
    return HighlightWidget(
      focusNode: item.moreFocusNode,
      onTap: () {
        item.moreFocusNode.unfocus();
        item.showAll.value = false;
      },
      color: Colors.white10,
      borderRadius: AppStyle.radius16,
      child: Center(
        child: Text(
          "收起",
          maxLines: 1,
          textAlign: TextAlign.center,
          style: item.moreFocusNode.isFoucsed.value ? AppStyle.textStyleBlack : AppStyle.textStyleWhite,
        ),
      ),
    );
  }
}
