import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/consts/app_consts.dart';
import 'package:pure_live/player/switchable_global_player.dart';
import 'package:pure_live/common/widgets/settings_item_widget.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:pure_live/common/widgets/button/highlight_list_tile.dart';

class SettingsPage extends GetView<SettingsService> {
  const SettingsPage({super.key});

  BuildContext get context => Get.context!;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: ListView(
        padding: AppStyle.edgeInsetsA48,
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
                  Navigator.of(Get.context!).pop();
                },
              ),
            ],
          ),
          AppStyle.vGap24,
          SettingsItemWidget(
            focusNode: controller.autoRefreshTimeNode,
            title: "自动更新关注",
            items: const {0: "关闭", 1: "打开"},
            value: controller.autoRefreshFavorite.value ? 1 : 0,
            onChanged: (e) {
              controller.autoRefreshFavorite.value = e == 1;
            },
          ),
          AppStyle.vGap24,
          Obx(
            () => SettingsItemWidget(
              focusNode: controller.maxConcurrentRefreshNode,
              title: "刷新线程",
              items: const {
                1: "1",
                2: "2",
                3: "3",
                4: "4",
                5: "5",
                6: "6",
                7: "7",
                8: "8",
                9: "9",
                10: "10",
                11: "11",
                12: "12",
                13: "13",
                14: "14",
                15: "15",
                16: "16",
                17: "17",
                18: "18",
                19: "19",
                20: "20",
              },
              value: controller.maxConcurrentRefresh.value,
              onChanged: (e) {
                controller.maxConcurrentRefresh.value = e;
              },
            ),
          ),
          AppStyle.vGap24,
          Obx(
            () => SettingsItemWidget(
              focusNode: controller.preferResolutionNode,
              title: "首选清晰度",
              items: const {"原画": "原画", "蓝光8M": "蓝光8M", "蓝光4M": "蓝光4M", "超清": "超清", "流畅": "流畅"},
              value: controller.preferResolution.value,
              onChanged: (e) {
                controller.preferResolution.value = e;
              },
            ),
          ),
          AppStyle.vGap24,
          Obx(
            () => SettingsItemWidget(
              focusNode: controller.videoPlayerNode,
              title: "播放器设置",
              items: const {0: "Mpv播放器", 1: "Ijk播放器"},
              value: controller.videoPlayerIndex.value,
              onChanged: (e) {
                controller.videoPlayerIndex.value = e;
                SwitchableGlobalPlayer().switchEngine(e == 0 ? PlayerEngine.mediaKit : PlayerEngine.fijk);
              },
            ),
          ),
          AppStyle.vGap24,
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
          Obx(() {
            if (controller.videoPlayerIndex.value != 0) return const SizedBox.shrink();

            return Column(
              children: [
                AppStyle.vGap24,
                SettingsItemWidget(
                  focusNode: controller.audioDelayNode,
                  title: "音频调节",
                  items: AppConsts.audioDelayMap,
                  value: controller.audioDelay.value.toString(),
                  onChanged: (e) {
                    double val = double.tryParse(e.toString()) ?? 0.0;
                    controller.audioDelay.value = val;
                  },
                ),
                AppStyle.vGap24,
                SettingsItemWidget(
                  focusNode: controller.playerCompatModeNode,
                  title: "兼容模式",
                  items: const {0: "关闭", 1: "打开"},
                  value: controller.playerCompatMode.value ? 1 : 0,
                  onChanged: (e) {
                    controller.playerCompatMode.value = e == 1;
                  },
                ),
              ],
            );
          }),

          Obx(
            () => SettingsItemWidget(
              focusNode: controller.preferPlatformNode,
              title: "默认平台",
              items: AppConsts.platforms.asMap(),
              value: AppConsts.platforms.indexOf(controller.preferPlatform.value),
              onChanged: (e) {
                controller.preferPlatform.value = AppConsts.platforms[e];
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
              value: AppConsts.currentBoxImageSources
                  .map((e) => e.keys.first)
                  .toList()[controller.currentBoxImageIndex.value],
              onChanged: (e) {
                var index = AppConsts.currentBoxImageSources.map((e) => e.keys.first).toList().indexOf(e);
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
    );
  }
}
