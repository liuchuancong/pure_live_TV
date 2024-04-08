import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/modules/hot_areas/hot_areas_controller.dart';

class HotAreasPage extends GetView<HotAreasController> {
  const HotAreasPage({super.key});

  _initListData() {
    return controller.sites.map((e) {
      return SwitchListTile(
          title: Text(e.name),
          value: e.show,
          activeColor: Theme.of(Get.context!).colorScheme.primary,
          onChanged: (bool value) => controller.onChanged(e.id, value));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("平台显示"),
      ),
      body: Obx(() => ListView(
            padding: const EdgeInsets.all(12.0),
            children: _initListData(),
          )),
    );
  }
}
