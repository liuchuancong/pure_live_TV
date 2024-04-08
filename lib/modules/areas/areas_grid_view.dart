import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/modules/areas/widgets/area_card.dart';
import 'package:pure_live/modules/areas/areas_list_controller.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class AreaGridView extends StatefulWidget {
  final String tag;
  const AreaGridView(this.tag, {super.key});
  AreasListController get controller => Get.find<AreasListController>(tag: tag);
  @override
  State<AreaGridView> createState() => _AreaGridViewState();
}

class _AreaGridViewState extends State<AreaGridView> with SingleTickerProviderStateMixin {
  late TabController tabController = TabController(length: widget.controller.list.length, vsync: this);

  @override
  void initState() {
    widget.controller.tabIndex.addListener(() {
      tabController.animateTo(widget.controller.tabIndex.value);
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TabBar(
          controller: tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.center,
          indicatorSize: TabBarIndicatorSize.label,
          tabs: widget.controller.list.map<Widget>((e) => Tab(text: e.name)).toList(),
        ),
        Expanded(
          child: Obx(() => TabBarView(
                controller: tabController,
                children: widget.controller.list.map<Widget>((e) => buildAreasView(e)).toList(),
              )),
        ),
      ],
    );
  }

  Widget buildAreasView(AppLiveCategory category) {
    return LayoutBuilder(builder: (context, constraint) {
      final width = constraint.maxWidth;
      final crossAxisCount = width > 1280 ? 9 : (width > 960 ? 7 : (width > 640 ? 5 : 3));
      return widget.controller.list.isNotEmpty
          ? MasonryGridView.count(
              padding: const EdgeInsets.all(5),
              controller: ScrollController(),
              crossAxisCount: crossAxisCount,
              itemCount: category.children.length,
              itemBuilder: (context, index) => AreaCard(category: category.children[index]),
            )
          : EmptyView(
              icon: Icons.area_chart_outlined,
              title: S.of(context).empty_areas_title,
              subtitle: S.of(context).empty_areas_subtitle,
            );
    });
  }
}
