import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter_svg/svg.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/consts/app_consts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/pkg/canvas_danmaku/danmaku_screen.dart';
import 'package:pure_live/common/widgets/settings_item_widget.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:pure_live/pkg/canvas_danmaku/models/danmaku_option.dart';
import 'package:pure_live/common/widgets/button/highlight_list_tile.dart';
import 'package:pure_live/common/widgets/button/highlight_icon_button.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/video_controller.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/models/video_enums.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/controller/video_constants.dart';
// 导入常量类

class VideoControllerPanel extends StatefulWidget {
  final VideoController controller;

  const VideoControllerPanel({super.key, required this.controller});

  @override
  State<StatefulWidget> createState() => _VideoControllerPanelState();
}

class _VideoControllerPanelState extends State<VideoControllerPanel> {
  static const barHeight = 56.0;

  // Video controllers
  VideoController get controller => widget.controller;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          ChannelVideoWidget(controller: controller, barHeight: 100),
          DanmakuViewer(controller: controller),
          SettingsPanel(controller: controller),
          ResolutionPanel(controller: controller),
          LinePanel(controller: controller),
          ShieldPanel(controller: controller),
          FavoriteChoose(controller: controller),
          TopActionBar(controller: controller, barHeight: barHeight),
          BottomActionBar(controller: controller, barHeight: barHeight),
        ],
      ),
    );
  }
}

class ErrorWidget extends StatelessWidget {
  const ErrorWidget({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(S.of(context).play_video_failed, style: const TextStyle(color: Colors.white, fontSize: 16)),
          ),
          ElevatedButton(
            onPressed: () => controller.refresh(),
            style: ElevatedButton.styleFrom(elevation: 0, backgroundColor: Colors.white.withValues(alpha: 0.2)),
            child: Text(S.of(context).retry, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// Top action bar widgets
class TopActionBar extends StatelessWidget {
  const TopActionBar({super.key, required this.controller, required this.barHeight});

  final VideoController controller;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AnimatedPositioned(
        top: (controller.showController.value) ? 0 : -barHeight,
        left: 0,
        right: 0,
        height: barHeight,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(color: Colors.black),
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    controller.room.title ?? '正在读取直播信息...',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 20, decoration: TextDecoration.none),
                  ),
                ),
              ),
              ...[const DatetimeInfo()],
            ],
          ),
        ),
      ),
    );
  }
}

class DatetimeInfo extends StatefulWidget {
  const DatetimeInfo({super.key});

  @override
  State<DatetimeInfo> createState() => _DatetimeInfoState();
}

class _DatetimeInfoState extends State<DatetimeInfo> {
  DateTime dateTime = DateTime.now();
  Timer? refreshDateTimer;

  @override
  void initState() {
    super.initState();
    refreshDateTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      setState(() => dateTime = DateTime.now());
    });
  }

  @override
  void dispose() {
    super.dispose();
    refreshDateTimer?.cancel();
  }

  @override
  Widget build(BuildContext context) {
    // get system time and format
    var hour = dateTime.hour.toString();
    if (hour.length < 2) hour = '0$hour';
    var minute = dateTime.minute.toString();
    if (minute.length < 2) minute = '0$minute';

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      child: Text(
        '$hour:$minute',
        style: const TextStyle(color: Colors.white, fontSize: 18, decoration: TextDecoration.none),
      ),
    );
  }
}

class DanmakuViewer extends StatelessWidget {
  const DanmakuViewer({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => DanmakuScreen(
        controller: controller.danmakuController,
        option: DanmakuOption(
          fontSize: controller.danmakuFontSize.value,
          topAreaDistance: controller.danmakuTopArea.value,
          area: controller.danmakuArea.value,
          bottomAreaDistance: controller.danmakuBottomArea.value,
          duration: controller.danmakuSpeed.value.toInt(),
          opacity: controller.danmakuOpacity.value,
          fontWeight: controller.danmakuFontBorder.value.toInt(),
        ),
      ),
    );
  }
}

