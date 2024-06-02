import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import 'package:pure_live/app/utils.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/routes/app_navigation.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/common/widgets/highlight_widget.dart';
import 'package:pure_live/modules/areas/areas_list_controller.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

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
                focusNode: controller.focusNodes.first,
                iconData: Icons.arrow_back,
                text: "返回",
                autofocus: true,
                onTap: () {
                  Navigator.of(Get.context!).pop();
                },
              ),
              AppStyle.hGap32,
              Text(
                "分区类别",
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
          AppStyle.vGap24,
          Expanded(
            child: Obx(
              () => Sites().availableSites().isNotEmpty
                  ? ListView.builder(
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
                            if (controller.siteId.value != Sites.iptvSite)
                              Obx(
                                () => GridView.count(
                                  shrinkWrap: true,
                                  padding: AppStyle.edgeInsetsV8,
                                  physics: const NeverScrollableScrollPhysics(),
                                  crossAxisCount: 8,
                                  crossAxisSpacing: 20.w,
                                  mainAxisSpacing: 20.w,
                                  children: List.generate(
                                      item.children.length, (index) => buildSubCategory(item.children[index])).toList(),
                                ),
                              )
                            else
                              Obx(
                                () => MasonryGridView.count(
                                  padding: AppStyle.edgeInsetsA48,
                                  itemCount: controller.list.isNotEmpty ? controller.list[0].children.length : 0,
                                  crossAxisCount: 5,
                                  crossAxisSpacing: 24.w,
                                  mainAxisSpacing: 20.w,
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemBuilder: (_, i) {
                                    LiveArea liveArea = item.children[i];
                                    var roomItem = LiveRoom(
                                      roomId: liveArea.areaId,
                                      title: liveArea.areaName,
                                      cover: '',
                                      nick: liveArea.typeName,
                                      watching: '',
                                      avatar:
                                          'https://img95.699pic.com/xsj/0q/x6/7p.jpg%21/fw/700/watermark/url/L3hzai93YXRlcl9kZXRhaWwyLnBuZw/align/southeast',
                                      area: '',
                                      liveStatus: LiveStatus.live,
                                      status: true,
                                      platform: 'iptv',
                                    );
                                    return RoomCard(
                                      room: roomItem,
                                      dense: true,
                                      focusNode: liveArea.focusNode,
                                      isIptv: true,
                                      areas: item.children,
                                      roomTypePage: EnterRoomTypePage.areasRoomPage,
                                    );
                                  },
                                ),
                              ),
                          ],
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
                            "暂无分区类目\n请打开设置展示平台",
                            textAlign: TextAlign.center,
                            style: AppStyle.textStyleWhite,
                          )
                        ],
                      ),
                    ),
            ),
          ),
          AppStyle.vGap24,
        ],
      ),
    );
  }

  handleLiveArea(LiveArea area) async {
    if (controller.settingsService.isFavoriteArea(area)) {
      var result = await Utils.showAlertDialog("确定要删除此分区吗?", title: "删除分区");
      if (!result) {
        return;
      }
      controller.settingsService.removeArea(area);
    } else {
      var result = await Utils.showAlertDialog("确定要添加此分区吗?", title: "添加分区");
      if (!result) {
        return;
      }
      controller.settingsService.addArea(area);
    }
  }

  Widget buildSubCategory(LiveArea item) {
    return HighlightWidget(
      focusNode: item.focusNode,
      onTap: () {
        AppNavigator.toCategoryDetail(site: controller.site, category: item);
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
            width: 100.w,
            height: 100.w,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30.w),
            ),
            child: CachedNetworkImage(
              imageUrl: item.areaPic!,
              cacheManager: CustomCacheManager.instance,
              fit: BoxFit.fill,
              errorWidget: (context, error, stackTrace) => Center(
                child: Icon(
                  Icons.live_tv_rounded,
                  size: 50,
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
