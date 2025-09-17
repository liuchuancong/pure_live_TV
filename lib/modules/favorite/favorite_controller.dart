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
    try {
      // 如果没有收藏的房间，直接结束刷新
      if (settings.favoriteRooms.value.isEmpty) {
        loading.value = false;
        return false;
      }

      // 逐个处理每个收藏的房间
      for (final room in settings.favoriteRooms.value) {
        try {
          // 获取房间详情
          final liveRoom =
              await Sites.of(room.platform!).liveSite.getRoomDetail(roomId: room.roomId!, platform: room.platform!);

          // 更新房间信息
          settings.updateRoom(liveRoom);
        } catch (e) {
          debugPrint('刷新单个房间时出错: $e');
        }

        // 每个请求后间隔1秒，最后一个请求不需要延迟
        if (room != settings.favoriteRooms.value.last && room.platform == Sites.douyinSite) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    } catch (e) {
      debugPrint('刷新过程中发生错误: $e');
    } finally {
      syncRooms();
      isFirstLoad = false;
      loading.value = false;
    }
    return false;
  }
}
