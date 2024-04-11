import 'package:get/get.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/routes/app_navigation.dart';

class AccountController extends GetxController {
  final nodes = List.generate(4, (index) => AppFocusNode());
  void bilibiliTap() async {
    AppNavigator.toBiliBiliLogin();
  }
}
