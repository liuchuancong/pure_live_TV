import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/cache/cache_model.dart';
import 'package:pure_live/services/webdav/webdav_model.dart';
import 'package:pure_live/services/db_service/db_service.dart';
import 'package:pure_live/services/cache/cache_controller.dart';
import 'package:pure_live/services/db_service/db_controller.dart';
import 'package:pure_live/services/iptv/iptv_settings_model.dart';
import 'package:pure_live/services/webdav/webdav_controller.dart';
import 'package:pure_live/services/startUp/startup_controller.dart';
import 'package:pure_live/services/cookie_manager/cookie_model.dart';
import 'package:pure_live/services/iptv/iptv_settings_controller.dart';
import 'package:pure_live/services/history_settings/history_model.dart';
import 'package:pure_live/services/log_settings/log_settings_model.dart';
import 'package:pure_live/services/app_settings/app_settings_model.dart';
import 'package:pure_live/services/cookie_manager/cookie_controller.dart';
import 'package:pure_live/services/page_settings/page_settings_model.dart';
import 'package:pure_live/services/exit_settings/exit_settings_model.dart';
import 'package:pure_live/services/font_settings/font_settings_model.dart';
import 'package:pure_live/services/vol_settings/volume_settings_model.dart';
import 'package:pure_live/services/tag_management/tag_management_model.dart';
import 'package:pure_live/services/proxy_settings/proxy_settings_model.dart';
import 'package:pure_live/services/refresh_config/refresh_config_model.dart';
import 'package:pure_live/services/theme_settings/theme_settings_model.dart';
import 'package:pure_live/services/history_settings/history_controller.dart';
import 'package:pure_live/services/log_settings/log_settings_controller.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/services/player_settings/player_settings_model.dart';
import 'package:pure_live/services/page_settings/page_settings_controller.dart';
import 'package:pure_live/services/exit_settings/exit_settings_controller.dart';
import 'package:pure_live/services/font_settings/font_settings_controller.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_model.dart';
import 'package:pure_live/services/vol_settings/volume_settings_controller.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/tag_management/tag_management_controller.dart';
import 'package:pure_live/services/proxy_settings/proxy_settings_controller.dart';
import 'package:pure_live/services/refresh_config/refresh_config_controller.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/services/favorite_settings/favorite_settings_model.dart';
import 'package:pure_live/services/background_config/background_config_model.dart';
import 'package:pure_live/services/favorite_settings/favorite_room_controller.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';

class SettingsService {
  static final SettingsService _instance = SettingsService._internal();
  static SettingsService get to => _instance;
  SettingsService._internal();
  ProviderContainer? get container => _container;
  late final ProviderContainer _container;

  void init(ProviderContainer container) {
    _container = container;
  }

  // background
  BackgroundConfigModel get bgState => _container.read(backgroundControllerProvider);
  BackgroundController get bg => _container.read(backgroundControllerProvider.notifier);
  // startup
  bool get isFirstInApp => _container.read(startupControllerProvider);
  StartupController get startup => _container.read(startupControllerProvider.notifier);
  // app
  AppSettingsModel get appState => _container.read(appSettingsControllerProvider);
  AppSettingsController get app => _container.read(appSettingsControllerProvider.notifier);

  // dbService
  DbService get dbService => _container.read(dbServiceProvider);
  // exit
  ExitSettingsModel get exitState => _container.read(exitSettingsControllerProvider);
  ExitSettingsController get exit => _container.read(exitSettingsControllerProvider.notifier);
  // player
  PlayerSettingsModel get playerState => _container.read(playerSettingsControllerProvider);
  PlayerSettingsController get player => _container.read(playerSettingsControllerProvider.notifier);
  // font
  FontSettingsModel get fontState => _container.read(fontSettingsControllerProvider).value!;
  FontSettingsController get font => _container.read(fontSettingsControllerProvider.notifier);
  // favorite
  FavoriteSettingsModel get favState => _container.read(favoriteRoomControllerProvider);
  FavoriteRoomController get fav => _container.read(favoriteRoomControllerProvider.notifier);
  // history
  HistoryModel get historyState => _container.read(historyControllerProvider);
  HistoryController get history => _container.read(historyControllerProvider.notifier);
  // cache
  CacheModel get cacheState => _container.read(cacheControllerProvider);
  CacheController get cache => _container.read(cacheControllerProvider.notifier);
  // cookieManager
  CookieModel get cookieState => _container.read(cookieControllerProvider);
  CookieController get cookieManager => _container.read(cookieControllerProvider.notifier);
  // webDav
  WebDavModel get webDavState => _container.read(webDavControllerProvider);
  WebDavController get webDav => _container.read(webDavControllerProvider.notifier);

  IptvSettingsModel get iptvState => _container.read(iptvSettingsControllerProvider);
  IptvSettingsController get iptv => _container.read(iptvSettingsControllerProvider.notifier);
  // iptv
  VolumeSettingsModel get volumeState => _container.read(volumeSettingsControllerProvider);
  VolumeSettingsController get volume => _container.read(volumeSettingsControllerProvider.notifier);
  // theme
  ThemeSettingsController get theme => _container.read(themeSettingsControllerProvider.notifier);
  ThemeSettingsModel get themeState => _container.read(themeSettingsControllerProvider);
  // proxy
  ProxySettingsModel get proxyState => _container.read(proxySettingsControllerProvider);
  ProxySettingsController get proxy => _container.read(proxySettingsControllerProvider.notifier);
  //
  // dynamic get backup => throw UnimplementedError('等待重构为Riverpod');

  RefreshConfigModel get refreshState => _container.read(refreshConfigControllerProvider);
  RefreshConfigController get refresh => _container.read(refreshConfigControllerProvider.notifier);
  // page_settings
  PageSettingsModel get pageState => _container.read(pageSettingsControllerProvider);
  PageSettingsController get page => _container.read(pageSettingsControllerProvider.notifier);
  // log
  LogSettingsModel get logState => _container.read(logSettingsControllerProvider);
  LogSettingsController get log => _container.read(logSettingsControllerProvider.notifier);
  // tag
  TagManagementModel get tagState => _container.read(tagManagementControllerProvider);
  TagManagementController get tag => _container.read(tagManagementControllerProvider.notifier);

  // danmaku
  DanmakuSettingsModel get danmakuState => _container.read(danmakuSettingsControllerProvider);
  DanmakuSettingsController get danmaku => _container.read(danmakuSettingsControllerProvider.notifier);
}
