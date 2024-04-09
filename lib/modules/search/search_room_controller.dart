import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/base/base_controller.dart';

class SearchRoomController extends BasePageController<LiveRoom> {
  final String keyword;
  late Site site;
  var siteId = ''.obs;
  var currentNodeIndex = 1.obs;
  // button列表再加上设置最近观看
  List<AppFocusNode> focusNodes = [];
  List<AppFocusNode> focusLiveNodes = [];
  SearchRoomController({required this.keyword});

  @override
  void onInit() {
    siteId.value = Sites().availableSites()[0].id;
    site = Sites().availableSites()[0];
    focusNodes = [];
    // 分类按钮
    for (var i = 0; i < Sites().availableSites().length; i++) {
      focusNodes.add(AppFocusNode());
    }
    // 返回按钮
    focusNodes.add(AppFocusNode());

    refreshData();
    super.onInit();

    list.addListener(() {
      if (list.isNotEmpty) {
        // 直播间
        focusLiveNodes = [];
        for (var i = 0; i < list.length; i++) {
          focusLiveNodes.add(AppFocusNode());
        }
      }
    });
  }

  void setSite(String id) {
    siteId.value = id;
    final pIndex = Sites().availableSites().indexWhere((e) => e.id == id);
    site = Sites().availableSites()[pIndex];
    refreshData();
  }

  @override
  Future<List<LiveRoom>> getData(int page, int pageSize) async {
    if (keyword.isEmpty) {
      return [];
    }
    var result = await site.liveSite.searchRooms(keyword, page: page);
    return result.items;
  }
}
