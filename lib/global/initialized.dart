import 'dart:io';
import 'package:pure_live/core/index.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/core/exports/package_export.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:media_kit/media_kit.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:pure_live/global/app_path_manager.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pure_live/player/core/playback_proxy_policy.dart';

class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  bool _isInitialized = false;
  late final ProviderContainer container;

  factory AppInitializer() {
    return _instance;
  }

  AppInitializer._internal();

  Future<void> initialize() async {
    if (_isInitialized) return;

    WidgetsFlutterBinding.ensureInitialized();

    SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeRight, DeviceOrientation.landscapeLeft]);

    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    final appDir = await getApplicationDocumentsDirectory();
    final String path = '${appDir.path}${Platform.pathSeparator}pure_live_Tv';
    Hive.init(path);

    await HivePrefUtil.init();
    MediaKit.ensureInitialized();
    await AppPathManager().initialize();
    await CustomImageCacheManager.initialize();

    container = ProviderContainer();
    SettingsService.to.init(container);

    SmartDialog.config.toast = SmartConfigToast(
      displayTime: const Duration(milliseconds: 3000),
      intervalTime: const Duration(milliseconds: 100),
    );

    _isInitialized = true;

    // 旧版遗留设置迁移（pure_live GetX 版键值 → v2）
    await LegacySettingsMigration.migrateIfNeeded();

    // 弹幕 WebSocket 与 API/图片共用同一代理设置（同步自 pure_live）
    configureWebSocketProxyRouting((uri) => PlaybackProxyPolicy.currentDirective());

    // 版本信息 + 启动时检查更新
    unawaited(() async {
      await VersionUtil.initPackageInfo();
      if (SettingsService.to.appState.enableAutoCheckUpdate) {
        await VersionUtil().checkUpdate();
      }
    }());
  }

  bool get isInitialized => _isInitialized;
}