// Bottom action bar widgets
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({super.key, required this.controller, required this.barHeight});

  final VideoController controller;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AnimatedPositioned(
        bottom: (controller.showController.value) ? 0 : -barHeight,
        left: 0,
        right: 0,
        height: barHeight,
        duration: const Duration(milliseconds: 300),
        child: Container(
          height: barHeight,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(color: Colors.black),
          child: Row(
            children: <Widget>[
              FavoriteButton(controller: controller),
              RefreshButton(controller: controller),
              PlayPauseButton(controller: controller),
              DanmakuButton(controller: controller),
              SettingsButton(controller: controller),
              QualiteNameButton(controller: controller),
              LineButton(controller: controller),
              BoxFitButton(controller: controller),
              ShieldButton(controller: controller),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    final manager = GlobalPlayerService.instance.playerManager;

    return Container(
      alignment: Alignment.center,
      padding: AppStyle.edgeInsetsA12,
      child: StreamBuilder<bool>(
        stream: manager.onPlaying,
        initialData: manager.isPlayingNow,
        builder: (context, snapshot) {
          final isPlaying = snapshot.data ?? false;
          return Obx(
            () => HighlightIconButton(
              useFocus: false,
              focusNode: AppFocusNode(),
              selected: controller.currentBottomClickType.value == BottomButtonClickType.playPause,
              iconData: isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
              onTap: () {
                controller.togglePlayPause();
              },
            ),
          );
        },
      ),
    );
  }
}

class LineButton extends StatelessWidget {
  const LineButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: AppStyle.edgeInsetsA12,
      child: Obx(
        () => HighlightButton(
          useFocus: false,
          focusNode: AppFocusNode(),
          selected: controller.currentBottomClickType.value == BottomButtonClickType.changeLine,
          iconData: Icons.density_small_rounded,
          onTap: () {
            // 点击弹出线路面板
            controller.showLinePanel.value = true;
          },
          text: '线路${controller.currentLineIndex + 1}',
        ),
      ),
    );
  }
}

class QualiteNameButton extends StatelessWidget {
  const QualiteNameButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: AppStyle.edgeInsetsA12,
      child: Obx(
        () => HighlightButton(
          useFocus: false,
          focusNode: AppFocusNode(),
          selected: controller.currentBottomClickType.value == BottomButtonClickType.qualityName,
          iconData: Icons.swap_vertical_circle_outlined,
          onTap: () {
            controller.showChangeNameFlag.value = true;
          },
          text: controller.qualiteName,
        ),
      ),
    );
  }
}

class BoxFitButton extends StatelessWidget {
  const BoxFitButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    final fitmodes = AppConsts.videoFitChineseTranslation;
    return Container(
      alignment: Alignment.center,
      padding: AppStyle.edgeInsetsA12,
      child: Obx(
        () => HighlightButton(
          useFocus: false,
          focusNode: AppFocusNode(),
          selected: controller.currentBottomClickType.value == BottomButtonClickType.boxFit,
          iconData: Icons.video_settings_outlined,
          onTap: () {
            controller.setVideoFit();
          },
          text: fitmodes[controller.settings.videoFitIndex.value],
        ),
      ),
    );
  }
}

class ShieldButton extends StatelessWidget {
  const ShieldButton({super.key, required this.controller});
  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: AppStyle.edgeInsetsA12,
      child: Obx(
        () => HighlightButton(
          useFocus: false,
          focusNode: AppFocusNode(),
          selected: controller.currentBottomClickType.value == BottomButtonClickType.shieldSetting,
          iconData: Icons.dynamic_feed_rounded,
          text: '弹幕过滤',
          onTap: () {
            controller.showShieldSetting();
          },
        ),
      ),
    );
  }
}

