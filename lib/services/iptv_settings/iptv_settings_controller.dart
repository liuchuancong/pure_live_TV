import 'iptv_settings_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/settings/settings_value.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'iptv_settings_controller.g.dart';

/// 同步自 pure_live IptvSettingsController 的常量。
const int iptvDefaultAutoSyncHours = 24;
const int iptvMinAutoSyncHours = 2;
const int iptvMaxAutoSyncHours = 72;

int normalizeIptvAutoSyncHours(int hours) => hours.clamp(iptvMinAutoSyncHours, iptvMaxAutoSyncHours);

/// 同步自 pure_live IptvSettingsController：IPTV 源选择与自动同步配置。
@riverpod
class IptvSettingsController extends _$IptvSettingsController {
  static IptvSettingsController get to => SettingsService.to.iptv;

  static const String autoSyncHoursIntervalKey = 'autoSyncHoursInterval';

  // 供播放器核心等非 widget 代码反应式读写。
  SettingsValue<String> get selectedSourceId => SettingsValue(() => state.selectedSourceId, selectSourceId);
  SettingsValue<String> get selectedSourceName => SettingsValue(() => state.selectedSourceName, selectSourceName);
  SettingsValue<bool> get isAutoSyncEnabled => SettingsValue(() => state.isAutoSyncEnabled, setAutoSyncEnabled);

  int _sourceRevision = 0;

  /// 源选择变更版本号。长任务（EPG 映射重建等）用它检测会话期间的源切换，
  /// 包括 A→B→A 这种仅靠比较当前值看不出来的情况。
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

  /// 同步自 pure_live：解析 iptv 分区但不通知观察者/不持久化。
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

  /// 同步自 pure_live：从备份根配置中提取 iptv 分区。
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
