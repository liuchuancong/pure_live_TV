import 'package:pure_live/get/get.dart';
import 'package:pure_live/services/settings_service.dart';

class SettingsBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => SettingsService())];
  }
}
