import 'dart:async';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/base/base_controller.dart';

class PopularGridController extends BasePageController<LiveRoom> {
  late Site site;
  var siteId = ''.obs;
  @override
  void onInit() {
    final preferPlatform = Get.find<SettingsService>().preferPlatform.value;
    final pIndex = Sites().availableSites().indexWhere((e) => e.id == preferPlatform);
    siteId.value = pIndex != -1 ? Sites().availableSites()[pIndex].id : Sites().availableSites()[0].id;
    site = pIndex != -1 ? Sites().availableSites()[pIndex] : Sites().availableSites()[0];
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
    var result = await site.liveSite.getRecommendRooms(page: page);
    return result.items;
  }
}
