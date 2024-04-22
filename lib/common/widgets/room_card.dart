import 'dart:developer';
import 'package:get/get.dart';
import 'package:marquee/marquee.dart';
import 'package:pure_live/app/utils.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/routes/app_navigation.dart';
import 'package:pure_live/common/widgets/highlight_widget.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/search/search_room_controller.dart';
import 'package:pure_live/modules/popular/popular_grid_controller.dart';
import 'package:pure_live/modules/history/history_rooms_controller.dart';
import 'package:pure_live/modules/area_rooms/area_rooms_controller.dart';

// ignore: must_be_immutable
class RoomCard extends StatefulWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.focusNode,
    this.dense = false,
    this.isIptv = false,
    this.onLongTap,
    this.useDefaultLongTapEvent = true,
    this.areas = const [],
    required this.roomTypePage,
  });
  final LiveRoom room;
  final bool dense;
  final bool isIptv;
  final List<LiveArea> areas;
  final AppFocusNode focusNode;
  final Function()? onLongTap;
  final bool useDefaultLongTapEvent;
  final EnterRoomTypePage roomTypePage;
  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  EnterRoomTypePage get roomTypePage => widget.roomTypePage;
  void onTap() {
    handleCurrentPlayList();
    AppNavigator.toLiveRoomDetail(liveRoom: widget.room);
  }

  handleCurrentPlayList() {
    final SettingsService settingsService = Get.find<SettingsService>();
    if (widget.isIptv) {
      var rooms = [];
      for (var liveArea in widget.areas) {
        var roomItem = LiveRoom(
          roomId: liveArea.areaId,
          title: liveArea.areaName,
          cover: '',
          nick: liveArea.typeName,
          watching: '',
          avatar:
              'https://img95.699pic.com/xsj/0q/x6/7p.jpg%21/fw/700/watermark/url/L3hzai93YXRlcl9kZXRhaWwyLnBuZw/align/southeast',
          area: '',
          liveStatus: LiveStatus.live,
          status: true,
          platform: 'iptv',
        );
        rooms.add(roomItem);
      }
      settingsService.currentPlayList.value = rooms;
      settingsService.currentPlayListNodeIndex.value =
          rooms.indexWhere((element) => element.roomId == widget.room.roomId);
    } else {
      switch (roomTypePage) {
        case EnterRoomTypePage.homePage:
          var rooms =
              settingsService.historyRooms.value.where((room) => room.liveStatus == LiveStatus.live).take(5).toList();
          settingsService.currentPlayList.value = rooms;
          settingsService.currentPlayListNodeIndex.value =
              rooms.indexWhere((element) => element.roomId == widget.room.roomId);
          break;
        case EnterRoomTypePage.areasRoomPage:
          var areaRoomsController = Get.find<AreaRoomsController>();
          var rooms = areaRoomsController.list.value;
          settingsService.currentPlayList.value = rooms;
          settingsService.currentPlayListNodeIndex.value =
              rooms.indexWhere((element) => element.roomId == widget.room.roomId);
          break;
        case EnterRoomTypePage.favoritePage:
          var favoriteController = Get.find<FavoriteController>();
          var rooms = favoriteController.tabBottomIndex.value == 0
              ? favoriteController.onlineRooms.value
              : favoriteController.offlineRooms.value;
          settingsService.currentPlayList.value = rooms;
          settingsService.currentPlayListNodeIndex.value =
              rooms.indexWhere((element) => element.roomId == widget.room.roomId);
          break;
        case EnterRoomTypePage.searchPage:
          var searchRoomController = Get.find<SearchRoomController>();
          var rooms = searchRoomController.list.value;
          settingsService.currentPlayList.value = rooms;
          settingsService.currentPlayListNodeIndex.value =
              rooms.indexWhere((element) => element.roomId == widget.room.roomId);
          break;

        case EnterRoomTypePage.historyPage:
          var historyRoomsController = Get.find<HistoryPageController>();
          var rooms = historyRoomsController.list.value;
          settingsService.currentPlayList.value = rooms;
          settingsService.currentPlayListNodeIndex.value =
              rooms.indexWhere((element) => element.roomId == widget.room.roomId);
          break;
        case EnterRoomTypePage.popularPage:
          var popularGridController = Get.find<PopularGridController>();
          var rooms = popularGridController.list.value;
          settingsService.currentPlayList.value = rooms;
          settingsService.currentPlayListNodeIndex.value =
              rooms.indexWhere((element) => element.roomId == widget.room.roomId);
          break;
        default:
      }
    }
  }

  ImageProvider? getRoomAvatar(avatar) {
    try {
      return CachedNetworkImageProvider(avatar, errorListener: (err) {
        log("CachedNetworkImageProvider: Image failed to load!");
      });
    } catch (e) {
      return null;
    }
  }

  handleFollowLongTap() async {
    final SettingsService settingsService = Get.find<SettingsService>();
    if (settingsService.isFavorite(widget.room)) {
      var result = await Utils.showAlertDialog("确定要取消关注此房间吗?", title: "取消关注");
      if (!result) {
        return;
      }
      settingsService.removeRoom(widget.room);
    } else {
      var result = await Utils.showAlertDialog("确定要关注此房间吗?", title: "关注");
      if (!result) {
        return;
      }
      settingsService.addRoom(widget.room);
    }
  }

  @override
  Widget build(BuildContext context) {
    return HighlightWidget(
      focusNode: widget.focusNode,
      color: Colors.white10,
      onTap: onTap,
      onLongTap: widget.useDefaultLongTapEvent
          ? () {
              handleFollowLongTap();
            }
          : widget.onLongTap,
      borderRadius: AppStyle.radius16,
      child: Obx(
        () => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.w),
                topRight: Radius.circular(16.w),
              ),
              child: Stack(
                children: [
                  Hero(
                    tag: widget.room.roomId!,
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Card(
                        margin: const EdgeInsets.all(0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0.0),
                        ),
                        clipBehavior: Clip.antiAlias,
                        color: Theme.of(context).focusColor,
                        elevation: 0,
                        child: widget.room.liveStatus == LiveStatus.offline
                            ? Center(
                                child: Icon(
                                  Icons.tv_off_rounded,
                                  size: widget.dense ? 36 : 60,
                                  color: widget.focusNode.isFoucsed.value ? Colors.black : Colors.white,
                                ),
                              )
                            : CachedNetworkImage(
                                imageUrl: widget.room.cover!,
                                cacheManager: CustomCacheManager.instance,
                                fit: BoxFit.fill,
                                errorWidget: (context, error, stackTrace) => Center(
                                  child: Icon(
                                    color: widget.focusNode.isFoucsed.value ? Colors.black : Colors.white,
                                    Icons.live_tv_rounded,
                                    size: widget.dense ? 38 : 62,
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ),
                  if (widget.room.isRecord == true)
                    Positioned(
                      right: 8.w,
                      top: 8.w,
                      child: CountChip(
                        icon: Icons.videocam_rounded,
                        count: S.of(context).replay,
                        dense: widget.dense,
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (widget.room.isRecord == false && widget.room.liveStatus == LiveStatus.live)
                    Positioned(
                      right: 8.w,
                      bottom: 8.w,
                      child: CountChip(
                        icon: Icons.whatshot_rounded,
                        count: readableCount(widget.room.watching!),
                        dense: widget.dense,
                      ),
                    ),
                  if (widget.room.isRecord == false && widget.room.liveStatus == LiveStatus.offline)
                    Positioned(
                      right: 8.w,
                      top: 8.w,
                      child: CountChip(
                        icon: Icons.videocam_rounded,
                        count: "未开播",
                        dense: widget.dense,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                ],
              ),
              // child: Container(
              //   height: 200.w,
              // ),
            ),
            AppStyle.vGap8,
            Padding(
              padding: AppStyle.edgeInsetsH20,
              child: SizedBox(
                height: 56.w,
                child: widget.focusNode.isFoucsed.value && widget.room.title!.isNotEmpty
                    ? Marquee(
                        text: widget.room.title ?? '未设置标题',
                        style: AppStyle.textStyleBlack,
                        startAfter: const Duration(seconds: 1),
                        velocity: 20,
                        blankSpace: 200.w,
                        //decelerationDuration: const Duration(seconds: 2),
                        scrollAxis: Axis.horizontal,
                      )
                    : Container(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.room.title ?? '未设置标题',
                          style: AppStyle.textStyleWhite,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                AppStyle.hGap20,
                SizedBox(
                  width: 40.w,
                  height: 40.h,
                  child: CircleAvatar(
                    foregroundImage: widget.room.avatar!.isNotEmpty ? getRoomAvatar(widget.room.avatar) : null,
                    backgroundColor: Theme.of(context).disabledColor,
                  ),
                ),
                AppStyle.hGap8,
                Expanded(
                  child: Text(
                    widget.room.nick!,
                    style: widget.focusNode.isFoucsed.value ? AppStyle.subTextStyleBlack : AppStyle.subTextStyleWhite,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            AppStyle.vGap12,
          ],
        ),
      ),
    );
  }
}

class CountChip extends StatelessWidget {
  const CountChip({
    super.key,
    required this.icon,
    required this.count,
    this.dense = false,
    this.color = Colors.black,
  });

  final IconData icon;
  final String count;
  final bool dense;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: const StadiumBorder(),
      color: color.withOpacity(0.8),
      shadowColor: Colors.transparent,
      elevation: 0,
      child: Padding(
        padding: EdgeInsets.all(dense ? 4 : 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white.withOpacity(0.8),
              size: dense ? 18 : 20,
            ),
            Text(
              count,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: dense ? 15 : 18,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
