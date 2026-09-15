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

/// IPTV source selection and auto-sync configuration.
@riverpod
class IptvSettingsController extends _$IptvSettingsController {
  static IptvSettingsController get to => SettingsService.to.iptv;

  static const String autoSyncHoursIntervalKey = 'autoSyncHoursInterval';

  // Exposed as a reactive value for non-widget code such as the player core.
  SettingsValue<String> get selectedSourceId => SettingsValue(() => state.selectedSourceId, selectSourceId);
  SettingsValue<String> get selectedSourceName => SettingsValue(() => state.selectedSourceName, selectSourceName);
  SettingsValue<bool> get isAutoSyncEnabled => SettingsValue(() => state.isAutoSyncEnabled, setAutoSyncEnabled);

  int _sourceRevision = 0;

  /// Source selection revision. Long-running work such as EPG remapping uses it
  /// to notice a mid-session source switch, including A to B to A changes that
  /// comparing current values would miss.
  int get sourceRevision => _sourceRevision;

  void selectSourceId(String id) => selectSource(state.selectedSourceName, id);

  void selectSourceName(String name) => selectSource(name, state.selectedSourceId);

  @override
  IptvSettingsModel build() {
    return IptvSettingsModel(
      selectedSourceName: HivePrefUtil.getString('selectedSourceName') ?? '',
      selectedSourceId: HivePrefUtil.getString('selectedSourceId') ?? '',
      isAutoSyncEnabled: HivePrefUtil.getBool('isAutoSyncEnabled') ?? false,
      autoSyncHoursInterval: normalizeIptvAutoSyncHours(
        HivePrefUtil.getInt(autoSyncHoursIntervalKey) ?? iptvDefaultAutoSyncHours,
      ),
      customIptvUserAgent: HivePrefUtil.getString('customIptvUserAgent') ?? '',
      m3uDirectory: HivePrefUtil.getString('m3uDirectory') ?? 'm3uDirectory',
    );
  }

  void updateSettings(IptvSettingsModel newModel) {
    state = newModel.copyWith(
      autoSyncHoursInterval: normalizeIptvAutoSyncHours(newModel.autoSyncHoursInterval),
    );
    _persist();
  }

  void selectSource(String sourceName, String sourceId) {
    _sourceRevision++;
    updateSettings(state.copyWith(selectedSourceName: sourceName, selectedSourceId: sourceId));
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

  int normalizeCurrentAutoSyncHours() {
    final normalized = normalizeIptvAutoSyncHours(state.autoSyncHoursInterval);
    if (normalized != state.autoSyncHoursInterval) {
      state = state.copyWith(autoSyncHoursInterval: normalized);
      _persist();
    }
    return normalized;
  }

  void _persist() {
    HivePrefUtil.setString('selectedSourceName', state.selectedSourceName);
    HivePrefUtil.setString('selectedSourceId', state.selectedSourceId);
    HivePrefUtil.setBool('isAutoSyncEnabled', state.isAutoSyncEnabled);
    HivePrefUtil.setInt(autoSyncHoursIntervalKey, state.autoSyncHoursInterval);
    HivePrefUtil.setString('customIptvUserAgent', state.customIptvUserAgent);
    HivePrefUtil.setString('m3uDirectory', state.m3uDirectory);
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
      'selectedSourceName': (json['selectedSourceName'] ?? '') as String,
      'selectedSourceId': (json['selectedSourceId'] ?? '') as String,
      'isAutoSyncEnabled': (json['isAutoSyncEnabled'] ?? false) as bool,
      'autoSyncHoursInterval': normalizeIptvAutoSyncHours(
        rawHours is int ? rawHours : iptvDefaultAutoSyncHours,
      ),
      'customIptvUserAgent': (json['customIptvUserAgent'] ?? '') as String,
      'm3uDirectory': (json['m3uDirectory'] ?? 'm3uDirectory') as String,
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
