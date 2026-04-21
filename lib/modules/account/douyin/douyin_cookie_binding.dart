import 'package:get/get.dart';
import 'package:pure_live/modules/account/douyin/douyin_cookie_controller.dart';

class DouyinCookieBinding extends Binding {
  @override
  List<Bind> dependencies() {
    return [Bind.lazyPut(() => DouyinCookiePageController())];
  }
}
