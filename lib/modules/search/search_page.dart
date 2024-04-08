import 'package:get/get.dart';
import 'search_list_view.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/core/sites.dart';
import 'package:pure_live/common/l10n/generated/l10n.dart';
import 'package:pure_live/modules/search/search_controller.dart' as pure_live;

class SearchPage extends GetView<pure_live.SearchController> {
  const SearchPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TextField(
          controller: controller.searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: S.of(context).search_input_hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(24)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12.0),
            prefixIcon: IconButton(
              onPressed: Get.back,
              icon: const Icon(Icons.arrow_back),
            ),
            suffixIcon: IconButton(
              onPressed: controller.doSearch,
              icon: const Icon(Icons.search),
            ),
          ),
          onSubmitted: (e) {
            controller.doSearch();
          },
        ),
        bottom: TabBar(
          controller: controller.tabController,
          padding: EdgeInsets.zero,
          tabAlignment: TabAlignment.center,
          tabs: Sites().availableSites().map((e) => Tab(text: e.name)).toList(),
          isScrollable: false,
          indicatorSize: TabBarIndicatorSize.label,
        ),
      ),
      body: TabBarView(
        controller: controller.tabController,
        children: Sites().availableSites().map((e) => SearchListView(e.id)).toList(),
      ),
    );
  }
}
