import 'iptv_settings_model.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/settings/settings_value.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'iptv_settings_controller.g.dart';

/// IPTV auto-sync interval bounds and normalization.
const int iptvDefaultAutoSyncHours = 24;
const int iptvMinAutoSyncHours = 2;
const int iptvMaxAutoSyncHours = 72;

int normalizeIptvAutoSyncHours(int hours) => hours.clamp(iptvMinAutoSyncHours, iptvMaxAutoSyncHours);

/// IPTV auto-sync configuration.
@riverpod
class IptvSettingsController extends _$IptvSettingsController {
  static IptvSettingsController get to => SettingsService.to.iptv;

  static const String autoSyncHoursIntervalKey = 'autoSyncHoursInterval';

  /// The built-in hot-list subscription, imported into the fixed system hot
  /// provider when the recommendation list runs empty. Stored as the canonical
  /// raw address; the download races it through the GitHub mirrors.
  static const String defaultHotResourceUrl = 'https://raw.githubusercontent.com/vbskycn/iptv/master/tv/iptv4.m3u';

  // Exposed as a reactive value for non-widget code such as the player core.
  SettingsValue<bool> get isAutoSyncEnabled => SettingsValue(() => state.isAutoSyncEnabled, setAutoSyncEnabled);

  /// The URL the hot import actually uses — the user's override, or the
  /// built-in default when the override is blank.
  String get effectiveHotResourceUrl {
    final url = state.hotResourceUrl.trim();
    return url.isEmpty ? defaultHotResourceUrl : url;
  }

  /// The raw override; empty means the built-in default applies.
  SettingsValue<String> get hotResourceUrl => SettingsValue(() => state.hotResourceUrl, setHotResourceUrl);

  @override
  IptvSettingsModel build() {
    return IptvSettingsModel(
      isAutoSyncEnabled: HivePrefUtil.getBool('isAutoSyncEnabled') ?? false,
      autoSyncHoursInterval: normalizeIptvAutoSyncHours(
        HivePrefUtil.getInt(autoSyncHoursIntervalKey) ?? iptvDefaultAutoSyncHours,
      ),
      customIptvUserAgent: HivePrefUtil.getString('customIptvUserAgent') ?? '',
      customIptvReferer: HivePrefUtil.getString('customIptvReferer') ?? '',
      customIptvCookie: HivePrefUtil.getString('customIptvCookie') ?? '',
      m3uDirectory: HivePrefUtil.getString('m3uDirectory') ?? 'm3uDirectory',
      hotResourceUrl: HivePrefUtil.getString('hotResourceUrl') ?? '',
    );
  }

  void setHotResourceUrl(String url) {
    updateSettings(state.copyWith(hotResourceUrl: url.trim()));
  }

  void updateSettings(IptvSettingsModel newModel) {
    state = newModel.copyWith(
      autoSyncHoursInterval: normalizeIptvAutoSyncHours(newModel.autoSyncHoursInterval),
    );
    _persist();
  }

  void setAutoSyncEnabled(bool enabled) {
    updateSettings(state.copyWith(isAutoSyncEnabled: enabled));
  }

  void setAutoSyncHoursInterval(int hours) {
    updateSettings(state.copyWith(autoSyncHoursInterval: hours));
  }

  void setCustomIptvUserAgent(String userAgent) {
    updateSettings(state.copyWith(customIptvUserAgent: userAgent));
  }

  void setCustomIptvReferer(String referer) {
    updateSettings(state.copyWith(customIptvReferer: referer));
  }

  void setCustomIptvCookie(String cookie) {
    updateSettings(state.copyWith(customIptvCookie: cookie));
  }

  int normalizeCurrentAutoSyncHours() {
    final normalized = normalizeIptvAutoSyncHours(state.autoSyncHoursInterval);
    if (normalized != state.autoSyncHoursInterval) {
      state = state.copyWith(autoSyncHoursInterval: normalized);
      _persist();
    }
    return normalized;
  }

  void _persist() {
    HivePrefUtil.setBool('isAutoSyncEnabled', state.isAutoSyncEnabled);
    HivePrefUtil.setInt(autoSyncHoursIntervalKey, state.autoSyncHoursInterval);
    HivePrefUtil.setString('customIptvUserAgent', state.customIptvUserAgent);
    HivePrefUtil.setString('customIptvReferer', state.customIptvReferer);
    HivePrefUtil.setString('customIptvCookie', state.customIptvCookie);
    HivePrefUtil.setString('m3uDirectory', state.m3uDirectory);
    HivePrefUtil.setString('hotResourceUrl', state.hotResourceUrl);
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    final model = IptvSettingsModel.fromJson(json);
    state = model.copyWith(autoSyncHoursInterval: normalizeIptvAutoSyncHours(model.autoSyncHoursInterval));
    _persist();
  }

  /// Parses the iptv section without notifying observers or persisting.
  static Map<String, dynamic> parseConfig(Map<String, dynamic> json) {
    final rawHours = json['autoSyncHoursInterval'];
    return {
      'isAutoSyncEnabled': (json['isAutoSyncEnabled'] ?? false) as bool,
      'autoSyncHoursInterval': normalizeIptvAutoSyncHours(
        rawHours is int ? rawHours : iptvDefaultAutoSyncHours,
      ),
      'customIptvUserAgent': (json['customIptvUserAgent'] ?? '') as String,
      'customIptvReferer': (json['customIptvReferer'] ?? '') as String,
      'customIptvCookie': (json['customIptvCookie'] ?? '') as String,
      'm3uDirectory': (json['m3uDirectory'] ?? 'm3uDirectory') as String,
      'hotResourceUrl': (json['hotResourceUrl'] ?? '') as String,
    };
  }

  /// Extracts the iptv section from a backup root document.
  static Map<String, dynamic> extractConfig(Map<String, dynamic>? rootConfig) {
    final iptv = rootConfig?['iptv'] as Map<String, dynamic>? ?? {};
    return parseConfig(iptv);
  }

  static Map<String, dynamic> mergeConfig(Map<String, dynamic> rootConfig, Map<String, dynamic> updateFields) {
    final iptv = Map<String, dynamic>.from(rootConfig['iptv'] ?? {});
    updateFields.forEach((k, v) => iptv[k] = v);
    rootConfig['iptv'] = iptv;
    return rootConfig;
  }
}
