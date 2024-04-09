import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class FavoriteAreasPage extends GetView<SettingsService> {
  const FavoriteAreasPage({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraint) {
      final width = constraint.maxWidth;
      final crossAxisCount = width > 1280 ? 9 : (width > 960 ? 7 : (width > 640 ? 5 : 3));
      return Scaffold(
        appBar: AppBar(title: Text(S.of(context).favorite_areas)),
        body: Obx(
          () => controller.favoriteAreas.isNotEmpty
              ? MasonryGridView.count(
                  padding: const EdgeInsets.all(5),
                  crossAxisCount: crossAxisCount,
                  itemCount: controller.favoriteAreas.length,
                  itemBuilder: (context, index) => Container())
              : EmptyView(
                  icon: Icons.area_chart_outlined,
                  title: S.of(context).empty_areas_title,
                  subtitle: '',
                ),
        ),
      );
    });
  }
}
