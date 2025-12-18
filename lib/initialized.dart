import 'dart:io';
import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'common/utils/hive_pref_util.dart';
import 'package:pure_live/common/index.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

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
    initService();
    _isInitialized = true;
  }

  void initService() {
    Get.put(SettingsService());
  }

  // 检查是否已初始化
  bool get isInitialized => _isInitialized;
}
