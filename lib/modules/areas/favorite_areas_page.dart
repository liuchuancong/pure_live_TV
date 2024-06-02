import 'package:get/get.dart';
import 'package:pure_live/app/utils.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/routes/app_navigation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/common/widgets/highlight_widget.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';

class FavoriteAreasPage extends GetView<SettingsService> {
  const FavoriteAreasPage({super.key});

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
                  Navigator.of(Get.context!).pop();
                },
              ),
              AppStyle.hGap32,
              Text(
                "关注分区",
                style: AppStyle.titleStyleWhite.copyWith(
                  fontSize: 36.w,
                  fontWeight: FontWeight.bold,
                ),
              ),
              AppStyle.hGap24,
              const Spacer(),
              AppStyle.hGap24
            ],
          ),
          AppStyle.vGap24,
          Expanded(
              child: Obx(
            () => controller.favoriteAreas.isNotEmpty
                ? Padding(
                    padding: AppStyle.edgeInsetsA24,
                    child: GridView.count(
                      shrinkWrap: true,
                      padding: AppStyle.edgeInsetsV8,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: 8,
                      crossAxisSpacing: 36.w,
                      mainAxisSpacing: 36.w,
                      children: List.generate(controller.favoriteAreas.length,
                          (index) => buildSubCategory(controller.favoriteAreas[index])).toList(),
                    ),
                  )
                : EmptyView(
                    icon: Icons.area_chart_outlined,
                    title: S.of(context).empty_areas_title,
                    subtitle: '',
                  ),
          )),
          AppStyle.vGap24,
        ],
      ),
    );
  }

  handleLiveArea(LiveArea area) async {
    if (controller.isFavoriteArea(area)) {
      var result = await Utils.showAlertDialog("确定要删除此分区吗?", title: "删除分区");
      if (!result) {
        return;
      }
      controller.removeArea(area);
    } else {
      var result = await Utils.showAlertDialog("确定要添加此分区吗?", title: "添加分区");
      if (!result) {
        return;
      }
      controller.addArea(area);
    }
  }

  Widget buildSubCategory(LiveArea item) {
    return HighlightWidget(
      focusNode: item.focusNode,
      onTap: () {
        AppNavigator.toCategoryDetail(site: Sites.of(item.platform!), category: item);
      },
      onLongTap: () {
        handleLiveArea(item);
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
}
