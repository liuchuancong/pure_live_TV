import 'package:pure_live/get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/routes/app_navigation.dart';

class AccountController extends GetxController {
  final nodes = List.generate(5, (index) => AppFocusNode());
  final SettingsService settings = Get.find<SettingsService>();
  void bilibiliTap() async {
    AppNavigator.toBiliBiliLogin();
  }

  void douyinTap() {
    Get.toNamed(RoutePath.kDouyinCookie);
  }

  void kuaishouTap() {
    Get.toNamed(RoutePath.kKuaishouCookie);
  }
}
