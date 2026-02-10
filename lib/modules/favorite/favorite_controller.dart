import 'dart:async';
import 'package:get/get.dart';
import 'package:pool/pool.dart';
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
    if (settings.autoRefreshFavorite.value) {
      int interval = settings.autoRefreshInterval.value;
      if (interval == 0) return;
      DateTime now = DateTime.now();
      DateTime last = settings.lastRefreshTime ?? now.subtract(Duration(days: 1));
      if (now.difference(last).inMinutes >= interval) {
        onRefresh();
        settings.lastRefreshTime = now;
      }
    }
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
    final Pool refreshPool = Pool(settings.maxConcurrentRefresh.value);
    loading.value = true;
    try {
      final rooms = settings.favoriteRooms.value.where((room) {
        return room.roomId != null && room.roomId!.isNotEmpty && room.platform != null && room.platform!.isNotEmpty;
      }).toList();

      if (rooms.isEmpty) {
        debugPrint('没有有效的收藏房间需要刷新');
        loading.value = false;
        return false;
      }

      final List<Future<void>> tasks = rooms.map((room) {
        return refreshPool.withResource(() async {
          try {
            if (room.platform == null || room.roomId == null) {
              debugPrint('跳过无效房间数据');
              return;
            }

            final liveRoom = await Sites.of(
              room.platform!,
            ).liveSite.getRoomDetail(roomId: room.roomId!, platform: room.platform!);

            settings.updateRoom(liveRoom);
          } catch (e, stack) {
            debugPrint('================ 刷新失败记录 ================');
            debugPrint('平台 (Platform): ${room.platform}');
            debugPrint('房间号 (RoomID): ${room.roomId}');
            debugPrint('昵称 (Nickname): ${room.nick}');
            debugPrint('原始标题 (Title): ${room.title}');
            debugPrint('具体错误类型: $e');
            debugPrint('堆栈追踪: $stack');
            debugPrint('============================================');
          }
        });
      }).toList();

      //  并发启动所有任务并等待它们全部执行完毕
      await Future.wait(tasks);
    } catch (e) {
      debugPrint('刷新过程中发生全局错误: $e');
    } finally {
      // 4. 数据同步和状态重置
      syncRooms();
      isFirstLoad = false;
      loading.value = false;
    }
    return true;
  }
}
