import 'dart:io';
import 'app_path_manager.dart';
import 'package:pure_live/common/index.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:pure_live/plugins/cache_manager.dart';
import 'package:pure_live/global/initial_services.dart';
import 'package:pure_live/common/utils/hive_pref_util.dart';
import 'package:pure_live/global/platform/mobile_manager.dart';

class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  bool _isInitialized = false;

  factory AppInitializer() => _instance;
  AppInitializer._internal();

  bool get isInitialized => _isInitialized;

  Future<void> initialize(List<String> args) async {
    if (_isInitialized) return;

    WidgetsFlutterBinding.ensureInitialized();

    await AppPathManager().initialize();
    final Directory hiveDir = await AppPathManager().getDir(AppPathManager.dirHiveDB);

    await Future.wait([
      Hive.initFlutter(hiveDir.path).then((_) => HivePrefUtil.init()),
      CustomImageCacheManager.initialize(),
    ]);

    InitialServices.init();
    _initSmartDialog();
    // initRefresh();

    await MobileManager.initialize();

    _isInitialized = true;
  }

  void _initSmartDialog() {
    SmartDialog.config.toast = SmartConfigToast(
      displayTime: const Duration(milliseconds: 3000),
      intervalTime: const Duration(milliseconds: 100),
    );
  }
}
