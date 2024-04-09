import 'package:get/get.dart';
import 'package:pure_live/core/sites.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/models/live_area.dart';
import 'package:pure_live/common/models/live_room.dart';
import 'package:pure_live/common/base/base_controller.dart';

class AreaRoomsController extends BasePageController<LiveRoom> {
  final Site site;
  final LiveArea subCategory;
  var currentNodeIndex = 1.obs;
  // button列表再加上设置最近观看
  List<AppFocusNode> focusNodes = [];
  List<AppFocusNode> focusCateGoryNodes = [];
  AreaRoomsController({
    required this.site,
    required this.subCategory,
  });

  @override
  void onInit() {
    refreshData();
    super.onInit();
    list.addListener(() {
      if (list.isNotEmpty) {
        // 直播间
        focusCateGoryNodes = [];
        for (var i = 0; i < list.length; i++) {
          focusCateGoryNodes.add(AppFocusNode());
        }
      }
    });
  }

  @override
  Future<List<LiveRoom>> getData(int page, int pageSize) async {
    var result = await site.liveSite.getCategoryRooms(subCategory, page: page);
    for (var element in result.items) {
      element.area = subCategory.areaName;
    }
    return result.items;
  }
}
