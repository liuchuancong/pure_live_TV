import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/base/base_controller.dart';

class HomeController extends BasePageController {
  var datetime = "00:00".obs;
  static List<String> mainPageOptions = ["直播关注", "热门直播", "分区类别", "搜索直播", "观看记录", "数据同步", "平台设置"];
  static List<IconData> mainPageIconOptions = [
    Icons.favorite_border,
    Remix.fire_line,
    Remix.apps_line,
    Remix.search_2_line,
    Icons.history,
    Icons.devices,
    Icons.category_outlined
  ];
  var rooms = <LiveRoom>[].obs;
  var currentNodeIndex = 1.obs;
  // button列表再加上设置最近观看
  List<AppFocusNode> focusNodes = List.generate(mainPageOptions.length + 2, (_) => AppFocusNode());
  List<AppFocusNode> hisToryFocusNodes = [];
  final pageController = GroupButtonController(selectedIndex: 0);
  final SettingsService settingsService = Get.find<SettingsService>();

  var refreshIsOk = true.obs;
  @override
  void onInit() {
    initTimer();
    focusNodeListener();
    rooms.value = settingsService.historyRooms.reversed.take(20).toList();
    hisToryFocusNodes = List.generate(rooms.length, (_) => AppFocusNode());
    super.onInit();
  }

  void focusNodeListener() {
    // 监听 FocusNode 的变化
    focusNodes[currentNodeIndex.value].requestFocus();
  }

  toSync() {}
  void initTimer() {
    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      DateTime now = DateTime.now();
      DateFormat formatter = DateFormat('yyyy年MM月dd日 HH:mm:ss', 'zh_CN');
      datetime.value = formatter.format(now);
    });
  }

  Future<bool> historyRefresh() async {
    List<Future<LiveRoom>> futures = [];
    refreshIsOk.value = false;
    if (settingsService.historyRooms.value.reversed.take(20).isEmpty) {
      refreshIsOk.value = true;
      return false;
    }
    for (final room in settingsService.historyRooms.value.reversed.take(20)) {
      futures.add(Sites.of(room.platform!).liveSite.getRoomDetail(roomId: room.roomId!));
    }
    try {
      final rooms = await Future.wait(futures);
      for (var room in rooms) {
        settingsService.updateRoomInHistory(room);
      }
    } catch (e) {
      refreshIsOk.value = true;
      return false;
    }
    refreshIsOk.value = true;
    rooms.value = settingsService.historyRooms.reversed.take(20).toList();
    hisToryFocusNodes = List.generate(rooms.length, (_) => AppFocusNode());
    return true;
  }
}