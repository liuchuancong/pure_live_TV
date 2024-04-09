import 'package:get/get.dart';
import 'package:pure_live/modules/search/search_room_controller.dart';

class SearchBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => SearchRoomController(keyword: Get.arguments[0]))];
  }
}
