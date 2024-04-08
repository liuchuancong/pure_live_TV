import 'dart:io';
import 'dart:math';
import 'dart:async';
import 'package:get/get.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/plugins/barrage.dart';
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
  double currentVolumn = 1.0;
  bool showVolumn = true;
  Timer? _hideVolumn;
  void restartTimer() {
    _hideVolumn?.cancel();
    _hideVolumn = Timer(const Duration(seconds: 1), () {
      setState(() => showVolumn = true);
    });
    setState(() => showVolumn = false);
  }

  @override
  void dispose() {
    _hideVolumn?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.enableController();
    });
  }

  void updateVolumn(double? volume) {
    restartTimer();
    setState(() {
      currentVolumn = volume!;
    });
  }

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    iconData = currentVolumn <= 0
        ? Icons.volume_mute
        : currentVolumn < 0.5
            ? Icons.volume_down
            : Icons.volume_up;
    return Material(
      type: MaterialType.transparency,
      child: CallbackShortcuts(
        bindings: {
          const SingleActivator(LogicalKeyboardKey.mediaPlay): () => controller.mediaPlayerController.player.play(),
          const SingleActivator(LogicalKeyboardKey.mediaPause): () => controller.mediaPlayerController.player.pause(),
          const SingleActivator(LogicalKeyboardKey.mediaPlayPause): () =>
              controller.mediaPlayerController.player.playOrPause(),
          const SingleActivator(LogicalKeyboardKey.space): () => controller.mediaPlayerController.player.playOrPause(),
          const SingleActivator(LogicalKeyboardKey.keyR): () => controller.refresh(),
          const SingleActivator(LogicalKeyboardKey.arrowUp): () async {
            double? volume = 1.0;
            volume = await controller.volumn();
            volume = (volume! + 0.05);
            volume = min(volume, 1.0);
            volume = max(volume, 0.0);
            controller.setVolumn(volume);
            updateVolumn(volume);
          },
          const SingleActivator(LogicalKeyboardKey.arrowDown): () async {
            double? volume = 1.0;
            volume = await controller.volumn();
            volume = (volume! - 0.05);
            volume = min(volume, 1.0);
            volume = max(volume, 0.0);
            controller.setVolumn(volume);
            updateVolumn(volume);
          },
          const SingleActivator(LogicalKeyboardKey.escape): () => controller.toggleFullScreen(),
        },
        child: Focus(
          autofocus: true,
          child: Obx(() => controller.hasError.value
              ? ErrorWidget(controller: controller)
              : MouseRegion(
                  onHover: (event) => controller.enableController(),
                  onExit: (event) {
                    controller.showControllerTimer?.cancel();
                    controller.showController.toggle();
                  },
                  child: Stack(children: [
                    Container(
                      color: Colors.transparent,
                      alignment: Alignment.center,
                      child: AnimatedOpacity(
                        opacity: !showVolumn ? 0.8 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        child: Card(
                          color: Colors.black,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Icon(iconData, color: Colors.white),
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, right: 4),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: SizedBox(
                                      width: 100,
                                      height: 20,
                                      child: LinearProgressIndicator(
                                        value: currentVolumn,
                                        backgroundColor: Colors.white38,
                                        valueColor: AlwaysStoppedAnimation(
                                          Theme.of(context).indicatorColor,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    DanmakuViewer(controller: controller),
                    GestureDetector(
                        onTap: () {
                          if (controller.showSettting.value) {
                            controller.showSettting.toggle();
                          } else {
                            controller.isPlaying.value ? controller.enableController() : controller.togglePlayPause();
                          }
                        },
                        onDoubleTap: () => controller.isWindowFullscreen.value
                            ? controller.toggleWindowFullScreen()
                            : controller.toggleFullScreen(),
                        child: BrightnessVolumnDargArea(
                          controller: controller,
                        )),
                    SettingsPanel(
                      controller: controller,
                    ),
                    LockButton(controller: controller),
                    TopActionBar(
                      controller: controller,
                      barHeight: barHeight,
                    ),
                    BottomActionBar(
                      controller: controller,
                      barHeight: barHeight,
                    ),
                  ]),
                )),
        ),
      ),
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
        top: (!controller.isPipMode.value &&
                !controller.showSettting.value &&
                controller.showController.value &&
                !controller.showLocked.value)
            ? 0
            : -barHeight,
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
            if (controller.fullscreenUI) BackButton(controller: controller),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  controller.room.title!,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 16, decoration: TextDecoration.none),
                ),
              ),
            ),
            if (controller.fullscreenUI) ...[
              const DatetimeInfo(),
              BatteryInfo(controller: controller),
            ],
            if (!controller.fullscreenUI && controller.supportPip && controller.videoPlayerIndex == 0)
              PIPButton(controller: controller),
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
        style: const TextStyle(color: Colors.white, fontSize: 14, decoration: TextDecoration.none),
      ),
    );
  }
}

