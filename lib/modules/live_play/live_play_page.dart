import 'dart:async';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'widgets/video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:pure_live/modules/live_play/live_play_controller.dart';

class LivePlayPage extends GetWidget<LivePlayController> {
  LivePlayPage({super.key});
  final SettingsService settings = Get.find<SettingsService>();

  @override
  Widget build(BuildContext context) {
    if (settings.enableScreenKeepOn.value) {
      WakelockPlus.toggle(enable: true);
    }
    return BackButtonListener(onBackButtonPressed: onWillPop, child: buildVideoPlayer());
  }

  Future<bool> onWillPop() async {
    try {
      var exit = await controller.onBackPressed();
      if (exit) {
        Navigator.of(Get.context!).pop();
      }
    } catch (e) {
      Navigator.of(Get.context!).pop();
    }
    return true;
  }

  Widget buildLoading() {
    return Material(
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          Container(
            color: Colors.black, // 设置你想要的背景色
          ),
          Container(
            color: Colors.black,
            child: const Center(
              child: SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 6, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildVideoPlayer() {
    return Hero(
      tag: controller.room.roomId!,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Obx(
            () => controller.hasError.value
                ? ErrorVideoWidget(controller: controller)
                : controller.success.value
                ? VideoPlayer(controller: controller.videoController!)
                : buildLoading(),
          ),
        ),
      ),
    );
  }
}

class ErrorVideoWidget extends StatelessWidget {
  const ErrorVideoWidget({super.key, required this.controller});

  final LivePlayController controller;
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStyle.vGap24,
          Padding(
            padding: AppStyle.edgeInsetsA24,
            child: Obx(
              () => Text(
                '${controller.currentChannelIndex.value + 1}. ${controller.currentPlayRoom.value.platform == Sites.iptvSite ? controller.currentPlayRoom.value.title : controller.currentPlayRoom.value.nick ?? ''}',
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      S.of(context).play_video_failed,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  AppStyle.vGap24,
                  const Text("所有线路已切换且无法播放", style: TextStyle(color: Colors.white, fontSize: 18)),
                  const Text("请切换播放器或设置解码方式刷新重试", style: TextStyle(color: Colors.white, fontSize: 18)),
                  const Text("如仍有问题可能该房间未开播或无法观看", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
          ),
          AppStyle.vGap48,
        ],
      ),
    );
  }
}

class TimeOutVideoWidget extends StatelessWidget {
  const TimeOutVideoWidget({super.key, required this.controller});

  final LivePlayController controller;
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppStyle.vGap24,
          Padding(
            padding: AppStyle.edgeInsetsA24,
            child: Obx(
              () => Text(
                '${controller.currentChannelIndex.value + 1}. ${controller.currentPlayRoom.value.platform == Sites.iptvSite ? controller.currentPlayRoom.value.title : controller.currentPlayRoom.value.nick ?? ''}',
                style: const TextStyle(fontSize: 32, color: Colors.white),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      S.of(context).play_video_failed,
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                  ),
                  AppStyle.vGap24,
                  const Text("该房间未开播或已下播", style: TextStyle(color: Colors.white, fontSize: 18)),
                  const Text("请刷新或者切换其他直播间进行观看吧", style: TextStyle(color: Colors.white, fontSize: 18)),
                ],
              ),
            ),
          ),
          AppStyle.vGap48,
        ],
      ),
    );
  }
}
