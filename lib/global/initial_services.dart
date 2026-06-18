import 'package:pure_live/common/index.dart';
import 'package:pure_live/plugins/db_service.dart';
import 'package:pure_live/core/iptv/services/channel_detail_controller.dart';

class InitialServices {
  static void initGlobalServices() {
    Get.put(SettingsService(), permanent: true);
  }

  static void initLazyControllers() {
    // 关注
    Get.lazyPut(() => FavoriteController(), fenix: true);
    // iptv频道
    Get.lazyPut(() => ChannelDetailController(), fenix: true);
    // 热门
    Get.lazyPut(() => PopularController(), fenix: true);
    // 分区
    Get.lazyPut(() => AreasController(), fenix: true);
  }

  static Future<void> initDb() async {
    final db = DbService();
    await db.init();
    Get.put<DbService>(db, permanent: true);
  }

  static Future<void> init() async {
    await initDb();
    initGlobalServices();
    initLazyControllers();
    _initHeavyServicesInBackground();
  }

  static void _initHeavyServicesInBackground() {
    Future.delayed(const Duration(seconds: 3), () {
      try {
        Get.put(AuthController(), permanent: true);
      } catch (_) {}
    });
  }
}
