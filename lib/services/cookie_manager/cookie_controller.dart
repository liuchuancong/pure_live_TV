import 'cookie_model.dart';
import 'cookie_value.dart';
import 'bilibili/bilibili_account_service.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/settings/settings_value.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cookie_controller.g.dart';

/// 同步自 pure_live CookieSettingsController：各平台 Cookie 的归一化/校验。
@riverpod
class CookieController extends _$CookieController {
  static CookieController get to => SettingsService.to.cookieManager;

  // 供播放器核心等非 widget 代码反应式读取。
  SettingsValue<String> get bilibiliCookie => SettingsValue(() => state.bilibiliCookie);
  SettingsValue<int> get bilibiliUid => SettingsValue(() => state.bilibiliUid);
  SettingsValue<String> get huyaCookie => SettingsValue(() => state.huyaCookie);
  SettingsValue<String> get douyinCookie => SettingsValue(() => state.douyinCookie);
  SettingsValue<String> get kuaishouCookie => SettingsValue(() => state.kuaishouCookie);
  SettingsValue<String> get yyCookie => SettingsValue(() => state.yyCookie);
  SettingsValue<String> get soopCookie => SettingsValue(() => state.soopCookie);
  SettingsValue<String> get twitchCookie => SettingsValue(() => state.twitchCookie);

  @override
  CookieModel build() {
    final model = CookieModel(
      bilibiliCookie: normalizeAccountCookie(HivePrefUtil.getString('bilibiliCookie') ?? ''),
      bilibiliUid: HivePrefUtil.getInt('bilibiliUid') ?? 0,
      huyaCookie: normalizeAccountCookie(HivePrefUtil.getString('huyaCookie') ?? ''),
      douyinCookie: normalizeAccountCookie(HivePrefUtil.getString('douyinCookie') ?? ''),
      kuaishouCookie: normalizeAccountCookie(HivePrefUtil.getString('kuaishouCookie') ?? ''),
      yyCookie: normalizeAccountCookie(HivePrefUtil.getString('yyCookie') ?? ''),
      soopCookie: normalizeAccountCookie(HivePrefUtil.getString('soopCookie') ?? ''),
      twitchCookie: normalizeAccountCookie(HivePrefUtil.getString('twitchCookie') ?? ''),
    );
    _persist(model);
    return model;
  }

  void updateCookies(CookieModel newCookies) {
    state = _normalize(newCookies);
    _persist(state);
  }

  CookieModel _normalize(CookieModel model) {
    return CookieModel(
      bilibiliCookie: normalizeAccountCookie(model.bilibiliCookie),
      bilibiliUid: model.bilibiliUid,
      huyaCookie: normalizeAccountCookie(model.huyaCookie),
      douyinCookie: normalizeAccountCookie(model.douyinCookie),
      kuaishouCookie: normalizeAccountCookie(model.kuaishouCookie),
      yyCookie: normalizeAccountCookie(model.yyCookie),
      soopCookie: normalizeAccountCookie(model.soopCookie),
      twitchCookie: normalizeAccountCookie(model.twitchCookie),
    );
  }

  // ------------------------------------------------------------------
  // per-platform setters（同步自 pure_live 的逐平台 Cookie 校验）
  // ------------------------------------------------------------------

  void setBilibiliCookie(String cookie) {
    final normalized = normalizeAccountCookie(cookie);
    if (normalized == state.bilibiliCookie) return;
    state = state.copyWith(bilibiliCookie: normalized);
    _persist(state);
    BilibiliAccountService.instance.loadUserInfo();
  }

  void setBilibiliUid(int uid) {
    if (uid == state.bilibiliUid) return;
    state = state.copyWith(bilibiliUid: uid);
    _persist(state);
  }

  void setHuyaCookie(String cookie) => _setPlatformCookie((m, v) => m.copyWith(huyaCookie: v), cookie);

  void setDouyinCookie(String cookie) => _setPlatformCookie((m, v) => m.copyWith(douyinCookie: v), cookie);

  void setKuaishouCookie(String cookie) => _setPlatformCookie((m, v) => m.copyWith(kuaishouCookie: v), cookie);

  void setYyCookie(String cookie) => _setPlatformCookie((m, v) => m.copyWith(yyCookie: v), cookie);

  void setSoopCookie(String cookie) => _setPlatformCookie((m, v) => m.copyWith(soopCookie: v), cookie);

  void setTwitchCookie(String cookie) => _setPlatformCookie((m, v) => m.copyWith(twitchCookie: v), cookie);

  void _setPlatformCookie(CookieModel Function(CookieModel, String) apply, String cookie) {
    final normalized = normalizeAccountCookie(cookie);
    final next = apply(state, normalized);
    if (next == state) return;
    state = next;
    _persist(state);
  }

  void clearAllCookies() {
    state = const CookieModel();
    _persist(state);
  }

  void _persist(CookieModel model) {
    HivePrefUtil.setString('bilibiliCookie', model.bilibiliCookie);
    HivePrefUtil.setInt('bilibiliUid', model.bilibiliUid);
    HivePrefUtil.setString('huyaCookie', model.huyaCookie);
    HivePrefUtil.setString('douyinCookie', model.douyinCookie);
    HivePrefUtil.setString('kuaishouCookie', model.kuaishouCookie);
    HivePrefUtil.setString('yyCookie', model.yyCookie);
    HivePrefUtil.setString('soopCookie', model.soopCookie);
    HivePrefUtil.setString('twitchCookie', model.twitchCookie);
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = _normalize(CookieModel.fromJson(json));
    _persist(state);
    BilibiliAccountService.instance.loadUserInfo();
  }

  /// 同步自 pure_live：解析 cookie 分区但不通知观察者/不持久化。
  static Map<String, dynamic> parseConfig(Map<String, dynamic> json) {
    return {
      'bilibiliCookie': normalizeAccountCookie((json['bilibiliCookie'] ?? '') as String),
      'huyaCookie': normalizeAccountCookie((json['huyaCookie'] ?? '') as String),
      'douyinCookie': normalizeAccountCookie((json['douyinCookie'] ?? '') as String),
      'kuaishouCookie': normalizeAccountCookie((json['kuaishouCookie'] ?? '') as String),
      'bilibiliUid': (json['bilibiliUid'] ?? 0) as int,
      'twitchCookie': normalizeAccountCookie((json['twitchCookie'] ?? '') as String),
      'soopCookie': normalizeAccountCookie((json['soopCookie'] ?? '') as String),
      'yyCookie': normalizeAccountCookie((json['yyCookie'] ?? '') as String),
    };
  }

  /// 同步自 pure_live：从备份根配置中提取 cookie 分区。
  static Map<String, dynamic> extractConfig(Map<String, dynamic>? rootConfig) {
    final cookie = rootConfig?['cookie'] as Map<String, dynamic>? ?? {};
    return parseConfig(cookie);
  }

  static Map<String, dynamic> mergeConfig(Map<String, dynamic> rootConfig, Map<String, dynamic> updateFields) {
    final cookie = Map<String, dynamic>.from(rootConfig['cookie'] ?? {});
    updateFields.forEach((k, v) => cookie[k] = v);
    rootConfig['cookie'] = cookie;
    return rootConfig;
  }
}
