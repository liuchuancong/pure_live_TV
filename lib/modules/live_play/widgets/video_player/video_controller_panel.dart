import 'dart:async';
import 'package:get/get.dart';
import 'package:pure_live/app/utils.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/plugins/barrage.dart';
import 'package:pure_live/common/widgets/settings_item_widget.dart';
import 'package:pure_live/common/widgets/button/highlight_icon_button.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/video_controller.dart';

class VideoControllerPanel extends StatefulWidget {
  final VideoController controller;

  const VideoControllerPanel({
    super.key,
    required this.controller,
  });

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
      child: Obx(() => controller.hasError.value
          ? ErrorWidget(controller: controller)
          : Stack(children: [
              DanmakuViewer(controller: controller),
              TopActionBar(
                controller: controller,
                barHeight: barHeight,
              ),
              BottomActionBar(
                controller: controller,
                barHeight: barHeight,
              ),
            ])),
    );
  }
}

class ErrorWidget extends StatelessWidget {
  const ErrorWidget({
    super.key,
    required this.controller,
  });

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              S.of(context).play_video_failed,
              style: const TextStyle(color: Colors.white, fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => controller.refresh(),
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: Colors.white.withOpacity(0.2),
            ),
            child: Text(
              S.of(context).retry,
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

// Top action bar widgets
class TopActionBar extends StatelessWidget {
  const TopActionBar({
    super.key,
    required this.controller,
    required this.barHeight,
  });

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
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Colors.transparent, Colors.black45],
            ),
          ),
          child: Row(children: [
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
            ...[
              const DatetimeInfo(),
            ],
          ]),
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

// Center widgets
// Center widgets
class DanmakuViewer extends StatelessWidget {
  const DanmakuViewer({
    super.key,
    required this.controller,
  });

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Opacity(
          opacity: controller.hideDanmaku.value ? 0 : controller.danmakuOpacity.value,
          child: controller.danmakuArea.value == 0.0
              ? Container()
              : BarrageWall(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * controller.danmakuArea.value,
                  controller: controller.danmakuController,
                  speed: controller.danmakuSpeed.value.toInt(),
                  maxBulletHeight: controller.danmakuFontSize * 1.5,
                  massiveMode: false, // disabled by default
                  child: Container(),
                ),
        ));
  }
}

// Bottom action bar widgets
class BottomActionBar extends StatelessWidget {
  const BottomActionBar({
    super.key,
    required this.controller,
    required this.barHeight,
  });

  final VideoController controller;
  final double barHeight;

  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedPositioned(
          bottom: (controller.showController.value) ? 0 : -barHeight,
          left: 0,
          right: 0,
          height: barHeight,
          duration: const Duration(milliseconds: 300),
          child: Container(
            height: barHeight,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black45],
              ),
            ),
            child: Row(
              children: <Widget>[
                PlayPauseButton(controller: controller),
                FavoriteButton(controller: controller),
                RefreshButton(controller: controller),
                DanmakuButton(controller: controller),
                SettingsButton(controller: controller),
                const Spacer(),
              ],
            ),
          ),
        ));
  }
}

class PlayPauseButton extends StatelessWidget {
  const PlayPauseButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          alignment: Alignment.center,
          padding: AppStyle.edgeInsetsA12,
          child: HighlightIconButton(
            focusNode: controller.playPauseFoucsNode,
            iconData: controller.isPlaying.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
            onTap: () {
              controller.togglePlayPause();
            },
          ),
        ));
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
      child: HighlightIconButton(
        focusNode: controller.refreshFoucsNode,
        iconData: Icons.refresh_rounded,
        onTap: () {
          controller.refresh();
        },
      ),
    );
  }
}

class DanmakuButton extends StatelessWidget {
  const DanmakuButton({
    super.key,
    required this.controller,
  });

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: AppStyle.edgeInsetsA12,
      child: Obx(() => HighlightIconButton(
            focusNode: controller.danmakuFoucsNode,
            iconData: controller.hideDanmaku.value ? CustomIcons.danmaku_close : CustomIcons.danmaku_open,
            onTap: () {
              controller.hideDanmaku.toggle();
            },
          )),
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
      child: HighlightIconButton(
        focusNode: controller.settingsFoucsNode,
        iconData: CustomIcons.danmaku_setting,
        onTap: () {
          controller.showSettting.value = true;
        },
      ),
    );
  }
}

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({
    super.key,
    required this.controller,
  });

  final VideoController controller;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  final settings = Get.find<SettingsService>();

  late bool isFavorite = settings.isFavorite(widget.controller.room);
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: AppStyle.edgeInsetsA12,
      child: Obx(() => HighlightIconButton(
            focusNode: widget.controller.favoriteFoucsNode,
            iconData: !isFavorite ? Icons.favorite_outline_outlined : Icons.favorite_rounded,
            onTap: () {
              if (isFavorite) {
                settings.removeRoom(widget.controller.room);
              } else {
                settings.addRoom(widget.controller.room);
              }
              setState(() => isFavorite = !isFavorite);
            },
          )),
    );
  }
}

