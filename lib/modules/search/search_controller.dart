import 'package:get/get.dart';
import '../../core/sites.dart';
import 'search_list_controller.dart';
import 'package:flutter/material.dart';

class SearchController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  int index = 0;

  SearchController() {
    tabController = TabController(
      length: Sites().availableSites().length,
      vsync: this,
    );
    tabController.animation?.addListener(() {
      var currentIndex = (tabController.animation?.value ?? 0).round();
      if (index == currentIndex) {
        return;
      }
      index = currentIndex;
      var controller = Get.find<SearchListController>(tag: Sites().availableSites()[index].id);
      if (controller.list.isEmpty && !controller.pageEmpty.value) {
        controller.refreshData();
      }
      controller.keyword.addListener(() {
        searchController.text = controller.keyword.value;
      });
    });
  }

  TextEditingController searchController = TextEditingController();

  @override
  void onInit() {
    for (var site in Sites().availableSites()) {
      Get.put(SearchListController(site), tag: site.id);
    }

    super.onInit();
  }

  void doSearch() {
    if (searchController.text.isEmpty) {
      return;
    }
    for (var site in Sites().availableSites()) {
      var controller = Get.find<SearchListController>(tag: site.id);
      controller.clear();
      controller.keyword.value = searchController.text;
    }
    var controller = Get.find<SearchListController>(tag: Sites().availableSites()[index].id);
    controller.loadData();
  }
}
