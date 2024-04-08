import 'package:get/get.dart';
import 'package:pure_live/core/sites.dart';
import 'package:pure_live/common/base/base_controller.dart';

class SearchListController extends BasePageController {
  final keyword = "".obs;

  /// 搜索模式，0=直播间，1=主播
  var searchMode = 0.obs;
  final Site site;
  SearchListController(
    this.site,
  );

  @override
  Future refreshData() async {
    if (keyword.value.isEmpty) {
      return;
    }
    return await super.refreshData();
  }

  @override
  Future<List> getData(int page, int pageSize) async {
    if (keyword.value.isEmpty) {
      return [];
    }
    if (searchMode.value == 1) {
      // 搜索主播
      var result = await site.liveSite.searchAnchors(keyword.value, page: page);
      return result.items;
    }
    var result = await site.liveSite.searchRooms(keyword.value, page: page);
    return result.items;
  }

  void clear() {
    currentPage = 1;
    list.value = [];
  }
}