class BatteryInfo extends StatefulWidget {
  const BatteryInfo({super.key, required this.controller});

  final VideoController controller;

  @override
  State<BatteryInfo> createState() => _BatteryInfoState();
}

class _BatteryInfoState extends State<BatteryInfo> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.all(12),
      child: Container(
        width: 35,
        height: 15,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.4),
          border: Border.all(color: Colors.white),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Obx(() => Text(
                '${widget.controller.batteryLevel.value}',
                style: const TextStyle(color: Colors.white, fontSize: 9, decoration: TextDecoration.none),
              )),
        ),
      ),
    );
  }
}

class BackButton extends StatelessWidget {
  const BackButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () =>
          controller.isWindowFullscreen.value ? controller.toggleWindowFullScreen() : controller.toggleFullScreen(),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: const Icon(
          Icons.arrow_back_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}

class PIPButton extends StatelessWidget {
  const PIPButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.enterPipMode(context),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: const Icon(
          CustomIcons.float_window,
          color: Colors.white,
        ),
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

class BrightnessVolumnDargArea extends StatefulWidget {
  const BrightnessVolumnDargArea({
    super.key,
    required this.controller,
  });

  final VideoController controller;

  @override
  State<BrightnessVolumnDargArea> createState() => BrightnessVolumnDargAreaState();
}

class BrightnessVolumnDargAreaState extends State<BrightnessVolumnDargArea> {
  VideoController get controller => widget.controller;

  // Darg bv ui control
  Timer? _hideBVTimer;
  bool _hideBVStuff = true;
  bool _isDargLeft = true;
  double _updateDargVarVal = 1.0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _hideBVTimer?.cancel();
    super.dispose();
  }

  void updateVolumn(double? volume) {
    _isDargLeft = false;
    _cancelAndRestartHideBVTimer();
    setState(() {
      _updateDargVarVal = volume!;
    });
  }

  void _cancelAndRestartHideBVTimer() {
    _hideBVTimer?.cancel();
    _hideBVTimer = Timer(const Duration(seconds: 1), () {
      setState(() => _hideBVStuff = true);
    });
    setState(() => _hideBVStuff = false);
  }

  void _onVerticalDragUpdate(Offset postion, Offset delta) async {
    if (controller.showLocked.value) return;
    if (delta.distance < 0.2) return;

    // fix darg left change to switch bug
    final width = MediaQuery.of(context).size.width;
    final dargLeft = (postion.dx > (width / 2)) ? false : true;
    // disable windows brightness
    if (Platform.isWindows && dargLeft) return;
    if (_hideBVStuff || _isDargLeft != dargLeft) {
      _isDargLeft = dargLeft;
      if (_isDargLeft) {
        await controller.brightness().then((double v) {
          setState(() => _updateDargVarVal = v);
        });
      } else {
        await controller.volumn().then((double? v) {
          setState(() => _updateDargVarVal = v!);
        });
      }
    }
    _cancelAndRestartHideBVTimer();

    double dragRange =
        (delta.direction < 0 || delta.direction > pi) ? _updateDargVarVal + 0.01 : _updateDargVarVal - 0.01;
    // 是否溢出
    dragRange = min(dragRange, 1.0);
    dragRange = max(dragRange, 0.0);
    // 亮度 & 音量
    if (_isDargLeft) {
      controller.setBrightness(dragRange);
    } else {
      controller.setVolumn(dragRange);
    }
    setState(() => _updateDargVarVal = dragRange);
  }

