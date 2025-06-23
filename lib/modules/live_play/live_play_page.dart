import 'dart:async';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'widgets/video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/live_play/live_play_controller.dart';

class LivePlayPage extends GetWidget<LivePlayController> {
  LivePlayPage({super.key});
  final SettingsService settings = Get.find<SettingsService>();

  @override
  Widget build(BuildContext context) {
    if (settings.enableScreenKeepOn.value) {
      WakelockPlus.toggle(enable: true);
    }
    return BackButtonListener(
      onBackButtonPressed: onWillPop,
      child: buildVideoPlayer(),
    );
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

  Widget buildVideoPlayer() {
    return Hero(
      tag: controller.room.roomId!,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: Obx(
            () => controller.success.value
                ? VideoPlayer(controller: controller.videoController!)
                : KeyboardListener(
                    focusNode: controller.focusNode,
                    autofocus: true,
                    onKeyEvent: controller.onKeyEvent,
                    child: controller.hasError.value && controller.isActive.value == false
                        ? ErrorVideoWidget(controller: controller)
                        : !controller.getVideoSuccess.value
                            ? ErrorVideoWidget(controller: controller)
                            : Card(
                                elevation: 0,
                                margin: const EdgeInsets.all(0),
                                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                clipBehavior: Clip.antiAlias,
                                color: Get.theme.focusColor,
                                child: Obx(() => controller.isFirstLoad.value
                                    ? const Center(
                                        child: CircularProgressIndicator(
                                        color: Colors.white,
                                      ))
                                    : controller.loadTimeOut.value
                                        ? CachedNetworkImage(
                                            imageUrl: controller.currentPlayRoom.value.cover!,
                                            cacheManager: CustomCacheManager.instance,
                                            fit: BoxFit.fill,
                                            errorWidget: (context, error, stackTrace) => Center(
                                              child: Column(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  const Icon(Icons.live_tv_rounded, size: 48),
                                                  AppStyle.vGap16,
                                                  const Text(
                                                    "无法获取播放信息",
                                                    style: TextStyle(color: Colors.white, fontSize: 18),
                                                  ),
                                                  AppStyle.vGap16,
                                                  const Text(
                                                    "当前房间未开播或无法观看",
                                                    style: TextStyle(color: Colors.white, fontSize: 18),
                                                  ),
                                                  AppStyle.vGap16,
                                                  const Text(
                                                    "请按确定按钮刷新重试",
                                                    style: TextStyle(color: Colors.white, fontSize: 18),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        : TimeOutVideoWidget(
                                            controller: controller,
                                          )),
                              ),
                  ),
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
              child: Obx(() => Text(
                    '${controller.currentChannelIndex.value + 1}. ${controller.currentPlayRoom.value.platform == Sites.iptvSite ? controller.currentPlayRoom.value.title : controller.currentPlayRoom.value.nick ?? ''}',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  )),
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
                    const Text(
                      "所有线路已切换且无法播放",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const Text(
                      "请切换播放器或设置解码方式刷新重试",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const Text(
                      "如仍有问题可能该房间未开播或无法观看",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    )
                  ],
                ),
              ),
            ),
            AppStyle.vGap48,
          ],
        ));
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
              child: Obx(() => Text(
                    '${controller.currentChannelIndex.value + 1}. ${controller.currentPlayRoom.value.platform == Sites.iptvSite ? controller.currentPlayRoom.value.title : controller.currentPlayRoom.value.nick ?? ''}',
                    style: const TextStyle(
                      fontSize: 32,
                      color: Colors.white,
                    ),
                  )),
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
                    const Text(
                      "该房间未开播或已下播",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    const Text(
                      "请刷新或者切换其他直播间进行观看吧",
                      style: TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ],
                ),
              ),
            ),
            AppStyle.vGap48,
          ],
        ));
  }
}
