import 'dart:io';
import 'package:dpad/dpad.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/tv_dialog/tv_menu_dialog.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/modules/settings/pages/font_family_manager_page.dart';

class VideoSettingsPage extends GetView<SettingsService> {
  const VideoSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final Map<String, String> resolutionMap = {
      for (var res in PlayerConsts.resolutions) res: res
    };

    return TvScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              i18n("video_settings"),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: DpadRegion(
              memoryKey: 'settings/video_settings',
              horizontalEdge: DpadEdgeBehavior.stop,
              verticalEdge: DpadEdgeBehavior.stop,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  context.buildGroupTitle(i18n("audio_settings")),
                  context.buildModernCard([
                    context.buildSwitchTile(
                      title: i18n("global_mute"),
                      subtitle: i18n("global_mute_subtitle"),
                      value: SettingsService.to.vol.globalVolumeMute,
                      icon: SettingsService.to.vol.globalVolumeMute.v ? Remix.volume_mute_line : Remix.volume_up_line,
                    ),
                    Obx(
                      () => context.buildSliderTile(
                        context,
                        icon: Remix.computer_line,
                        title: i18n("desktop_default_volume"),
                        value: SettingsService.to.vol.defaultDesktopVolume.v,
                        min: 0.0,
                        max: 100.0,
                        displayValue: "${(SettingsService.to.vol.defaultDesktopVolume.v).toStringAsFixed(0)}%",
                        onChanged: (val) => SettingsService.to.vol.defaultDesktopVolume.v = val,
                        step: 5.0,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("video_quality_settings")),
                  context.buildModernCard([
                    Obx(
                      () => context.buildMenuTile<String>(
                        icon: Remix.hd_line,
                        title: i18n("prefer_resolution"),
                        subtitle: i18n("prefer_resolution_subtitle"),
                        value: SettingsService.to.player.preferResolution.v,
                        valueMap: resolutionMap,
                        onChanged: (String newValue) {
                          SettingsService.to.player.changePreferResolution(newValue);
                        },
                        onTap: () async => showPreferResolutionSelectorDialog(resolutionMap),
                      ),
                    )
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("playback_behavior_settings")),
                  context.buildModernCard([
                    context.buildSwitchTile(
                      title: i18n('enable_fullscreen_default'),
                      subtitle: i18n('enable_fullscreen_default_subtitle'),
                      value: SettingsService.to.app.enableFullScreenDefault,
                      icon: Remix.fullscreen_line,
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("danmaku_settings")),
                  context.buildModernCard([
                    context.buildSwitchTile(
                      title: i18n('show_danmaku'),
                      subtitle: i18n('show_danmaku_subtitle'),
                      value: SettingsService.to.danmaku.enableDanmakuDisplay,
                      icon: Remix.chat_smile_2_line,
                    ),
                    Obx(
                      () => context.buildTile(
                        icon: Remix.font_size,
                        title: i18n("change_danmaku_font_family"),
                        subtitle: "${i18n("current_font_prefix")}: ${SettingsService.to.danmaku.danmakuFontFamilyName.v}",
                        onTap: () async => Get.to(() => const FontFamilyManagerPage(isDanmakuSettings: true)),
                      ),
                    ),
                    context.buildTile(
                      icon: Remix.filter_2_line,
                      title: i18n("danmaku_filter"),
                      subtitle: "",
                      onTap: () async => Get.toNamed(RoutePath.kSettingsDanmuShield),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showPreferResolutionSelectorDialog(Map<String, String> resolutionMap) async {
    final List<TvMenuItem<String>> menuItems = resolutionMap.entries.map((e) {
      return TvMenuItem<String>(
        title: e.value,
        value: e.key,
      );
    }).toList();

    final selected = await Get.dialog<String>(
      TvMenuDialog<String>(
        title: i18n("prefer_resolution"),
        items: menuItems,
        selectedValue: SettingsService.to.player.preferResolution.v,
      ),
    );

    if (selected != null) {
      SettingsService.to.player.changePreferResolution(selected);
    }
  }
}
