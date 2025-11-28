import 'dart:async';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/pkg/canvas_danmaku/danmaku_screen.dart';
import 'package:pure_live/common/widgets/settings_item_widget.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:pure_live/pkg/canvas_danmaku/models/danmaku_option.dart';
import 'package:pure_live/common/widgets/button/highlight_list_tile.dart';
import 'package:pure_live/common/widgets/button/highlight_icon_button.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/video_controller.dart';

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
      child: Obx(
        () => controller.hasError.value
            ? ErrorWidget(controller: controller)
            : Stack(
                children: [
                  ChannelVideoWidget(controller: controller, barHeight: 100),
                  DanmakuViewer(controller: controller),
                  SettingsPanel(controller: controller),
                  FavoriteChoose(controller: controller),
                  TopActionBar(controller: controller, barHeight: barHeight),
                  BottomActionBar(controller: controller, barHeight: barHeight),
                ],
              ),
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
    return Container(
      alignment: Alignment.center,
      padding: AppStyle.edgeInsetsA12,
      child: Obx(
        () => HighlightIconButton(
          useFocus: false,
          focusNode: AppFocusNode(),
          selected: controller.currentBottomClickType.value == BottomButtonClickType.playPause,
          iconData: controller.isPlaying.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onTap: () {
            controller.togglePlayPause();
          },
        ),
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
            controller.changeLine();
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
            controller.changeQuality();
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
    final fitmodes = [
      S.of(context).videofit_contain,
      S.of(context).videofit_fill,
      S.of(context).videofit_cover,
      S.of(context).videofit_fitwidth,
      S.of(context).videofit_fitheight,
    ];
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
          iconData: controller.hideDanmaku.value ? CustomIcons.danmaku_close : CustomIcons.danmaku_open,
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
          iconData: CustomIcons.danmaku_setting,
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
                "设置",
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
                Padding(
                  padding: AppStyle.edgeInsetsH20,
                  child: Text("弹幕", style: AppStyle.textStyleWhite.copyWith(fontWeight: FontWeight.bold)),
                ),
                AppStyle.vGap24,
                Obx(
                  () => SettingsItemWidget(
                    useFocus: false,
                    focusNode: AppFocusNode(),
                    key: VideoController.danmakuAbleKey,
                    selected: controller.currentDanmukuClickType.value == DanmakuSettingClickType.danmakuAble,
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
                    selected: controller.currentDanmukuClickType.value == DanmakuSettingClickType.danmakuSize,
                    title: "弹幕大小",
                    items: {
                      10.0: "10",
                      12.0: "12",
                      14.0: "14",
                      16.0: "16",
                      18.0: "18",
                      20.0: "20",
                      22.0: "22",
                      24.0: "24",
                      26.0: "26",
                      28.0: "28",
                      32.0: "32",
                      40.0: "40",
                      48.0: "48",
                      56.0: "56",
                      64.0: "64",
                      72.0: "72",
                    },
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
                    selected: controller.currentDanmukuClickType.value == DanmakuSettingClickType.danmakuSpeed,
                    title: "弹幕速度",
                    items: {
                      4.0: "速度1",
                      6.0: "速度2",
                      8.0: "速度3",
                      10.0: "速度4",
                      12.0: "速度5",
                      14.0: "速度6",
                      16.0: "速度7",
                      18.0: "速度8",
                      20.0: "速度9",
                      22.0: "速度10",
                      24.0: "速度11",
                      26.0: "速度12",
                      28.0: "速度13",
                      30.0: "速度14",
                      32.0: "速度15",
                      34.0: "速度16",
                      36.0: "速度17",
                      38.0: "速度18",
                      40.0: "速度19",
                      42.0: "速度20",
                      44.0: "速度21",
                      46.0: "速度22",
                      48.0: "速度23",
                      50.0: "速度24",
                      52.0: "速度25",
                      54.0: "速度26",
                      56.0: "速度27",
                      58.0: "速度28",
                      60.0: "速度29",
                      62.0: "速度30",
                      64.0: "速度31",
                      66.0: "速度32",
                      68.0: "速度33",
                      70.0: "速度34",
                    },
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
                    selected: controller.currentDanmukuClickType.value == DanmakuSettingClickType.danmakuArea,
                    title: "显示区域",
                    items: {0.25: "1/4", 0.5: "1/2", 0.75: "3/4", 1.0: "全屏"},
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
                    selected: controller.currentDanmukuClickType.value == DanmakuSettingClickType.danmakuOpacity,
                    title: "不透明度",
                    items: {
                      0.1: "10%",
                      0.2: "20%",
                      0.3: "30%",
                      0.4: "40%",
                      0.5: "50%",
                      0.6: "60%",
                      0.7: "70%",
                      0.8: "80%",
                      0.9: "90%",
                      1.0: "100%",
                    },
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
                    selected: controller.currentDanmukuClickType.value == DanmakuSettingClickType.danmakuStorke,
                    title: "描边宽度",
                    items: {
                      0.0: "2",
                      1.0: "4",
                      2.0: "6",
                      3.0: "8",
                      4.0: "10",
                      5.0: "12",
                      6.0: "14",
                      7.0: "16",
                      8.0: "18",
                    },
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
