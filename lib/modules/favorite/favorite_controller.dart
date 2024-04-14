import 'dart:async';
import 'package:get/get.dart';
import 'package:pure_live/app/utils.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';

class FavoriteController extends GetxController {
  final SettingsService settings = Get.find<SettingsService>();

  final tabBottomIndex = 0.obs;

  final onlineRoomsNodes = AppFocusNode();

  final offlineRoomsNodes = AppFocusNode();

  bool isFirstLoad = true;

  @override
  void onInit() {
    super.onInit();
    // 初始化关注页
    syncRooms();
    settings.currentPlayListNodeIndex.value = 0;
    // 监听settings rooms变化
    settings.favoriteRooms.listen((rooms) => syncRooms());
  }

  final onlineRooms = [].obs;
  final offlineRooms = [].obs;

  void syncRooms() {
    onlineRooms.clear();
    offlineRooms.clear();
    onlineRooms.addAll(settings.favoriteRooms.where((room) => room.liveStatus == LiveStatus.live));
    offlineRooms.addAll(settings.favoriteRooms.where((room) => room.liveStatus != LiveStatus.live));
    for (var room in onlineRooms) {
      if (int.tryParse(room.watching!) == null) {
        room.watching = "0";
      }
    }
    onlineRooms.sort((a, b) => int.parse(b.watching!).compareTo(int.parse(a.watching!)));
    settings.currentPlayList.value = onlineRooms;
    settings.currentPlayListNodeIndex.value = 0;
  }

  handleFollowLongTap(LiveRoom room) async {
    if (settings.isFavorite(room)) {
      var result = await Utils.showAlertDialog("确定要取消关注此房间吗?", title: "取消关注");
      if (!result) {
        return;
      }
      settings.removeRoom(room);
    } else {
      var result = await Utils.showAlertDialog("确定要关注此房间吗?", title: "关注");
      if (!result) {
        return;
      }
      settings.addRoom(room);
    }
    syncRooms();
  }

  Future<bool> onRefresh() async {
    // 自动刷新时间为0关闭。不是手动刷新并且不是第一次刷新
    if (isFirstLoad) {
      await const Duration(seconds: 1).delay();
    }
    bool hasError = false;
    List<Future<LiveRoom>> futures = [];
    if (settings.favoriteRooms.value.isEmpty) return false;
    for (final room in settings.favoriteRooms.value) {
      futures.add(Sites.of(room.platform!).liveSite.getRoomDetail(roomId: room.roomId!, platform: room.platform!));
    }
    try {
      final rooms = await Future.wait(futures);
      for (var room in rooms) {
        settings.updateRoom(room);
      }
      syncRooms();
    } catch (e) {
      hasError = true;
    }
    isFirstLoad = false;
    return hasError;
  }
}
