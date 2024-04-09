import 'package:get/get.dart';
import 'package:pure_live/modules/history/history_rooms_controller.dart';

class HistoryPageBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => HistoryPageController())];
  }
}
