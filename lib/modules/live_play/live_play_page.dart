import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'widgets/video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:pure_live/model/live_play_quality.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/live_play/live_play_controller.dart';

class LivePlayPage extends GetWidget<LivePlayController> {
  LivePlayPage({super.key});

  final SettingsService settings = Get.find<SettingsService>();
  final groupButtonController = GroupButtonController();
  @override
  Widget build(BuildContext context) {
    if (settings.enableScreenKeepOn.value) {
      WakelockPlus.toggle(enable: settings.enableScreenKeepOn.value);
    }
    return Scaffold(body: buildVideoPlayer());
  }

  Widget buildLiveResolutionsRow() {
    var resolutions = [];
    final urls = controller.playUrls;
    for (int i = 0; i < urls.length; i++) {
      for (LivePlayQuality rate in controller.qualites.value) {
        resolutions.add('线路${i + 1}${rate.quality}');
      }
    }

    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: GroupButton(
          controller: groupButtonController,
          isRadio: false,
          options: GroupButtonOptions(
            selectedTextStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white),
            unselectedTextStyle: const TextStyle(
              fontSize: 12,
              color: Colors.black,
            ),
            groupingType: GroupingType.wrap,
            direction: Axis.horizontal,
            borderRadius: BorderRadius.circular(20),
            mainGroupAlignment: MainGroupAlignment.start,
            crossGroupAlignment: CrossGroupAlignment.start,
            groupRunAlignment: GroupRunAlignment.start,
            textAlign: TextAlign.center,
            textPadding: EdgeInsets.zero,
            alignment: Alignment.center,
          ),
          buttons: resolutions,
          maxSelected: 1,
          onSelected: (val, i, selected) => handleResolutions(val, i)),
    );
  }

  handleResolutions(String val, i) {
    // 线路 清晰度
    var lineIndex = val.substring(2, 3);
    controller.currentLineIndex.value = int.parse(lineIndex) - 1;
    controller.currentQuality.value = i % controller.qualites.length;
    controller.setPlayer();
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
