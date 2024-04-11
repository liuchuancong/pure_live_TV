import 'package:get/get.dart';
import 'package:pure_live/modules/account/bilibili/qr_login_controller.dart';

class BilibiliQrLoginBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [
      Bind.lazyPut(() => BiliBiliQRLoginController()),
    ];
  }
}
