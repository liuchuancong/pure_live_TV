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
  final groupButtonController = GroupButtonController();

  @override
  Widget build(BuildContext context) {
    if (settings.enableScreenKeepOn.value) {
      WakelockPlus.toggle(enable: true);
    }
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (!didPop) {
          //双击返回键退出
          if (controller.doubleClickExit) {
            controller.doubleClickTimer?.cancel();
            Get.back();
            return;
          }
          controller.doubleClickExit = true;
          SmartDialog.showToast("再按一次退出播放器");
          controller.doubleClickTimer = Timer(const Duration(seconds: 2), () {
            controller.doubleClickExit = false;
            controller.doubleClickTimer!.cancel();
          });
        }
      },
      child: buildVideoPlayer(),
    );
  }

  handleResolutions() {}

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
                : Card(
                    elevation: 0,
                    margin: const EdgeInsets.all(0),
                    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    clipBehavior: Clip.antiAlias,
                    color: Get.theme.focusColor,
                    child: CachedNetworkImage(
                      imageUrl: controller.room.cover!,
                      cacheManager: CustomCacheManager.instance,
                      fit: BoxFit.fill,
                      errorWidget: (context, error, stackTrace) => const Center(
                        child: Icon(Icons.live_tv_rounded, size: 48),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
