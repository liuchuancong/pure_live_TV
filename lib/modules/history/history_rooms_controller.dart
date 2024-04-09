import 'package:get/get.dart';
import 'package:pure_live/plugins/utils.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/common/base/base_controller.dart';
import 'package:pure_live/common/services/settings_service.dart';

class HistoryPageController extends BasePageController<LiveRoom> {
  var currentNodeIndex = 1.obs;
  // button列表再加上设置最近观看
  List<AppFocusNode> focusNodes = [];

  @override
  void onInit() {
    refreshData();
    super.onInit();
    stopLoadMore.value = false;
    list.addListener(() {
      if (list.isNotEmpty) {
        // 直播间
        focusNodes = [];
        for (var i = 0; i < list.length; i++) {
          focusNodes.add(AppFocusNode());
        }
      }
    });
  }

  void clean() async {
    var result = await Utils.showAlertDialog("确定要清空观看记录吗?", title: "清空观看记录");
    if (!result) {
      return;
    }
    refreshData();
  }

  void removeItem(LiveRoom item) async {
    var result = await Utils.showAlertDialog("确定要删除此记录吗?", title: "删除记录");
    if (!result) {
      return;
    }
    refreshData();
  }

  @override
  Future<List<LiveRoom>> getData(int page, int pageSize) async {
    final SettingsService settings = Get.find<SettingsService>();
    final rooms = settings.historyRooms.reversed.toList();
    return rooms;
  }
}
