import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/widgets/button/highlight_button.dart';
import 'package:pure_live/modules/hot_areas/hot_areas_controller.dart';
import 'package:pure_live/common/widgets/button/highlight_list_tile.dart';

class HotAreasPage extends GetView<HotAreasController> {
  const HotAreasPage({super.key});

  _buildListData() {
    return List.generate(
      controller.sites.length,
      (index) => Obx(
        () => HighlightListTile(
          title: controller.sites[index].name,
          trailing: Switch(
            value: controller.sites[index].show,
            thumbColor: controller.sites[index].show
                ? WidgetStateProperty.all(Colors.white)
                : WidgetStateProperty.all(Colors.black),
            onChanged: (bool value) {},
          ),
          focusNode: controller.sitesNodes[index],
          onTap: () {
            controller.settingsController.currentPlayListNodeIndex.value = 0;
            controller.onChanged(controller.sites[index].id, !controller.sites[index].show);
          },
        ),
      ),
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Padding(
        padding: AppStyle.edgeInsetsA48,
        child: ListView(
          physics: const BouncingScrollPhysics(),
          children: <Widget>[
            AppStyle.vGap32,
            Row(
              children: [
                HighlightButton(
                  focusNode: AppFocusNode(),
                  iconData: Icons.arrow_back,
                  text: "返回",
                  autofocus: true,
                  onTap: () {
                    Navigator.of(Get.context!).pop();
                  },
                ),
              ],
            ),
            AppStyle.vGap32,
            Column(
              children: _buildListData(),
            )
          ],
        ),
      ),
    );
  }
}
