import 'package:get/get.dart';
import 'package:pure_live/modules/areas/areas_list_controller.dart';

class AreasBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => AreasListController())];
  }
}