class VideoFitSetting extends StatefulWidget {
  const VideoFitSetting({
    super.key,
    required this.controller,
  });

  final VideoController controller;

  @override
  State<VideoFitSetting> createState() => _VideoFitSettingState();
}

class _VideoFitSettingState extends State<VideoFitSetting> {
  late final fitmodes = {
    S.of(context).videofit_contain: BoxFit.contain,
    S.of(context).videofit_fill: BoxFit.fill,
    S.of(context).videofit_cover: BoxFit.cover,
    S.of(context).videofit_fitwidth: BoxFit.fitWidth,
    S.of(context).videofit_fitheight: BoxFit.fitHeight,
  };
  late int fitIndex = fitmodes.values.toList().indexWhere((e) => e == widget.controller.videoFit.value);

  @override
  Widget build(BuildContext context) {
    final Color color = Theme.of(context).colorScheme.primary.withOpacity(0.8);
    final isSelected = [false, false, false, false, false];
    isSelected[fitIndex] = true;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            S.of(context).settings_videofit_title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ToggleButtons(
            borderRadius: BorderRadius.circular(10),
            // selectedBorderColor: color,
            // borderColor: color,
            selectedColor: Theme.of(context).colorScheme.primary,
            fillColor: color,
            isSelected: isSelected,
            onPressed: (index) {
              setState(() {
                fitIndex = index;
                widget.controller.setVideoFit(fitmodes.values.toList()[index]);
              });
            },
            children: fitmodes.keys
                .map<Widget>((e) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(e,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          )),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

void showDanmuSettings(VideoController controller) {
  Utils.showRightDialog(
    width: 800.w,
    useSystem: true,
    child: Column(
      children: [
        AppStyle.vGap24,
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AppStyle.hGap32,
            Text(
              "设置",
              style: AppStyle.titleStyleWhite.copyWith(
                fontSize: 36.w,
                fontWeight: FontWeight.bold,
              ),
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
                child: Text(
                  "弹幕",
                  style: AppStyle.textStyleWhite.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              AppStyle.vGap24,
              SettingsItemWidget(
                foucsNode: controller.danmakuAbleFoucsNode,
                autofocus: controller.danmakuFoucsNode.isFoucsed.value,
                title: "弹幕开关",
                items: const {
                  0: "关",
                  1: "开",
                },
                value: controller.hideDanmaku.value ? 1 : 0,
                onChanged: (e) {
                  controller.hideDanmaku.value = e == 1;
                  controller.hideDanmaku.toggle();
                },
              ),
              SettingsItemWidget(
                foucsNode: controller.danmakuMergeFoucsNode,
                autofocus: controller.danmakuMergeFoucsNode.isFoucsed.value,
                title: "弹幕合并",
                items: {
                  0.0: "不合并",
                  0.25: "相似度小于25%",
                  0.5: "相似度小于50%",
                  0.75: "相似度小于75%",
                  1.0: "全部合并",
                },
                value: controller.mergeDanmuRating.value,
                onChanged: (e) {
                  controller.mergeDanmuRating.value = e;
                },
              ),
              AppStyle.vGap24,
              SettingsItemWidget(
                foucsNode: controller.danmakuSizeFoucsNode,
                autofocus: controller.danmakuSizeFoucsNode.isFoucsed.value,
                title: "弹幕大小",
                items: {
                  24.0: "24",
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
              AppStyle.vGap24,
              SettingsItemWidget(
                foucsNode: controller.danmakuSpeedFoucsNode,
                autofocus: controller.danmakuSpeedFoucsNode.isFoucsed.value,
                title: "弹幕速度",
                items: {
                  18.0: "很快",
                  14.0: "较快",
                  12.0: "快",
                  10.0: "正常",
                  8.0: "慢",
                  6.0: "较慢",
                  4.0: "很慢",
                },
                value: controller.danmakuSpeed.value,
                onChanged: (e) {
                  controller.danmakuSpeed.value = e;
                },
              ),
              AppStyle.vGap24,
              SettingsItemWidget(
                foucsNode: controller.danmakuAreaFoucsNode,
                autofocus: controller.danmakuAreaFoucsNode.isFoucsed.value,
                title: "显示区域",
                items: {
                  0.25: "1/4",
                  0.5: "1/2",
                  0.75: "3/4",
                  1.0: "全屏",
                },
                value: controller.danmakuArea.value,
                onChanged: (e) {
                  controller.danmakuArea.value = e;
                },
              ),
              AppStyle.vGap24,
              SettingsItemWidget(
                foucsNode: controller.danmakuOpacityFoucsNode,
                autofocus: controller.danmakuOpacityFoucsNode.isFoucsed.value,
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
              AppStyle.vGap24,
              SettingsItemWidget(
                foucsNode: controller.danmakuStorkeFoucsNode,
                autofocus: controller.danmakuStorkeFoucsNode.isFoucsed.value,
                title: "描边宽度",
                items: {
                  2.0: "2",
                  4.0: "4",
                  6.0: "6",
                  8.0: "8",
                  10.0: "10",
                  12.0: "12",
                  14.0: "14",
                  16.0: "16",
                },
                value: controller.danmakuFontBorder.value,
                onChanged: (e) {
                  controller.danmakuFontBorder.value = e;
                },
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class DanmakuSetting extends StatelessWidget {
  const DanmakuSetting({
    super.key,
    required this.controller,
  });

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    const TextStyle label = TextStyle(color: Colors.white);
    const TextStyle digit = TextStyle(color: Colors.white);

    return Obx(() => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                S.of(context).settings_danmaku_title,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white),
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Text('弹幕合并', style: label),
              subtitle: Text('相似度:${controller.mergeDanmuRating.value * 100}%的弹幕会被合并', style: label),
              title: Slider(
                divisions: 10,
                min: 0.0,
                max: 1.0,
                value: controller.mergeDanmuRating.value,
                onChanged: (val) => controller.mergeDanmuRating.value = val,
              ),
              trailing: Text(
                '${(controller.mergeDanmuRating.value * 100).toInt()}%',
                style: digit,
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(S.of(context).settings_danmaku_area, style: label),
              title: Slider(
                divisions: 10,
                min: 0.0,
                max: 1.0,
                value: controller.danmakuArea.value,
                onChanged: (val) => controller.danmakuArea.value = val,
              ),
              trailing: Text(
                '${(controller.danmakuArea.value * 100).toInt()}%',
                style: digit,
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(S.of(context).settings_danmaku_opacity, style: label),
              title: Slider(
                divisions: 10,
                min: 0.0,
                max: 1.0,
                value: controller.danmakuOpacity.value,
                onChanged: (val) => controller.danmakuOpacity.value = val,
              ),
              trailing: Text(
                '${(controller.danmakuOpacity.value * 100).toInt()}%',
                style: digit,
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(S.of(context).settings_danmaku_speed, style: label),
              title: Slider(
                divisions: 15,
                min: 5.0,
                max: 20.0,
                value: controller.danmakuSpeed.value,
                onChanged: (val) => controller.danmakuSpeed.value = val,
              ),
              trailing: Text(
                controller.danmakuSpeed.value.toInt().toString(),
                style: digit,
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(S.of(context).settings_danmaku_fontsize, style: label),
              title: Slider(
                divisions: 20,
                min: 10.0,
                max: 30.0,
                value: controller.danmakuFontSize.value,
                onChanged: (val) => controller.danmakuFontSize.value = val,
              ),
              trailing: Text(
                controller.danmakuFontSize.value.toInt().toString(),
                style: digit,
              ),
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Text(S.of(context).settings_danmaku_fontBorder, style: label),
              title: Slider(
                divisions: 25,
                min: 0.0,
                max: 2.5,
                value: controller.danmakuFontBorder.value,
                onChanged: (val) => controller.danmakuFontBorder.value = val,
              ),
              trailing: Text(
                controller.danmakuFontBorder.value.toStringAsFixed(2),
                style: digit,
              ),
            ),
          ],
        ));
  }
}
