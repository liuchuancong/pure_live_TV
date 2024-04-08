import 'dart:async';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';

class FavoriteController extends GetxController with GetSingleTickerProviderStateMixin {
  final SettingsService settings = Get.find<SettingsService>();
  late TabController tabController;
  final tabBottomIndex = 0.obs;
  bool isFirstLoad = true;
  FavoriteController() {
    tabController = TabController(length: 2, vsync: this);
  }

  @override
  void onInit() {
    super.onInit();
    // 初始化关注页
    syncRooms();
    // 监听settings rooms变化
    settings.favoriteRooms.listen((rooms) => syncRooms());
    onRefresh();
    // 定时自动刷新
    if (settings.autoRefreshTime.value != 0) {
      Timer.periodic(
        Duration(minutes: settings.autoRefreshTime.value),
        (timer) => onRefresh(),
      );
    }
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
      futures.add(Sites.of(room.platform!).liveSite.getRoomDetail(roomId: room.roomId!));
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
