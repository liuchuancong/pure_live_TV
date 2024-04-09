import 'package:get/get.dart';
import 'package:pure_live/modules/popular/popular_grid_controller.dart';

class PoPopularBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => PopularGridController())];
  }
}
