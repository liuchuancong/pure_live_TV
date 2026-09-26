import 'cookie_model.dart';
import 'cookie_value.dart';
import 'bilibili/bilibili_account_service.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/settings/settings_value.dart';

part 'cookie_controller.g.dart';

/// Normalizes and validates per-platform cookie values.
@riverpod
class CookieController extends _$CookieController {
  static CookieController get to => SettingsService.to.cookieManager;

  // Exposed as a reactive value for non-widget code such as the player core.
  SettingsValue<String> get bilibiliCookie => SettingsValue(() => state.bilibiliCookie);
  SettingsValue<int> get bilibiliUid => SettingsValue(() => state.bilibiliUid);
  SettingsValue<String> get huyaCookie => SettingsValue(() => state.huyaCookie);
  SettingsValue<String> get douyuCookie => SettingsValue(() => state.douyuCookie);
  SettingsValue<String> get douyuLtp0 => SettingsValue(() => state.douyuLtp0);
  SettingsValue<String> get douyuDid => SettingsValue(() => state.douyuDid);
  SettingsValue<int> get douyuCookieSavedAt => SettingsValue(() => state.douyuCookieSavedAt);
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
      douyuCookie: normalizeAccountCookie(HivePrefUtil.getString('douyuCookie') ?? ''),
      douyuLtp0: HivePrefUtil.getString('douyuLtp0') ?? '',
      douyuDid: HivePrefUtil.getString('douyuDid') ?? '',
      douyuCookieSavedAt: HivePrefUtil.getInt('douyuCookieSavedAt') ?? 0,
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
      douyuCookie: normalizeAccountCookie(model.douyuCookie),
      douyuLtp0: normalizeAccountCookie(model.douyuLtp0),
      douyuDid: normalizeAccountCookie(model.douyuDid),
      douyuCookieSavedAt: model.douyuCookieSavedAt,
      douyinCookie: normalizeAccountCookie(model.douyinCookie),
      kuaishouCookie: normalizeAccountCookie(model.kuaishouCookie),
      yyCookie: normalizeAccountCookie(model.yyCookie),
      soopCookie: normalizeAccountCookie(model.soopCookie),
      twitchCookie: normalizeAccountCookie(model.twitchCookie),
    );
  }

  // ------------------------------------------------------------------
  // Per-platform setters.
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

  void setDouyuCookie(String cookie) => _setPlatformCookie((m, v) => m.copyWith(douyuCookie: v), cookie);

  /// The renewal pair from the passport request (`LTP0` / `dy_did`). They are
  /// not part of the page cookie, so they are stored beside it.
  void setDouyuCredentials({required String ltp0, required String did}) {
    final next = state.copyWith(
      douyuLtp0: normalizeAccountCookie(ltp0),
      douyuDid: normalizeAccountCookie(did),
    );
    if (next == state) return;
    state = next;
    _persist(state);
  }

  /// When the Douyu cookie was stored, in seconds. `dy_auth` is opaque, so its
  /// seven-day lifetime can only be counted from this moment.
  void setDouyuCookieSavedAt(int seconds) {
    if (seconds == state.douyuCookieSavedAt) return;
    state = state.copyWith(douyuCookieSavedAt: seconds);
    _persist(state);
  }

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
    state = const CookieModel(bilibiliUid: 0);
    _persist(state);
  }

  void _persist(CookieModel model) {
    HivePrefUtil.setString('bilibiliCookie', model.bilibiliCookie);
    HivePrefUtil.setInt('bilibiliUid', model.bilibiliUid);
    HivePrefUtil.setString('huyaCookie', model.huyaCookie);
    HivePrefUtil.setString('douyuCookie', model.douyuCookie);
    HivePrefUtil.setString('douyuLtp0', model.douyuLtp0);
    HivePrefUtil.setString('douyuDid', model.douyuDid);
    HivePrefUtil.setInt('douyuCookieSavedAt', model.douyuCookieSavedAt);
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

  /// Parses the cookie section without notifying observers or persisting.
  static Map<String, dynamic> parseConfig(Map<String, dynamic> json) {
    return {
      'bilibiliCookie': normalizeAccountCookie((json['bilibiliCookie'] ?? '') as String),
      'huyaCookie': normalizeAccountCookie((json['huyaCookie'] ?? '') as String),
      'douyuCookie': normalizeAccountCookie((json['douyuCookie'] ?? '') as String),
      'douyuLtp0': normalizeAccountCookie((json['douyuLtp0'] ?? '') as String),
      'douyuDid': normalizeAccountCookie((json['douyuDid'] ?? '') as String),
      'douyuCookieSavedAt': (json['douyuCookieSavedAt'] ?? 0) as int,
      'douyinCookie': normalizeAccountCookie((json['douyinCookie'] ?? '') as String),
      'kuaishouCookie': normalizeAccountCookie((json['kuaishouCookie'] ?? '') as String),
      'bilibiliUid': (json['bilibiliUid'] ?? 0) as int,
      'twitchCookie': normalizeAccountCookie((json['twitchCookie'] ?? '') as String),
      'soopCookie': normalizeAccountCookie((json['soopCookie'] ?? '') as String),
      'yyCookie': normalizeAccountCookie((json['yyCookie'] ?? '') as String),
    };
  }

  /// Extracts the cookie section from a backup root document.
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
