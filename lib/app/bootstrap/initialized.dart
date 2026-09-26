import 'dart:io';
import 'dart:async';
import 'package:hive_ce/hive_ce.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_core/media_core.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/platform/local_network_access.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/app/bootstrap/app_path_manager.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:media_core_logging/media_core_logging.dart';
import 'package:pure_live/player/core/playback_proxy_policy.dart';
import 'package:pure_live/player/global_player_service.dart';

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
    // Image cache setup is not needed for the first frame: run it in the
    // background so startup is not blocked (the getter falls back to the
    // default cache until it is ready).
    unawaited(CustomImageCacheManager.initialize());

    container = ProviderContainer();
    SettingsService.to.init(container);

    SmartDialog.config.toast = SmartConfigToast(
      displayTime: const Duration(milliseconds: 3000),
      intervalTime: const Duration(milliseconds: 100),
    );

    _isInitialized = true;

    // Migrate legacy Hive keys into the v2 settings store.
    await LegacySettingsMigration.migrateIfNeeded();

    // Restore the optional local log file before playback starts, so a release
    // build can be diagnosed from the device.
    unawaited(Log.init());

    // Probe the platform once, early: the player kernel takes the result when it
    // is created later, and the danmaku frame budget reads it before the first
    // player exists.
    unawaited(GlobalPlayerService.instance.loadPlatformProvider());

    // Danmaku sockets reuse the proxy policy configured for API and image traffic.
    configureWebSocketProxyRouting((uri) => PlaybackProxyPolicy.currentDirective());

    // Version info plus the startup update check.
    //
    // The check does an HTTP fetch and a JSON parse on the main isolate; running
    // it while the first frames were being built competed with startup (logcat
    // showed 65-99 skipped frames and a frame-time warning). It is deferred past
    // the first frames instead, and only the cheap package-info read happens
    // now.
    unawaited(() async {
      await VersionUtil.initPackageInfo();
      if (!SettingsService.to.appState.enableAutoCheckUpdate) return;
      await Future<void>.delayed(const Duration(seconds: 3));
      await VersionUtil().checkUpdate();
    }());

    // Taobao Live was retired; its account cookie is dropped once so it cannot
    // be re-exported by a later backup.
    HivePrefUtil.remove('taobaoCookie');

    // Android 17 gates sockets to a local-network proxy behind
    // ACCESS_LOCAL_NETWORK, so an existing PC/router proxy asks for it on every
    // launch. Deferred past the first frames: the request needs an attached
    // activity and must not compete with startup. The permission only exists on
    // Android, so no timer is scheduled anywhere else.
    if (Platform.isAndroid) {
      unawaited(() async {
        await Future<void>.delayed(const Duration(seconds: 2));
        final proxy = SettingsService.to.proxyState;
        await LocalNetworkAccess.ensureForProxies([
          (enabled: proxy.enableAppProxy, host: proxy.appProxyHost),
          (enabled: proxy.enableProxy, host: proxy.proxyHost),
        ]);
      }());
    }

    // media_core is silent by default; diagnostics are turned on for debug
    // builds only, so a release build prints nothing unless it opts in.
    if (kDebugMode) {
      MediaCoreLog.level = LogLevel.debug;
    }
  }

  bool get isInitialized => _isInitialized;
}
