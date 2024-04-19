import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/widgets/settings_item_widget.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:pure_live/common/widgets/button/highlight_list_tile.dart';

class SettingsPage extends GetView<SettingsService> {
  const SettingsPage({super.key});

  BuildContext get context => Get.context!;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Padding(
        padding: AppStyle.edgeInsetsA48,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            AppStyle.vGap32,
            Row(
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
              ],
            ),
            AppStyle.vGap24,
            Obx(() => SettingsItemWidget(
                  focusNode: controller.preferResolutionNode,
                  title: "首选清晰度",
                  items: const {
                    "原画": "原画",
                    "蓝光8M": "蓝光8M",
                    "蓝光4M": "蓝光4M",
                    "超清": "超清",
                    "流畅": "流畅",
                  },
                  value: controller.preferResolution.value,
                  onChanged: (e) {
                    controller.preferResolution.value = e;
                  },
                )),
            AppStyle.vGap24,
            Obx(
              () => SettingsItemWidget(
                focusNode: controller.videoPlayerNode,
                title: "播放器设置",
                items: const {
                  0: "Exo播放器",
                  1: "Ijk播放器",
                  2: "Mpv播放器",
                },
                value: controller.videoPlayerIndex.value,
                onChanged: (e) {
                  controller.videoPlayerIndex.value = e;
                },
              ),
            ),
            AppStyle.vGap24,
            Obx(
              () => SettingsItemWidget(
                focusNode: controller.playerCompatModeNode,
                title: "Mpv播放器兼容模式(此配置生效解码不生效)",
                items: const {0: "不使用", 1: "使用"},
                value: controller.playerCompatMode.value ? 1 : 0,
                onChanged: (e) {
                  controller.playerCompatMode.value = e == 1;
                },
              ),
            ),
            Obx(
              () => SettingsItemWidget(
                focusNode: controller.enableCodecNode,
                title: "解码设置",
                items: const {0: "软解码", 1: "硬解码"},
                value: controller.enableCodec.value ? 1 : 0,
                onChanged: (e) {
                  controller.enableCodec.value = e == 1;
                },
              ),
            ),
            Obx(
              () => SettingsItemWidget(
                focusNode: controller.preferPlatformNode,
                title: "默认平台",
                items: SettingsService.platforms.asMap(),
                value: SettingsService.platforms.indexOf(controller.preferPlatform.value),
                onChanged: (e) {
                  controller.preferPlatform.value = SettingsService.platforms[e];
                },
              ),
            ),
            HighlightListTile(
              title: "平台设置",
              trailing: const Icon(Icons.chevron_right),
              focusNode: controller.platformNode,
              onTap: () {
                Get.toNamed(RoutePath.kSettingsHotAreas);
              },
            ),
            HighlightListTile(
              title: "三方认证",
              trailing: const Icon(Icons.chevron_right),
              focusNode: controller.accountNode,
              onTap: () {
                Get.toNamed(RoutePath.kSettingsAccount);
              },
            ),
            HighlightListTile(
              title: "数据同步",
              trailing: const Icon(Icons.chevron_right),
              focusNode: controller.dataSyncNode,
              onTap: () {
                Get.toNamed(RoutePath.kSync);
              },
            ),
            Obx(
              () => SettingsItemWidget(
                focusNode: controller.currentImageIndexNode,
                title: "壁纸选择",
                items: controller.getBoxImageItems(),
                value: SettingsService.currentBoxImageSources
                    .map((e) => e.keys.first)
                    .toList()[controller.currentBoxImageIndex.value],
                onChanged: (e) {
                  var index = SettingsService.currentBoxImageSources.map((e) => e.keys.first).toList().indexOf(e);
                  controller.currentBoxImageIndex.value = index;
                },
              ),
            ),
            HighlightListTile(
              title: "切换壁纸",
              trailing: const Icon(Icons.change_circle_rounded),
              focusNode: controller.currentImageNode,
              onTap: () {
                controller.getImage();
              },
            ),
          ],
        ),
      ),
    );
  }
}