class ShieldPanel extends StatelessWidget {
  const ShieldPanel({super.key, required this.controller});
  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      return AnimatedPositioned(
        duration: const Duration(milliseconds: 300),
        right: controller.showQrCodePanel.value ? 0 : -800.w,
        top: 0,
        bottom: 0,
        child: Container(
          width: 800.w,
          decoration: BoxDecoration(
            color: Get.theme.cardColor.withValues(alpha: 0.98),
            border: Border(
              left: BorderSide(color: Colors.white10, width: 1.w),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 32.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header with Return Button
              Row(
                children: [
                  AppStyle.hGap24,
                  Text(
                    "屏蔽设置",
                    style: AppStyle.titleStyleWhite.copyWith(fontSize: 32.w, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              AppStyle.vGap32,

              Align(
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(32.w),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16.w)),
                      child: QrImageView(
                        data: controller.fullServerUrl.value,
                        version: QrVersions.auto,
                        size: 400.w, // 3. Increased QR size to match the 800 width
                        eyeStyle: const QrEyeStyle(color: Colors.black, eyeShape: QrEyeShape.square),
                        dataModuleStyle: const QrDataModuleStyle(
                          color: Colors.black,
                          dataModuleShape: QrDataModuleShape.square,
                        ),
                      ),
                    ),
                    AppStyle.vGap16,
                    Text(
                      "手机扫码 远程增删",
                      style: AppStyle.textStyleWhite.copyWith(
                        fontSize: 28.w,
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              AppStyle.vGap24,
              const Divider(color: Colors.white12),
              AppStyle.vGap16,

              // 3. Shield List (Wrap Layout)
              Expanded(
                child: SingleChildScrollView(
                  child: Obx(
                    () => Wrap(
                      spacing: 12.w,
                      runSpacing: 12.h,
                      children: controller.settings.shieldList.asMap().entries.map((entry) {
                        final int index = entry.key;
                        final String value = entry.value;
                        if (index >= controller.shieldFocusNodes.length) return const SizedBox.shrink();
                        return HighlightButton(
                          focusNode: controller.shieldFocusNodes[index],
                          selected: controller.shieldFocusNodes[index].hasFocus,
                          text: entry.value,
                          // Customizing icon to show delete intent
                          iconData: Icons.close_rounded,
                          onTap: () {
                            controller.removeShieldWord(value);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class RefreshButton extends StatelessWidget {
  const RefreshButton({super.key, required this.controller});

  final VideoController controller;
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: AppStyle.edgeInsetsA12,
      child: Obx(
        () => HighlightIconButton(
          useFocus: false,
          focusNode: AppFocusNode(),
          selected: controller.currentBottomClickType.value == BottomButtonClickType.refresh,
          iconData: Icons.refresh_rounded,
          onTap: () {
            controller.refresh();
          },
        ),
      ),
    );
  }
}

class DanmakuButton extends StatelessWidget {
  const DanmakuButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: AppStyle.edgeInsetsA12,
      child: Obx(
        () => HighlightIconButton(
          useFocus: false,
          focusNode: AppFocusNode(),
          selected: controller.currentBottomClickType.value == BottomButtonClickType.danmaku,
          icon: controller.hideDanmaku.value
              ? SvgPicture.asset(
                  width: 60.w,
                  'assets/images/video/danmu_close.svg',
                  // ignore: deprecated_member_use
                  color: controller.currentBottomClickType.value == BottomButtonClickType.danmaku
                      ? Colors.black
                      : Colors.white,
                )
              : SvgPicture.asset(
                  'assets/images/video/danmu_open.svg',
                  // ignore: deprecated_member_use
                  color: controller.currentBottomClickType.value == BottomButtonClickType.danmaku
                      ? Colors.black
                      : Colors.white,
                  width: 60.w,
                ),
          onTap: () {
            controller.hideDanmaku.toggle();
          },
        ),
      ),
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key, required this.controller});

  final VideoController controller;
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: AppStyle.edgeInsetsA12,
      child: Obx(
        () => HighlightIconButton(
          useFocus: false,
          focusNode: AppFocusNode(),
          selected: controller.currentBottomClickType.value == BottomButtonClickType.settings,
          icon: SvgPicture.asset(
            'assets/images/video/danmu_setting.svg',
            width: 60.w,
            // ignore: deprecated_member_use
            color: controller.currentBottomClickType.value == BottomButtonClickType.settings
                ? Colors.black
                : Colors.white,
          ),
          onTap: () {
            controller.showSettting.value = true;
          },
        ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.controller});
  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: AppStyle.edgeInsetsA12,
      child: Obx(
        () => HighlightButton(
          useFocus: false,
          text: !controller.settings.isFavorite(controller.room) ? '未关注' : "已关注",
          focusNode: AppFocusNode(),
          selected: controller.currentBottomClickType.value == BottomButtonClickType.favorite,
          iconData: !controller.settings.isFavorite(controller.room)
              ? Icons.highlight_remove_outlined
              : Icons.add_task_rounded,
          onTap: () {
            if (controller.settings.isFavorite(controller.room)) {
              controller.settings.removeRoom(controller.room);
            } else {
              controller.settings.addRoom(controller.room);
            }
          },
        ),
      ),
    );
  }
}

class SettingsPanel extends StatelessWidget {
  const SettingsPanel({super.key, required this.controller});

  final VideoController controller;

  static const double width = 380;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AnimatedPositioned(
        top: 0,
        bottom: 0,
        right: controller.showSettting.value ? 0 : -width,
        width: width,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: AppStyle.edgeInsetsA12,
          child: DanmakuSetting(controller: controller),
        ),
      ),
    );
  }
}

class DanmakuSetting extends StatelessWidget {
  const DanmakuSetting({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Get.theme.cardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          AppStyle.vGap24,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppStyle.hGap32,
              Text(
                "弹幕设置",
                style: AppStyle.titleStyleWhite.copyWith(fontSize: 36.w, fontWeight: FontWeight.bold),
              ),
              AppStyle.hGap24,
              const Spacer(),
            ],
          ),
          Expanded(
            child: ListView(
              padding: AppStyle.edgeInsetsA48,
              children: [
                AppStyle.vGap24,
                Obx(
                  () => SettingsItemWidget(
                    useFocus: false,
                    focusNode: AppFocusNode(),
                    key: VideoController.danmakuAbleKey,
                    selected: controller.currentDanmakuClickType.value == DanmakuSettingClickType.danmakuAble,
                    title: "弹幕开关",
                    items: const {0: "关", 1: "开"},
                    value: controller.hideDanmaku.value ? 0 : 1,
                    onChanged: (e) {
                      controller.hideDanmaku.toggle();
                    },
                  ),
                ),
                AppStyle.vGap24,
                Obx(
                  () => SettingsItemWidget(
                    useFocus: false,
                    focusNode: AppFocusNode(),
                    selected: controller.currentDanmakuClickType.value == DanmakuSettingClickType.danmakuSize,
                    title: "弹幕大小",
                    // 使用常量类定义
                    items: DanmakuConstants.sizeMap,
                    value: controller.danmakuFontSize.value,
                    onChanged: (e) {
                      controller.danmakuFontSize.value = e;
                    },
                  ),
                ),
                AppStyle.vGap24,
                Obx(
                  () => SettingsItemWidget(
                    useFocus: false,
                    focusNode: AppFocusNode(),
                    selected: controller.currentDanmakuClickType.value == DanmakuSettingClickType.danmakuSpeed,
                    title: "弹幕速度",
                    // 使用常量类定义
                    items: DanmakuConstants.speedMap,
                    value: controller.danmakuSpeed.value,
                    onChanged: (e) {
                      controller.danmakuSpeed.value = e;
                    },
                  ),
                ),
                AppStyle.vGap24,
                Obx(
                  () => SettingsItemWidget(
                    useFocus: false,
                    focusNode: AppFocusNode(),
                    selected: controller.currentDanmakuClickType.value == DanmakuSettingClickType.danmakuArea,
                    title: "显示区域",
                    // 使用常量类定义
                    items: DanmakuConstants.areaMap,
                    value: controller.danmakuArea.value,
                    onChanged: (e) {
                      controller.danmakuArea.value = e;
                    },
                  ),
                ),
                AppStyle.vGap24,
                Obx(
                  () => SettingsItemWidget(
                    useFocus: false,
                    focusNode: AppFocusNode(),
                    selected: controller.currentDanmakuClickType.value == DanmakuSettingClickType.danmakuTopArea,
                    title: "距离顶部",
                    // 使用常量类定义
                    items: DanmakuConstants.distanceMap,
                    value: controller.danmakuTopArea.value,
                    onChanged: (e) {
                      controller.danmakuTopArea.value = e;
                    },
                  ),
                ),
                AppStyle.vGap24,
                Obx(
                  () => SettingsItemWidget(
                    useFocus: false,
                    focusNode: AppFocusNode(),
                    selected: controller.currentDanmakuClickType.value == DanmakuSettingClickType.danmakuBottomArea,
                    title: "距离底部",
                    // 使用常量类定义
                    items: DanmakuConstants.distanceMap,
                    value: controller.danmakuBottomArea.value,
                    onChanged: (e) {
                      controller.danmakuBottomArea.value = e;
                    },
                  ),
                ),
                AppStyle.vGap24,
                Obx(
                  () => SettingsItemWidget(
                    useFocus: false,
                    focusNode: AppFocusNode(),
                    selected: controller.currentDanmakuClickType.value == DanmakuSettingClickType.danmakuOpacity,
                    title: "不透明度",
                    // 使用常量类定义
                    items: DanmakuConstants.areaMap,
                    value: controller.danmakuOpacity.value,
                    onChanged: (e) {
                      controller.danmakuOpacity.value = e;
                    },
                  ),
                ),
                AppStyle.vGap24,
                Obx(
                  () => SettingsItemWidget(
                    useFocus: false,
                    focusNode: AppFocusNode(),
                    selected: controller.currentDanmakuClickType.value == DanmakuSettingClickType.danmakuStorke,
                    title: "描边宽度",
                    // 使用常量类定义
                    items: DanmakuConstants.strokeMap,
                    value: controller.danmakuFontBorder.value,
                    onChanged: (e) {
                      controller.danmakuFontBorder.value = e;
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ResolutionPanel extends StatelessWidget {
  const ResolutionPanel({super.key, required this.controller});

  final VideoController controller;

  static const double width = 380;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AnimatedPositioned(
        top: 0,
        bottom: 0,
        right: controller.showQualityPanel.value ? 0 : -width,
        width: width,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: AppStyle.edgeInsetsA12,
          child: ResolutionSetting(controller: controller),
        ),
      ),
    );
  }
}

class ResolutionSetting extends StatelessWidget {
  const ResolutionSetting({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Get.theme.cardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          AppStyle.vGap24,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppStyle.hGap32,
              Text(
                "清晰度设置",
                style: AppStyle.titleStyleWhite.copyWith(fontSize: 36.w, fontWeight: FontWeight.bold),
              ),
              AppStyle.hGap24,
              const Spacer(),
            ],
          ),
          Expanded(
            child: Column(
              children: controller.qualites.asMap().entries.map((e) {
                var quality = e.value;
                return Obx(() {
                  return Padding(
                    padding: AppStyle.edgeInsetsA24,
                    child: HighlightButton(
                      text: quality.quality,
                      focusNode: AppFocusNode(),
                      selected: controller.qualityCurrentIndex.value == e.key,
                    ),
                  );
                });
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class LinePanel extends StatelessWidget {
  const LinePanel({super.key, required this.controller});

  final VideoController controller;

  static const double width = 380;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AnimatedPositioned(
        top: 0,
        bottom: 0,
        right: controller.showLinePanel.value ? 0 : -width,
        width: width,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: AppStyle.edgeInsetsA12,
          child: LineSetting(controller: controller),
        ),
      ),
    );
  }
}

class LineSetting extends StatelessWidget {
  const LineSetting({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Get.theme.cardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          AppStyle.vGap24,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppStyle.hGap32,
              Text(
                "线路切换",
                style: AppStyle.titleStyleWhite.copyWith(fontSize: 36.w, fontWeight: FontWeight.bold),
              ),
              AppStyle.hGap24,
              const Spacer(),
            ],
          ),
          Expanded(
            child: ListView(
              padding: AppStyle.edgeInsetsA48,
              children: List.generate(
                controller.playUrls.length,
                (index) => Obx(() {
                  return Padding(
                    padding: AppStyle.edgeInsetsA24,
                    child: HighlightButton(
                      text: "线路${index + 1}",
                      focusNode: AppFocusNode(),
                      selected: controller.lineCurrentIndex.value == index,
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChannelVideoWidget extends StatelessWidget {
  const ChannelVideoWidget({super.key, required this.controller, required this.barHeight});

  final VideoController controller;
  final double barHeight;
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      LiveRoom room = controller.settings.currentPlayList[controller.settings.currentPlayListNodeIndex.value];
      return AnimatedPositioned(
        top: controller.showChangeNameFlag.value ? 0 : -barHeight,
        left: 0,
        right: 0,
        height: barHeight,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: barHeight,
          alignment: Alignment.centerLeft,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: const BoxDecoration(color: Colors.black),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppStyle.vGap24,
              Padding(
                padding: AppStyle.edgeInsetsA24,
                child: Text(
                  '${controller.settings.currentPlayListNodeIndex.value + 1}. ${room.platform == Sites.iptvSite ? room.title : room.nick!}',
                  style: const TextStyle(fontSize: 32, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }
}

class FavoriteChoose extends StatelessWidget {
  const FavoriteChoose({super.key, required this.controller});

  final VideoController controller;

  static const double width = 450;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => AnimatedPositioned(
        top: 0,
        bottom: 0,
        right: controller.showPlayListPanel.value ? 0 : -width,
        width: width,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: AppStyle.edgeInsetsA12,
          child: FavoriteChoosePanel(controller: controller),
        ),
      ),
    );
  }
}

class FavoriteChoosePanel extends StatelessWidget {
  const FavoriteChoosePanel({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Get.theme.cardColor, borderRadius: BorderRadius.circular(10)),
      child: Column(
        children: [
          AppStyle.vGap24,
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              AppStyle.hGap32,
              Text(
                "播放列表",
                style: AppStyle.titleStyleWhite.copyWith(fontSize: 36.w, fontWeight: FontWeight.bold),
              ),
              AppStyle.hGap24,
              const Spacer(),
            ],
          ),
          Expanded(
            child: ListView(
              controller: controller.scrollController,
              padding: AppStyle.edgeInsetsA48,
              children: List.generate(
                controller.settings.currentPlayList.length,
                (index) => Obx(
                  () => SizedBox(
                    height: 100,
                    child: HighlightListTile(
                      title: controller.settings.currentPlayList[index].title,
                      trailing: HighlightButton(
                        useFocus: false,
                        text: !controller.settings.isFavorite(controller.settings.currentPlayList[index])
                            ? '未关注'
                            : "已关注",
                        focusNode: AppFocusNode(),
                        selected: controller.beforePlayNodeIndex.value == index,
                        iconData: !controller.settings.isFavorite(controller.settings.currentPlayList[index])
                            ? Icons.highlight_remove_outlined
                            : Icons.add_task_rounded,
                        onTap: () {
                          if (controller.settings.isFavorite(controller.settings.currentPlayList[index])) {
                            controller.settings.removeRoom(controller.settings.currentPlayList[index]);
                          } else {
                            controller.settings.addRoom(controller.settings.currentPlayList[index]);
                          }
                        },
                      ),
                      leading: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: const BorderRadius.all(Radius.circular(8.0)),
                          image: DecorationImage(
                            image: CachedNetworkImageProvider(controller.settings.currentPlayList[index].avatar),
                            fit: BoxFit.fill,
                          ),
                        ),
                      ),
                      subtitle: controller.settings.currentPlayList[index].nick,
                      focusNode: AppFocusNode(),
                      useFocus: false,
                      selected: controller.beforePlayNodeIndex.value == index,
                      onTap: () {
                        // controller.getImage();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
