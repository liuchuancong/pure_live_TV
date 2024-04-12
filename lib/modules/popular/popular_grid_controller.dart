import 'dart:async';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/base/base_controller.dart';

class PopularGridController extends BasePageController<LiveRoom> {
  late Site site;
  var siteId = ''.obs;
  var currentNodeIndex = 1.obs;
  // button列表再加上设置最近观看
  List<AppFocusNode> focusNodes = [];
  List<AppFocusNode> focusLiveNodes = [];

  @override
  void onInit() {
    final preferPlatform = Get.find<SettingsService>().preferPlatform.value;
    final pIndex = Sites().availableSites().indexWhere((e) => e.id == preferPlatform);
    focusNodes = [];
    if (Sites().availableSites().isNotEmpty) {
      final SettingsService settingsService = Get.find<SettingsService>();
      siteId.value = pIndex != -1 ? Sites().availableSites()[pIndex].id : Sites().availableSites()[0].id;
      site = pIndex != -1 ? Sites().availableSites()[pIndex] : Sites().availableSites()[0];
      list.addListener(() {
        if (list.isNotEmpty) {
          // 直播间
          settingsService.currentPlayList.value = list;
          settingsService.currentPlayListNodeIndex.value = 0;
          focusLiveNodes = [];
          for (var i = 0; i < list.length; i++) {
            focusLiveNodes.add(AppFocusNode());
          }
        }
      });
    }

    // 分类按钮
    for (var i = 0; i < Sites().availableSites().length; i++) {
      focusNodes.add(AppFocusNode());
    }
    // 返回按钮
    focusNodes.add(AppFocusNode());

    refreshData();
    super.onInit();
  }

  void setSite(String id) {
    siteId.value = id;
    final pIndex = Sites().availableSites().indexWhere((e) => e.id == id);
    site = Sites().availableSites()[pIndex];
    refreshData();
  }

  @override
  Future<List<LiveRoom>> getData(int page, int pageSize) async {
    if (siteId.value.isEmpty) return [];
    var result = await site.liveSite.getRecommendRooms(page: page);
    return result.items;
  }
}
