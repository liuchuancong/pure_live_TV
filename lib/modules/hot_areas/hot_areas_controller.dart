import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/base/base_controller.dart';

class HotAreasController extends BaseController {
  final SettingsService settingsController = Get.find<SettingsService>();
  final sites = [].obs;

  List<AppFocusNode> sitesNodes = [];
  @override
  void onInit() {
    for (var element in Sites.supportSites) {
      var show = settingsController.hotAreasList.value.contains(element.id);
      var area = HotAreasModel(id: element.id, name: element.name, show: show);
      sites.add(area);
      sitesNodes.add(AppFocusNode());
    }
    settingsController.currentPlayListNodeIndex.value = 0;

    super.onInit();
  }

  Color get themeColor => HexColor(settingsController.themeColorSwitch.value);

  void onChanged(String id, bool value) {
    var index = sites.map((element) => element.id).toList().indexWhere((note) => note == id);
    HotAreasModel origin = sites[index];
    sites.removeAt(index);
    sites.insert(index, HotAreasModel(id: origin.id, name: origin.name, show: !origin.show));
    settingsController.hotAreasList.value = sites.where((p0) => p0.show).map((e) => e.id.toString()).toList();
  }
}

class HotAreasModel {
  String id;
  String name;
  bool show;

  HotAreasModel({required this.id, required this.name, required this.show});
}
