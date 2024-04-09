import 'package:get/get.dart';
import 'package:pure_live/modules/home/home_controller.dart';

class HomeBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => HomeController())];
  }
}
