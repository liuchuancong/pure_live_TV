import 'dart:async';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/base/base_controller.dart';

class HomeController extends BaseController {
  var datetime = "00:00".obs;
  static List<String> mainPageOptions = ["直播关注", "热门直播", "分区类别", "搜索直播", "观看记录", "数据同步"];
  static List<IconData> mainPageIconOptions = [
    Icons.favorite_border,
    Remix.fire_line,
    Remix.apps_line,
    Remix.search_2_line,
    Icons.history,
    Icons.devices
  ];
  var currentNodeIndex = 1.obs;
  // button列表再加上设置最近观看
  List<AppFocusNode> focusNodes = List.generate(mainPageOptions.length + 2, (_) => AppFocusNode());
  final pageController = GroupButtonController(selectedIndex: 0);
  final SettingsService settingsService = Get.find<SettingsService>();
  @override
  void onInit() {
    initTimer();
    focusNodeListener();
    super.onInit();
  }

  void focusNodeListener() {
    // 监听 FocusNode 的变化
    focusNodes[currentNodeIndex.value].requestFocus();
  }

  void initTimer() {
    Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      DateTime now = DateTime.now();
      DateFormat formatter = DateFormat('yyyy年MM月dd日 HH:mm:ss', 'zh_CN');
      datetime.value = formatter.format(now);
    });
  }
}
