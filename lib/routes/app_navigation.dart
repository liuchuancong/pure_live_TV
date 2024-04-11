import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';

/// APP页面跳转封装
/// * 需要参数的页面都应使用此类
/// * 如不需要参数，可以使用Get.toNamed
class AppNavigator {
  /// 跳转至分类详情
  static void toCategoryDetail({required Site site, required LiveArea category}) {
    Get.toNamed(RoutePath.kAreaRooms, arguments: [site, category]);
  }

  /// 跳转至直播间
  static Future<void> toLiveRoomDetail({required LiveRoom liveRoom}) async {
    Get.toNamed(RoutePath.kLivePlay, arguments: liveRoom, parameters: {
      "site": liveRoom.platform!,
    });
  }

  /// 跳转至哔哩哔哩登录
  static Future toBiliBiliLogin() async {
    await Get.toNamed(RoutePath.kBiliBiliQRLogin);
  }
}
