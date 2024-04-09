import 'dart:convert';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/model/live_category.dart';
import 'package:pure_live/common/base/base_controller.dart';

class AreasListController extends BasePageController<AppLiveCategory> {
  late Site site;
  var siteId = ''.obs;
  var currentNodeIndex = 1.obs;
  // button列表再加上设置最近观看
  List<AppFocusNode> focusNodes = [];
  List<AppFocusNode> focusLiveNodes = [];
  @override
  void onInit() {
    final preferPlatform = Get.find<SettingsService>().preferPlatform.value;
    stopLoadMore.value = false;
    final pIndex = Sites().availableSites().indexWhere((e) => e.id == preferPlatform);
    siteId.value = pIndex != -1 ? Sites().availableSites()[pIndex].id : Sites().availableSites()[0].id;
    site = pIndex != -1 ? Sites().availableSites()[pIndex] : Sites().availableSites()[0];
    refreshData();
    super.onInit();
    focusNodes = [];
    // 分类按钮
    for (var i = 0; i < Sites().availableSites().length; i++) {
      focusNodes.add(AppFocusNode());
    }
    // 返回按钮
    focusNodes.add(AppFocusNode());
  }

  void setSite(String id) {
    siteId.value = id;
    final pIndex = Sites().availableSites().indexWhere((e) => e.id == id);
    site = Sites().availableSites()[pIndex];
    refreshData();
  }

  @override
  Future<List<AppLiveCategory>> getData(int page, int pageSize) async {
    var result = await site.liveSite.getCategores(page, pageSize);
    return result.map((e) => AppLiveCategory.fromLiveCategory(e)).toList();
  }
}

class AppLiveCategory extends LiveCategory {
  var showAll = false.obs;

  AppLiveCategory({
    required super.id,
    required super.name,
    required super.children,
  }) {
    showAll.value = children.length < 19;
  }

  List<LiveArea> get take15 => children.take(15).toList();

  factory AppLiveCategory.fromLiveCategory(LiveCategory item) {
    return AppLiveCategory(
      children: item.children,
      id: item.id,
      name: item.name,
    );
  }
  Map<String, dynamic> toJson() {
    Map<String, dynamic> json = {};
    json['id'] = id;
    json['name'] = name;
    json['children'] = children.map((LiveArea e) => jsonEncode(e.toJson())).toList();
    return json;
  }
}
