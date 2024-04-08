import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
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
    return Scaffold(
        appBar: AppBar(
          title: Row(children: [
            CircleAvatar(
              foregroundImage: controller.room.avatar!.isEmpty ? null : NetworkImage(controller.room.avatar!),
              radius: 13,
              backgroundColor: Theme.of(context).disabledColor,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.room.nick!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                Text(
                  controller.room.area!.isEmpty
                      ? controller.room.platform!.toUpperCase()
                      : "${controller.room.platform!.toUpperCase()} / ${controller.room.area}",
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 8),
                ),
              ],
            ),
          ]),
        ),
        body: ListView(
          children: <Widget>[
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: buildVideoPlayer(),
                ),
                const SizedBox(width: 20),
                Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    Obx(() => Text(
                          "播放状态：${controller.success.value ? "正在播放" : "未开播或无法播放"}",
                          style: Get.textTheme.titleMedium,
                        )),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Icon(Icons.whatshot_rounded, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          readableCount(controller.room.watching!),
                          style: Get.textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Obx(
                      () => ElevatedButton(
                          onPressed: () {
                            if (settings.isFavorite(controller.room)) {
                              settings.removeRoom(controller.room);
                            } else {
                              settings.addRoom(controller.room);
                            }
                          },
                          child: settings.isFavorite(controller.room) ? const Text('已关注') : const Text("关注")),
                    ),
                  ],
                )
              ],
            ),
            const Divider(height: 1),
            const SectionTitle(title: "播放线路"),
            Obx(() => buildLiveResolutionsRow()),
            const SizedBox(height: 20),
          ],
        ));
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
        child: Container(
          color: Colors.black,
          width: Get.size.width * 0.3,
          child: Card(
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
        ));
  }
}
