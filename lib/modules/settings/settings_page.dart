import 'dart:io';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:flex_color_picker/flex_color_picker.dart';
import 'package:pure_live/modules/settings/danmuset.dart';
import 'package:pure_live/modules/backup/backup_page.dart';
import 'package:pure_live/plugins/file_recover_utils.dart';
import 'package:pure_live/modules/auth/utils/constants.dart';

class SettingsPage extends GetView<SettingsService> {
  const SettingsPage({super.key});

  BuildContext get context => Get.context!;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        scrolledUnderElevation: screenWidth > 640 ? 0 : null,
        title: Text(S.of(context).settings_title),
      ),
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: <Widget>[
          SectionTitle(title: S.of(context).general),
          ListTile(
            leading: const Icon(Icons.dark_mode_rounded, size: 32),
            title: Text(S.of(context).change_theme_mode),
            subtitle: Text(S.of(context).change_theme_mode_subtitle),
            onTap: showThemeModeSelectorDialog,
          ),
          ListTile(
            leading: const Icon(Icons.color_lens, size: 32),
            title: Text(S.of(context).change_theme_color),
            subtitle: Text(S.of(context).change_theme_color_subtitle),
            trailing: ColorIndicator(
              width: 44,
              height: 44,
              borderRadius: 4,
              color: HexColor(controller.themeColorSwitch.value),
              onSelectFocus: false,
            ),
            onTap: colorPickerDialog,
          ),
          ListTile(
            leading: const Icon(Icons.translate_rounded, size: 32),
            title: Text(S.of(context).change_language),
            subtitle: Text(S.of(context).change_language_subtitle),
            onTap: showLanguageSelecterDialog,
          ),
          ListTile(
            leading: const Icon(Icons.backup_rounded, size: 32),
            title: Text(S.of(context).backup_recover),
            subtitle: Text(S.of(context).backup_recover_subtitle),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const BackupPage()),
            ),
          ),
          SectionTitle(title: S.of(context).video),
          Obx(() => SwitchListTile(
                title: Text(S.of(context).enable_background_play),
                subtitle: Text(S.of(context).enable_background_play_subtitle),
                value: controller.enableBackgroundPlay.value,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (bool value) => controller.enableBackgroundPlay.value = value,
              )),
          Obx(() => SwitchListTile(
                title: Text(S.of(context).enable_screen_keep_on),
                subtitle: Text(S.of(context).enable_screen_keep_on_subtitle),
                value: controller.enableScreenKeepOn.value,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (bool value) => controller.enableScreenKeepOn.value = value,
              )),
          Obx(() => SwitchListTile(
                title: Text(S.of(context).enable_fullscreen_default),
                subtitle: Text(S.of(context).enable_fullscreen_default_subtitle),
                value: controller.enableFullScreenDefault.value,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (bool value) => controller.enableFullScreenDefault.value = value,
              )),
          ListTile(
            title: Text(S.of(context).prefer_resolution),
            subtitle: Text(S.of(context).prefer_resolution_subtitle),
            onTap: showPreferResolutionSelectorDialog,
          ),
          SectionTitle(title: S.of(context).custom),
          Obx(() => SwitchListTile(
                title: Text(S.of(context).enable_dynamic_color),
                subtitle: Text(S.of(context).enable_dynamic_color_subtitle),
                value: controller.enableDynamicTheme.value,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (bool value) => controller.enableDynamicTheme.value = value,
              )),
          Obx(() => SwitchListTile(
                title: Text(S.of(context).enable_dense_favorites_mode),
                subtitle: Text(S.of(context).enable_dense_favorites_mode_subtitle),
                value: controller.enableDenseFavorites.value,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (bool value) => controller.enableDenseFavorites.value = value,
              )),
          Obx(() => SwitchListTile(
                title: Text(S.of(context).enable_auto_check_update),
                subtitle: Text(S.of(context).enable_auto_check_update_subtitle),
                value: controller.enableAutoCheckUpdate.value,
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (bool value) => controller.enableAutoCheckUpdate.value = value,
              )),
          ListTile(
            title: Text(S.of(context).prefer_platform),
            subtitle: Text(S.of(context).prefer_platform_subtitle),
            onTap: showPreferPlatformSelectorDialog,
          ),
          ListTile(
            title: Text(S.of(context).auto_refresh_time),
            subtitle: Text(S.of(context).auto_refresh_time_subtitle),
            trailing: Obx(() => Text('${controller.autoRefreshTime}分钟')),
            onTap: showAutoRefreshTimeSetDialog,
          ),
          ListTile(
            title: Text(S.of(context).settings_danmaku_title),
            onTap: showDanmuSetDialog,
          ),
          ListTile(
            title: const Text("弹幕过滤"),
            subtitle: const Text("自定义关键词过滤弹幕"),
            onTap: () => Get.toNamed(RoutePath.kSettingsDanmuShield),
          ),
          ListTile(
            title: const Text("平台设置"),
            subtitle: const Text("自定义观看喜爱的平台"),
            onTap: () => Get.toNamed(RoutePath.kSettingsHotAreas),
          ),
          ListTile(
            title: const Text("Web服务"),
            subtitle: const Text("使用web页面控制应用"),
            onTap: showWebPortDialog,
          ),
          if (Platform.isAndroid)
            Obx(() => SwitchListTile(
                  title: Text(S.of(context).double_click_to_exit),
                  value: controller.doubleExit.value,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (bool value) => controller.doubleExit.value = value,
                )),
          if (Platform.isAndroid)
            ListTile(
              title: Text(S.of(context).change_player),
              subtitle: Text(S.of(context).change_player_subtitle),
              trailing: Obx(() => Text(controller.playerlist[controller.videoPlayerIndex.value])),
              onTap: showVideoSetDialog,
            ),
          if (Platform.isAndroid)
            Obx(() => SwitchListTile(
                  title: Text(S.of(context).enable_codec),
                  value: controller.enableCodec.value,
                  activeColor: Theme.of(context).colorScheme.primary,
                  onChanged: (bool value) => controller.enableCodec.value = value,
                )),
          if (Platform.isAndroid)
            ListTile(
              title: Text(S.of(context).auto_shutdown_time),
              subtitle: Text(S.of(context).auto_shutdown_time_subtitle),
              trailing: Obx(() => Text('${controller.autoShutDownTime} minute')),
              onTap: showAutoShutDownTimeSetDialog,
            ),
        ],
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

  Future<bool> colorPickerDialog() async {
    return ColorPicker(
      color: HexColor(controller.themeColorSwitch.value),
      onColorChanged: (Color color) {
        controller.themeColorSwitch.value = color.hex;
        var themeColor = color;
        var lightTheme = MyTheme(primaryColor: themeColor).lightThemeData;
        var darkTheme = MyTheme(primaryColor: themeColor).darkThemeData;
        Get.changeTheme(lightTheme);
        Get.changeTheme(darkTheme);
      },
      width: 40,
      height: 40,
      borderRadius: 4,
      spacing: 5,
      runSpacing: 5,
      wheelDiameter: 155,
      heading: Text(
        '主题颜色',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      subheading: Text(
        '选择透明度',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      wheelSubheading: Text(
        '主题颜色及透明度',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      showMaterialName: false,
      showColorName: false,
      showColorCode: true,
      copyPasteBehavior: const ColorPickerCopyPasteBehavior(
        longPressMenu: true,
      ),
      materialNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorNameTextStyle: Theme.of(context).textTheme.bodySmall,
      colorCodeTextStyle: Theme.of(context).textTheme.bodyMedium,
      colorCodePrefixStyle: Theme.of(context).textTheme.bodySmall,
      selectedPickerTypeColor: Theme.of(context).colorScheme.primary,
      customColorSwatchesAndNames: controller.colorsNameMap,
      pickersEnabled: const <ColorPickerType, bool>{
        ColorPickerType.both: false,
        ColorPickerType.primary: true,
        ColorPickerType.accent: true,
        ColorPickerType.bw: false,
        ColorPickerType.custom: true,
        ColorPickerType.wheel: true,
      },
      // customColorSwatchesAndNames: colorsNameMap,
    ).showPickerDialog(
      context,
      actionsPadding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 480, minWidth: 375, maxWidth: 420),
    );
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
                  max: 120,
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
                  spacer(20.0),
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
