import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/widgets/keep_alive_wrapper.dart';
import 'package:pure_live/modules/area_rooms/area_rooms_controller.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class AreasRoomPage extends StatefulWidget {
  const AreasRoomPage({super.key});

  @override
  State<AreasRoomPage> createState() => _AreasRoomPageState();
}

class _AreasRoomPageState extends State<AreasRoomPage> {
  AreaRoomsController get controller => Get.find<AreaRoomsController>();

  @override
  void initState() {
    super.initState();
    controller.loadData();
  }

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: Scaffold(
        appBar: AppBar(title: Text(controller.subCategory.areaName!)),
        body: LayoutBuilder(builder: (context, constraint) {
          final width = constraint.maxWidth;
          final crossAxisCount = width > 1280 ? 5 : (width > 960 ? 4 : (width > 640 ? 3 : 2));
          return Obx(() => EasyRefresh(
                controller: controller.easyRefreshController,
                onRefresh: controller.refreshData,
                onLoad: controller.loadData,
                child: controller.list.isNotEmpty
                    ? MasonryGridView.count(
                        padding: const EdgeInsets.all(5),
                        controller: controller.scrollController,
                        crossAxisCount: crossAxisCount,
                        itemCount: controller.list.length,
                        itemBuilder: (context, index) => RoomCard(room: controller.list[index], dense: true),
                      )
                    : EmptyView(
                        icon: Icons.live_tv_rounded,
                        title: S.of(context).empty_areas_room_title,
                        subtitle: S.of(context).empty_areas_room_subtitle,
                      ),
              ));
        }),
        floatingActionButton: FavoriteAreaFloatingButton(area: controller.subCategory),
      ),
    );
  }
}

class FavoriteAreaFloatingButton extends StatefulWidget {
  const FavoriteAreaFloatingButton({
    super.key,
    required this.area,
  });

  final LiveArea area;

  @override
  State<FavoriteAreaFloatingButton> createState() => _FavoriteAreaFloatingButtonState();
}

class _FavoriteAreaFloatingButtonState extends State<FavoriteAreaFloatingButton> {
  final settings = Get.find<SettingsService>();

  late bool isFavorite = settings.isFavoriteArea(widget.area);

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
                  content: Text(S.of(context).unfollow_message(widget.area.areaName!)),
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
                  settings.removeArea(widget.area);
                }
              });
            },
            child: CircleAvatar(
              foregroundImage: (widget.area.areaPic == '') ? null : NetworkImage(widget.area.areaPic!),
              radius: 18,
              backgroundColor: Theme.of(context).disabledColor,
            ),
          )
        : FloatingActionButton.extended(
            elevation: 2,
            backgroundColor: Theme.of(context).cardColor,
            onPressed: () {
              setState(() => isFavorite = !isFavorite);
              settings.addArea(widget.area);
            },
            icon: CircleAvatar(
              foregroundImage: (widget.area.areaPic == '') ? null : NetworkImage(widget.area.areaPic!),
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
                  widget.area.areaName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
  }
}
