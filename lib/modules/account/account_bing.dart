import 'package:get/get.dart';
import 'package:pure_live/modules/account/account_controller.dart';
import 'package:pure_live/common/services/bilibili_account_service.dart';

class AccountBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut(() => AccountController()),
      Bind.lazyPut(() => BiliBiliAccountService()),
    ];
  }
}
