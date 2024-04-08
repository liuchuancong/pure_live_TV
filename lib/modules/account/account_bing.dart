import 'package:get/get.dart';
import 'package:pure_live/modules/account/account_controller.dart';

class AccountBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => AccountController())];
  }
}
