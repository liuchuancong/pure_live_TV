import 'package:pure_live/get/get.dart';
import 'package:pure_live/modules/sync/sync_controller.dart';

class SyncBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => SyncController())];
  }
}
