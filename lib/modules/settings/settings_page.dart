import 'dart:io';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/modules/settings/danmuset.dart';
import 'package:pure_live/plugins/file_recover_utils.dart';
import 'package:pure_live/common/widgets/settings_item_widget.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';

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
                  foucsNode: controller.preferResolutionNode,
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
                foucsNode: controller.videoPlayerNode,
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
                foucsNode: controller.enableCodecNode,
                title: "解码设置",
                items: const {0: "软解码", 1: " 硬解码"},
                value: controller.enableCodec.value ? 1 : 0,
                onChanged: (e) {
                  controller.enableCodec.value = e == 1;
                },
              ),
            ),
            AppStyle.vGap24,
            Obx(
              () => SettingsItemWidget(
                foucsNode: controller.preferPlatformNode,
                title: "默认平台",
                items: SettingsService.platforms.asMap(),
                value: SettingsService.platforms.indexOf(controller.preferPlatform.value),
                onChanged: (e) {
                  controller.preferPlatform.value = SettingsService.platforms[e];
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void showThemeModeSelectorDialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return SimpleDialog(
            title: Text(S.of(Get.context!).change_theme_mode),
            children: SettingsService.themeModes.keys.map<Widget>((name) {
              return RadioListTile<String>(
                activeColor: Theme.of(context).colorScheme.primary,
                groupValue: controller.themeModeName.value,
                value: name,
                title: Text(name),
                onChanged: (value) {
                  controller.changeThemeMode(value!);
                  Navigator.of(context).pop();
                },
              );
            }).toList(),
          );
        });
  }

  void showLanguageSelecterDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(S.of(context).change_language),
          children: SettingsService.languages.keys.map<Widget>((name) {
            return RadioListTile<String>(
              activeColor: Theme.of(context).colorScheme.primary,
              groupValue: controller.languageName.value,
              value: name,
              title: Text(name),
              onChanged: (value) {
                controller.changeLanguage(value!);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        );
      },
    );
  }

  void showVideoSetDialog() {
    List<String> playerList = controller.playerlist;
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(S.of(context).change_player),
          children: playerList.map<Widget>((name) {
            return RadioListTile<String>(
              activeColor: Theme.of(context).colorScheme.primary,
              groupValue: playerList[controller.videoPlayerIndex.value],
              value: name,
              title: Text(name),
              onChanged: (value) {
                controller.changePlayer(playerList.indexOf(name));
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        );
      },
    );
  }

  void showPreferResolutionSelectorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(S.of(context).prefer_resolution),
          children: SettingsService.resolutions.map<Widget>((name) {
            return RadioListTile<String>(
              activeColor: Theme.of(context).colorScheme.primary,
              groupValue: controller.preferResolution.value,
              value: name,
              title: Text(name),
              onChanged: (value) {
                controller.changePreferResolution(value!);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        );
      },
    );
  }

  void showPreferPlatformSelectorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text(S.of(context).prefer_platform),
          children: SettingsService.platforms.map<Widget>((name) {
            return RadioListTile<String>(
              activeColor: Theme.of(context).colorScheme.primary,
              groupValue: controller.preferPlatform.value,
              value: name,
              title: Text(name.toUpperCase()),
              onChanged: (value) {
                controller.changePreferPlatform(value!);
                Navigator.of(context).pop();
              },
            );
          }).toList(),
        );
      },
    );
  }

  void showAutoRefreshTimeSetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // title: Text(S.of(context).auto_refresh_time),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Slider(
                  min: 0,
                  max: 30,
                  label: S.of(context).auto_refresh_time,
                  value: controller.autoRefreshTime.toDouble(),
                  onChanged: (value) => controller.autoRefreshTime.value = value.toInt(),
                ),
                Text('${S.of(context).auto_refresh_time}:'
                    ' ${controller.autoRefreshTime}分钟'),
              ],
            )),
      ),
    );
  }

  void showDanmuSetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).settings_danmaku_title),
        content: SizedBox(
          width: Platform.isAndroid ? MediaQuery.of(context).size.width : MediaQuery.of(context).size.width * 0.6,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                VideoFitSetting(
                  controller: controller,
                ),
                DanmakuSetting(
                  controller: controller,
                ),
                const SizedBox(
                  height: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void showAutoShutDownTimeSetDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        // title: Text(S.of(context).auto_refresh_time),
        content: Obx(() => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SwitchListTile(
                  title: Text(S.of(context).auto_shutdown_time_subtitle),
                  value: controller.enableAutoShutDownTime.value,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (bool value) => controller.enableAutoShutDownTime.value = value,
                ),
                Slider(
                  min: 1,
                  max: 1200,
                  label: S.of(context).auto_refresh_time,
                  value: controller.autoShutDownTime.toDouble(),
                  onChanged: (value) {
                    controller.autoShutDownTime.value = value.toInt();
                  },
                ),
                Text('${S.of(context).auto_shutdown_time}:'
                    ' ${controller.autoShutDownTime} minute'),
              ],
            )),
      ),
    );
  }

  Future<String?> showWebPortDialog() async {
    final TextEditingController textEditingController = TextEditingController();
    textEditingController.text = controller.webPort.value;
    var result = await Get.dialog(
        AlertDialog(
          title: const Text('请输入端口号'),
          content: SizedBox(
            width: 400.0,
            height: 140.0,
            child: Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Column(
                children: [
                  TextField(
                    controller: textEditingController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.all(12),
                      hintText: '端口地址(1-65535)',
                    ),
                  ),
                  Obx(() => SwitchListTile(
                        title: const Text('是否开启web服务'),
                        value: controller.webPortEnable.value,
                        activeColor: Theme.of(context).colorScheme.primary,
                        onChanged: (bool value) {
                          controller.webPortEnable.value = value;
                        },
                      )),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                if (controller.webPortEnable.value) {
                  SmartDialog.showToast('请先关闭web服务');
                  return;
                }
                if (textEditingController.text.isEmpty) {
                  SmartDialog.showToast('请输入端口号');
                  return;
                }
                bool validate = FileRecoverUtils.isPort(textEditingController.text);
                if (!validate) {
                  SmartDialog.showToast('请输入正确的端口号');
                  return;
                }
                if (int.parse(textEditingController.text) < 1 || int.parse(textEditingController.text) > 65535) {
                  SmartDialog.showToast('请输入正确的端口号');
                  return;
                }
                controller.webPort.value = textEditingController.text;
                SmartDialog.showToast('设置成功');
              },
              child: const Text("确定"),
            ),
            TextButton(
              onPressed: Get.back,
              child: const Text("关闭弹窗"),
            ),
          ],
        ),
        barrierDismissible: false);
    return result;
  }
}
