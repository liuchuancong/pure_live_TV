import 'dart:io';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'common/utils/hive_pref_util.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/plugins/db_service.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:pure_live/plugins/cache_manager.dart';
import 'package:pure_live/common/utils/app_path_manager.dart';
import 'package:pure_live/core/iptv/services/channel_detail_controller.dart';

class AppInitializer {
  // 单例实例
  static final AppInitializer _instance = AppInitializer._internal();

  // 是否已经初始化
  bool _isInitialized = false;

  // 工厂构造函数，返回单例
  factory AppInitializer() {
    return _instance;
  }

  // 私有构造函数
  AppInitializer._internal();

  // 初始化方法
  Future<void> initialize() async {
    if (_isInitialized) return;
    WidgetsFlutterBinding.ensureInitialized();
    // 限制图片缓存为 20MB（适配 1GB 内存设备）
    PaintingBinding.instance.imageCache.maximumSizeBytes = 20 * 1024 * 1024;
    // 强制横屏
    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);
    // 全屏
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    PrefUtil.prefs = await SharedPreferences.getInstance();
    final appDir = await getApplicationDocumentsDirectory();
    String path = '${appDir.path}${Platform.pathSeparator}pure_live_Tv';
    await Hive.initFlutter(path);
    await HivePrefUtil.init();
    MediaKit.ensureInitialized();
    await AppPathManager().initialize();
    await CustomImageCacheManager.initialize();
    initService();
    _isInitialized = true;
    SmartDialog.config.toast = SmartConfigToast(
      displayTime: const Duration(milliseconds: 3000),
      intervalTime: const Duration(milliseconds: 100),
    );
  }

  void initService() {
    Get.put(SettingsService());
    Get.lazyPut<DbService>(() => DbService()..init(), fenix: true);
    Get.lazyPut(() => ChannelDetailController(), fenix: true);
  }

  // 检查是否已初始化
  bool get isInitialized => _isInitialized;
}