  @override
  Widget build(BuildContext context) {
    IconData iconData;
    if (_isDargLeft) {
      iconData = _updateDargVarVal <= 0
          ? Icons.brightness_low
          : _updateDargVarVal < 0.5
              ? Icons.brightness_medium
              : Icons.brightness_high;
    } else {
      iconData = _updateDargVarVal <= 0
          ? Icons.volume_mute
          : _updateDargVarVal < 0.5
              ? Icons.volume_down
              : Icons.volume_up;
    }

    return Listener(
      onPointerSignal: (event) {
        if (event is PointerScrollEvent) {
          _onVerticalDragUpdate(event.localPosition, event.scrollDelta);
        }
      },
      child: GestureDetector(
        onVerticalDragUpdate: (details) => _onVerticalDragUpdate(details.localPosition, details.delta),
        child: Container(
          color: Colors.transparent,
          alignment: Alignment.center,
          child: AnimatedOpacity(
            opacity: !_hideBVStuff ? 0.8 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Card(
              color: Colors.black,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Icon(iconData, color: Colors.white),
                    Padding(
                      padding: const EdgeInsets.only(left: 8, right: 4),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 100,
                          height: 20,
                          child: LinearProgressIndicator(
                            value: _updateDargVarVal,
                            backgroundColor: Colors.white38,
                            valueColor: AlwaysStoppedAnimation(
                              Theme.of(context).indicatorColor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class LockButton extends StatelessWidget {
  const LockButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedOpacity(
          opacity: (!controller.isPipMode.value &&
                  !controller.showSettting.value &&
                  controller.fullscreenUI &&
                  controller.showController.value)
              ? 0.9
              : 0.0,
          duration: const Duration(milliseconds: 300),
          child: Align(
            alignment: Alignment.centerRight,
            child: AbsorbPointer(
              absorbing: !controller.showController.value,
              child: Container(
                margin: const EdgeInsets.only(right: 20.0),
                child: IconButton(
                  onPressed: () => controller.showLocked.toggle(),
                  icon: Icon(
                    controller.showLocked.value ? Icons.lock_rounded : Icons.lock_open_rounded,
                    size: 28,
                  ),
                  color: Colors.white,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black38,
                    shape: const StadiumBorder(),
                    minimumSize: const Size(50, 50),
                  ),
                ),
              ),
            ),
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
          bottom: (!controller.isPipMode.value &&
                  !controller.showSettting.value &&
                  controller.showController.value &&
                  !controller.showLocked.value)
              ? 0
              : -barHeight,
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
                RefreshButton(controller: controller),
                DanmakuButton(controller: controller),
                FavoriteButton(controller: controller),
                if (controller.isFullscreen.value) SettingsButton(controller: controller),
                if (controller.supportPip && controller.isFullscreen.value) ScreenToggleButton(controller: controller),
                const Spacer(),
                if (controller.supportWindowFull && !controller.isFullscreen.value)
                  ExpandWindowButton(controller: controller),
                if (!controller.isWindowFullscreen.value) ExpandButton(controller: controller),
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
    return GestureDetector(
      onTap: () => controller.togglePlayPause(),
      child: Obx(() => Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(12),
            child: Icon(
              controller.isPlaying.value ? Icons.pause_rounded : Icons.play_arrow_rounded,
              color: Colors.white,
            ),
          )),
    );
  }
}

class RefreshButton extends StatelessWidget {
  const RefreshButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.refresh(),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: const Icon(
          Icons.refresh_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ScreenToggleButton extends StatelessWidget {
  const ScreenToggleButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() => GestureDetector(
          onTap: () =>
              controller.isVertical.value ? controller.setLandscapeOrientation() : controller.setPortraitOrientation(),
          child: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.all(12),
            child: Icon(
              controller.isVertical.value ? Icons.crop_landscape : Icons.crop_portrait,
              color: Colors.white,
            ),
          ),
        ));
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
    return GestureDetector(
      onTap: () => controller.hideDanmaku.toggle(),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Obx(() => Icon(
              controller.hideDanmaku.value ? CustomIcons.danmaku_close : CustomIcons.danmaku_open,
              color: Colors.white,
            )),
      ),
    );
  }
}

class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.showSettting.toggle(),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: const Icon(
          CustomIcons.danmaku_setting,
          color: Colors.white,
        ),
      ),
    );
  }
}

class ExpandWindowButton extends StatelessWidget {
  const ExpandWindowButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.toggleWindowFullScreen(),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: RotatedBox(
          quarterTurns: 1,
          child: Obx(() => Icon(
                controller.isWindowFullscreen.value ? Icons.unfold_less_rounded : Icons.unfold_more_rounded,
                color: Colors.white,
                size: 26,
              )),
        ),
      ),
    );
  }
}

class ExpandButton extends StatelessWidget {
  const ExpandButton({super.key, required this.controller});

  final VideoController controller;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => controller.toggleFullScreen(),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Obx(() => Icon(
              controller.isFullscreen.value ? Icons.fullscreen_exit_rounded : Icons.fullscreen_rounded,
              color: Colors.white,
              size: 26,
            )),
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
    return GestureDetector(
      onTap: () {
        if (isFavorite) {
          settings.removeRoom(widget.controller.room);
        } else {
          settings.addRoom(widget.controller.room);
        }
        setState(() => isFavorite = !isFavorite);
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(12),
        child: Icon(
          !isFavorite ? Icons.favorite_outline_outlined : Icons.favorite_rounded,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Settings panel widgets
class SettingsPanel extends StatelessWidget {
  const SettingsPanel({
    super.key,
    required this.controller,
  });

  final VideoController controller;

  static const double width = 380;

  @override
  Widget build(BuildContext context) {
    return Obx(() => AnimatedPositioned(
          top: 0,
          bottom: 0,
          right: controller.showSettting.value ? 0 : -width,
          width: width,
          duration: const Duration(milliseconds: 500),
          child: Card(
            color: Colors.black.withOpacity(0.8),
            child: SizedBox(
              width: width,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  VideoFitSetting(controller: controller),
                  DanmakuSetting(controller: controller),
                ],
              ),
            ),
          ),
        ));
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
