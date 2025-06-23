import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pure_live/app/utils.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/base/base_controller.dart';

class HomeController extends BasePageController {
  var datetime = "00:00".obs;
  static List<String> mainPageOptions = ["直播关注", "热门直播", "分区类别", "搜索直播", "观看记录", "关注分区"];

  late ScrollController listScrollController;

  static List<IconData> mainPageIconOptions = [
    Icons.favorite_border,
    Remix.fire_line,
    Remix.apps_line,
    Remix.search_2_line,
    Icons.history,
    Icons.view_module_rounded
  ];
  var rooms = <LiveRoom>[].obs;
  var currentNodeIndex = 1.obs;
  // button列表再加上设置最近观看
  List<AppFocusNode> focusNodes = List.generate(mainPageOptions.length + 2, (_) => AppFocusNode());
  List<AppFocusNode> hisToryFocusNodes = [];
  final syncNode = AppFocusNode();
  final pageController = GroupButtonController(selectedIndex: 0);
  var refreshIsOk = true.obs;
  @override
  void onInit() {
    initTimer();
    focusNodeListener();
    hisToryFocusNodes = List.generate(rooms.length, (_) => AppFocusNode());
    refreshData();
    listScrollController = ScrollController();
    focusNodes[1].isFoucsed.listen((p0) {
      listScrollController.animateTo(0.0, duration: const Duration(milliseconds: 200), curve: Curves.linear);
    });
    focusNodes[mainPageOptions.length].isFoucsed.listen((p0) {
      listScrollController.animateTo(listScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200), curve: Curves.linear);
    });
    super.onInit();
  }

  void removeItem(LiveRoom item) async {
    var result = await Utils.showAlertDialog("确定要删除此记录吗?", title: "删除记录");
    if (!result) {
      return;
    }
    settingsService.removeHistoryRoom(item);
    refreshData();
  }

  void focusNodeListener() {
    // 监听 FocusNode 的变化
    focusNodes[currentNodeIndex.value].requestFocus();
  }

  void toSync() {
    Get.toNamed(RoutePath.kSync);
  }

  void initTimer() {
    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      DateTime now = DateTime.now();
      DateFormat formatter = DateFormat('yyyy年MM月dd日 HH:mm:ss', 'zh_CN');
      datetime.value = formatter.format(now);
    });
  }

  @override
  Future<List<LiveRoom>> getData(int page, int pageSize) async {
    List<Future<LiveRoom>> futures = [];
    var historyRooms =
        settingsService.historyRooms.value.where((room) => room.liveStatus == LiveStatus.live).take(8).toList();
    if (historyRooms.isEmpty) {
      return [];
    }
    for (final room in historyRooms) {
      futures.add(Sites.of(room.platform!)
          .liveSite
          .getRoomDetail(roomId: room.roomId!, platform: room.platform!, title: room.title!, nick: room.nick!));
    }
    try {
      final futuresRooms = await Future.wait(futures);
      for (var room in futuresRooms) {
        settingsService.updateRoomInHistory(room);
      }
    } catch (e) {
      return historyRooms;
    }
    historyRooms =
        settingsService.historyRooms.value.where((room) => room.liveStatus == LiveStatus.live).take(8).toList();
    rooms.value = historyRooms;
    hisToryFocusNodes = List.generate(rooms.length, (_) => AppFocusNode());
    return historyRooms;
  }
}
