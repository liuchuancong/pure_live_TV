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
                    Text(
                      "播放状态：${controller.success.value ? "正在播放" : "未开播或无法播放"}",
                      style: Get.textTheme.titleMedium,
                    ),
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
                    )
                  ],
                )
              ],
            ),
            const Divider(height: 1),
            const SectionTitle(title: "播放线路"),
            buildLiveResolutionsRow()
          ],
        ));
  }

  Widget buildLiveResolutionsRow() {
    var resolutions = [];
    for (LivePlayQuality rate in controller.qualites.value) {
      for (var url in controller.playUrls.value) {
        resolutions.add('${rate.quality}$url');
      }
    }
    return Padding(
      padding: const EdgeInsets.all(10.0),
      child: GroupButton(
          controller: groupButtonController,
          isRadio: false,
          options: GroupButtonOptions(
            selectedTextStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white),
            unselectedTextStyle: const TextStyle(
              fontSize: 15,
              color: Colors.black,
            ),
            spacing: 12,
            runSpacing: 10,
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
          onSelected: (val, i, selected) => handleResolutions(i)),
    );
  }

  handleResolutions(i) {}
  Widget buildVideoPlayer() {
    return Hero(
        tag: controller.room.roomId!,
        child: Container(
          color: Colors.black,
          width: Get.size.width * 0.45,
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

class ResolutionsRow extends StatefulWidget {
  const ResolutionsRow({super.key});

  @override
  State<ResolutionsRow> createState() => _ResolutionsRowState();
}

class _ResolutionsRowState extends State<ResolutionsRow> {
  LivePlayController get controller => Get.find();
  Widget buildInfoCount() {
    // controller.room watching or followers
    return Row(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.whatshot_rounded, size: 14),
      const SizedBox(width: 4),
      Text(
        readableCount(controller.room.watching!),
        style: Get.textTheme.bodySmall,
      ),
    ]);
  }

  List<Widget> buildResultionsList() {
    return controller.qualites
        .map<Widget>((rate) => PopupMenuButton(
              tooltip: rate.quality,
              color: Get.theme.colorScheme.surfaceVariant,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              offset: const Offset(0.0, 5.0),
              position: PopupMenuPosition.under,
              icon: Text(
                rate.quality,
                style: Get.theme.textTheme.labelSmall?.copyWith(
                  color: rate.quality == controller.qualites[controller.currentQuality.value].quality
                      ? Get.theme.colorScheme.primary
                      : null,
                ),
              ),
              onSelected: (String index) {
                controller.setResolution(rate.quality, index);
              },
              itemBuilder: (context) {
                final items = <PopupMenuItem<String>>[];
                final urls = controller.playUrls;
                for (int i = 0; i < urls.length; i++) {
                  items.add(PopupMenuItem<String>(
                    value: i.toString(),
                    child: Text(
                      '线路${i + 1}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: urls[i] == controller.playUrls[controller.currentLineIndex.value]
                                ? Get.theme.colorScheme.primary
                                : null,
                          ),
                    ),
                  ));
                }
                return items;
              },
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Container(
        height: 55,
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8),
              child: buildInfoCount(),
            ),
            const Spacer(),
            ...controller.success.value ? buildResultionsList() : [],
          ],
        ),
      ),
    );
  }
}

class FavoriteFloatingButton extends StatefulWidget {
  const FavoriteFloatingButton({
    super.key,
    required this.room,
  });

  final LiveRoom room;

  @override
  State<FavoriteFloatingButton> createState() => _FavoriteFloatingButtonState();
}

class _FavoriteFloatingButtonState extends State<FavoriteFloatingButton> {
  final settings = Get.find<SettingsService>();

  late bool isFavorite = settings.isFavorite(widget.room);

  @override
  Widget build(BuildContext context) {
    return isFavorite
        ? FloatingActionButton(
            elevation: 2,
            backgroundColor: Theme.of(context).cardColor,
            tooltip: S.of(context).unfollow,
            onPressed: () {
              Get.dialog(
                AlertDialog(
                  title: Text(S.of(context).unfollow),
                  content: Text(S.of(context).unfollow_message(widget.room.nick!)),
                  actions: [
                    TextButton(
                      onPressed: () => Get.back(result: false),
                      child: Text(S.of(context).cancel),
                    ),
                    ElevatedButton(
                      onPressed: () => Get.back(result: true),
                      child: Text(S.of(context).confirm),
                    ),
                  ],
                ),
              ).then((value) {
                if (value) {
                  setState(() => isFavorite = !isFavorite);
                  settings.removeRoom(widget.room);
                }
              });
            },
            child: CircleAvatar(
              foregroundImage: (widget.room.avatar == '') ? null : NetworkImage(widget.room.avatar!),
              radius: 18,
              backgroundColor: Theme.of(context).disabledColor,
            ),
          )
        : FloatingActionButton.extended(
            elevation: 2,
            backgroundColor: Theme.of(context).cardColor,
            onPressed: () {
              setState(() => isFavorite = !isFavorite);
              settings.addRoom(widget.room);
            },
            icon: CircleAvatar(
              foregroundImage: (widget.room.avatar == '') ? null : NetworkImage(widget.room.avatar!),
              radius: 18,
              backgroundColor: Theme.of(context).disabledColor,
            ),
            label: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  S.of(context).follow,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  widget.room.nick!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
  }
}
