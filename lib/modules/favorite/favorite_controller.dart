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

  var loading = true.obs;
  @override
  void onInit() {
    super.onInit();

    onlineRoomsNodes.requestFocus();
    // 初始化关注页
    syncRooms();
    // 监听settings rooms变化
    settings.favoriteRooms.listen((rooms) => syncRooms());
  }

  final onlineRooms = [].obs;
  final offlineRooms = [].obs;

  void syncRooms() {
    loading.value = true;
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
    loading.value = false;
  }

  Future<void> handleFollowLongTap(LiveRoom room) async {
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
    loading.value = true;
    List<Future<LiveRoom>> futures = [];
    if (settings.favoriteRooms.value.isEmpty) {
      loading.value = false;
      return false;
    }
    for (final room in settings.favoriteRooms.value) {
      if (room.platform!.isNotEmpty) {
        futures.add(
          Sites.of(room.platform!).liveSite.getRoomDetail(roomId: room.roomId!, platform: room.platform!),
        );
      }
    }
    List<List<Future<LiveRoom>>> groupedList = [];

    // 每次循环处理四个元素
    for (int i = 0; i < futures.length; i += 1) {
      // 获取当前循环开始到下一个四个元素的位置（但不超过原列表长度）
      int end = i + 1;
      if (end > futures.length) {
        end = futures.length;
      }
      // 截取当前四个元素的子列表
      List<Future<LiveRoom>> subList = futures.sublist(i, end);
      // 将子列表添加到结果列表中
      groupedList.add(subList);
    }

    try {
      for (var i = 0; i < groupedList.length; i++) {
        try {
          final rooms = await Future.wait(groupedList[i]);
          for (var room in rooms) {
            try {
              settings.updateRoom(room);
            } catch (e) {
              debugPrint('Error during refresh for a single request: $e');
            }
          }
        } catch (e) {
          debugPrint('Error during refresh for a batch of requests: $e');
        }
        syncRooms();
      }
    } catch (e) {
      loading.value = false;
    }
    isFirstLoad = false;
    loading.value = false;
    return false;
  }
}
