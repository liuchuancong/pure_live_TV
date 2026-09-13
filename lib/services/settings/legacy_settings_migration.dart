import 'dart:convert';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';

/// 旧版（pure_live GetX 版）遗留 Hive 键值迁移到 v2 设置体系。
/// 同步自 pure_live 的 LegacySettingsMigration，控制器定位改走
/// TV 的 SettingsService 外观（Riverpod ProviderContainer）。
class LegacySettingsMigration {
  static const _migratedKey = 'legacy_settings_migrated_to_v2';

  static Future<void> migrateIfNeeded() async {
    if (HivePrefUtil.getBool(_migratedKey) ?? false) {
      return;
    }

    final legacyData = _readLegacyAllData();
    if (legacyData.isEmpty) {
      HivePrefUtil.setBool(_migratedKey, true);
      return;
    }

    await _migrateToNewControllers(legacyData);

    HivePrefUtil.setBool(_migratedKey, true);
  }

  static Map<String, dynamic> _readLegacyAllData() {
    try {
      return {
        "themeMode": HivePrefUtil.getString("themeMode"),
        "enableDynamicTheme": HivePrefUtil.getBool("enableDynamicTheme"),
        "themeColorSwitch": HivePrefUtil.getString("themeColorSwitch"),
        "language": HivePrefUtil.getString("language"),
        "languageName": HivePrefUtil.getString("languageName"),

        "autoRefreshTime": HivePrefUtil.getInt("autoRefreshTime"),
        "enableDenseFavorites": HivePrefUtil.getBool("enableDenseFavorites"),
        "enableBackgroundPlay": HivePrefUtil.getBool("enableBackgroundPlay"),
        "enableStartUp": HivePrefUtil.getBool("enableStartUp"),
        "enableRotateScreenWithSystem": HivePrefUtil.getBool("enableRotateScreenWithSystem"),
        "enableScreenKeepOn": HivePrefUtil.getBool("enableScreenKeepOn"),
        "enableAutoCheckUpdate": HivePrefUtil.getBool("enableAutoCheckUpdate"),
        "enableFullScreenDefault": HivePrefUtil.getBool("enableFullScreenDefault"),
        "showSplashPage": HivePrefUtil.getBool("showSplashPage"),
        "textScaleFactor": HivePrefUtil.getDouble("textScaleFactor"),
        "crossAxisSpacing": HivePrefUtil.getDouble("crossAxisSpacing"),
        "mainAxisSpacing": HivePrefUtil.getDouble("mainAxisSpacing"),
        "loadingStyle": HivePrefUtil.getString("loadingStyle"),
        "loadingStyleColorSwitch": HivePrefUtil.getString("loadingStyleColorSwitch"),

        // 自动关机
        "autoShutDownTime": HivePrefUtil.getInt("autoShutDownTime"),
        "enableAutoShutDownTime": HivePrefUtil.getBool("enableAutoShutDownTime"),

        // 退出
        "dontAskExit": HivePrefUtil.getBool("dontAskExit"),
        "exitChoose": HivePrefUtil.getString("exitChoose"),

        // 字体
        "fontSizeBodySmall": HivePrefUtil.getDouble("fontSizeBodySmall"),
        "fontSizeBodyMedium": HivePrefUtil.getDouble("fontSizeBodyMedium"),
        "fontSizeBodyLarge": HivePrefUtil.getDouble("fontSizeBodyLarge"),
        "fontSizeTitleMedium": HivePrefUtil.getDouble("fontSizeTitleMedium"),
        "fontSizeTitleLarge": HivePrefUtil.getDouble("fontSizeTitleLarge"),
        "fontFamilyName": HivePrefUtil.getString("fontFamilyName"),
        "danmakuFontFamilyName": HivePrefUtil.getString("danmakuFontFamilyName"),

        // 播放器
        "videoFitIndex": HivePrefUtil.getInt("videoFitIndex"),
        "videoPlayerKey": HivePrefUtil.getString("videoPlayerKey"),
        "useHardStopOnExit": HivePrefUtil.getBool("useHardStopOnExit"),
        "enableCodec": HivePrefUtil.getBool("enableCodec"),
        "playerCompatMode": HivePrefUtil.getBool("playerCompatMode"),
        "customPlayerOutput": HivePrefUtil.getBool("customPlayerOutput"),
        "videoOutputDriver": HivePrefUtil.getString("videoOutputDriver"),
        "audioOutputDriver": HivePrefUtil.getString("audioOutputDriver"),
        "videoHardwareDecoder": HivePrefUtil.getString("videoHardwareDecoder"),
        "floatPlay": HivePrefUtil.getBool("floatPlay"),
        "audioOnly": HivePrefUtil.getBool("audioOnly"),
        "preferResolution": HivePrefUtil.getString("preferResolution"),
        "preferResolutionCellular": HivePrefUtil.getString("preferResolutionCellular"),
        "preferPlatform": HivePrefUtil.getString("preferPlatform"),

        // 弹幕
        "hideDanmaku": HivePrefUtil.getBool("hideDanmaku"),
        "danmakuTopArea": HivePrefUtil.getDouble("danmakuTopArea"),
        "danmakuArea": HivePrefUtil.getDouble("danmakuArea"),
        "danmakuBottomArea": HivePrefUtil.getDouble("danmakuBottomArea"),
        "danmakuSpeed": HivePrefUtil.getDouble("danmakuSpeed"),
        "danmakuFontSize": HivePrefUtil.getDouble("danmakuFontSize"),
        "danmakuFontBorder": HivePrefUtil.getDouble("danmakuFontBorder"),
        "danmakuOpacity": HivePrefUtil.getDouble("danmakuOpacity"),
        "enableDanmakuDisplay": HivePrefUtil.getBool("enableDanmakuDisplay"),

        // 音量
        "defaultMobileVolume": HivePrefUtil.getDouble("defaultMobileVolume"),
        "defaultDesktopVolume": HivePrefUtil.getDouble("defaultDesktopVolume"),
        "globalVolumeMute": HivePrefUtil.getBool("globalVolumeMute"),
        "roomVolumes": _decodeJsonMap(HivePrefUtil.getString("roomVolumes")),

        // Cookie
        "bilibiliCookie": HivePrefUtil.getString("bilibiliCookie"),
        "huyaCookie": HivePrefUtil.getString("huyaCookie"),
        "douyinCookie": HivePrefUtil.getString("douyinCookie"),
        "kuaishouCookie": HivePrefUtil.getString("kuaishouCookie"),

        // 代理
        "enableProxy": HivePrefUtil.getBool("enableProxy"),
        "proxyHost": HivePrefUtil.getString("proxyHost"),
        "proxyPort": HivePrefUtil.getInt("proxyPort"),

        // 收藏、历史、屏蔽
        "favoriteRooms": HivePrefUtil.getStringList("favoriteRooms"),
        "historyRooms": HivePrefUtil.getStringList("historyRooms"),
        "favoriteAreas": HivePrefUtil.getStringList("favoriteAreas"),
        "shieldList": HivePrefUtil.getStringList("shieldList"),
        "hotAreasList": HivePrefUtil.getStringList("hotAreasList"),
        "savedMenuIds": HivePrefUtil.getStringList("savedMenuIds"),

        // WebDAV
        "backupDirectory": HivePrefUtil.getString("backupDirectory"),
        "currentWebDavConfig": HivePrefUtil.getString("currentWebDavConfig"),
        "webDavConfigs": HivePrefUtil.getStringList("webDavConfigs"),
        "m3uDirectory": HivePrefUtil.getString("m3uDirectory"),
      };
    } catch (e) {
      return {};
    }
  }

  static Future<void> _migrateToNewControllers(Map<String, dynamic> legacy) async {
    final s = SettingsService.to;
    s.app.importFromJson(legacy);
    s.theme.importFromJson(legacy);
    s.font.importFromJson(legacy);
    s.player.importFromJson(legacy);
    s.danmaku.importFromJson(legacy);
    s.volume.importFromJson(legacy);
    s.fav.importFromJson(legacy);
    s.history.importFromJson(legacy);
    s.webDav.importFromJson(legacy);
    s.cookieManager.importFromJson(legacy);
    s.proxy.importFromJson(legacy);
    s.exit.importFromJson(legacy);
  }

  static Map<String, dynamic> _decodeJsonMap(String? json) {
    if (json == null || json.isEmpty) return {};
    try {
      return Map<String, dynamic>.from(jsonDecode(json));
    } catch (_) {
      return {};
    }
  }
}
