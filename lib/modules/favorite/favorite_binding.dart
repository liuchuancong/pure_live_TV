import 'package:get/get.dart';
import 'package:pure_live/modules/favorite/favorite_controller.dart';

class FavoriteBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => FavoriteController())];
  }
}
