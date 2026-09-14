/// Riverpod Provider 公共出口。
///
/// Provider 与其控制器定义在同一个文件里（riverpod_generator 生成），
/// 这里集中列出跨模块使用的 Provider，避免业务文件记住每个 provider 变量名在哪里声明。
library;

export 'package:pure_live/services/settings/settings.dart';
export 'package:pure_live/services/app_settings/app_settings_controller.dart';
export 'package:pure_live/services/cookie_manager/cookie_controller.dart';
export 'package:pure_live/services/cookie_manager/bilibili/bilibili_account_controller.dart';
export 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';
export 'package:pure_live/services/favorite_settings/favorite_room_controller.dart';
export 'package:pure_live/services/font_settings/font_settings_controller.dart';
export 'package:pure_live/services/history_settings/history_controller.dart';
export 'package:pure_live/services/iptv_settings/iptv_settings_controller.dart';
export 'package:pure_live/services/page_settings/page_settings_controller.dart';
export 'package:pure_live/services/player_settings/player_settings_controller.dart';
export 'package:pure_live/services/proxy_settings/proxy_settings_controller.dart';
export 'package:pure_live/services/refresh_config/refresh_config_controller.dart';
export 'package:pure_live/services/startUp/startup_controller.dart';
export 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
export 'package:pure_live/services/tag_management/tag_management_controller.dart';
export 'package:pure_live/services/vol_settings/volume_settings_controller.dart';
export 'package:pure_live/services/webdav/webdav_controller.dart';
export 'package:pure_live/theme/tv_theme_controller.dart';
