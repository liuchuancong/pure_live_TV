import 'iptv_settings_model.dart';
import 'package:pure_live/core/sites/sites.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/sites/iptv/services/auto_sync_scheduler.dart';

part 'iptv_settings_controller.g.dart';

@riverpod
class IptvSettingsController extends _$IptvSettingsController {
  static IptvSettingsController get to => SettingsService.to.iptv;
  @override
  IptvSettingsModel build() {
    _initAutoSync();
    return IptvSettingsModel(
      selectedSourceName: HivePrefUtil.getString('selectedSourceName') ?? '',
      selectedSourceId: HivePrefUtil.getString('selectedSourceId') ?? '',
      isAutoSyncEnabled: HivePrefUtil.getBool('isAutoSyncEnabled') ?? false,
      autoSyncHoursInterval: HivePrefUtil.getInt('autoShutDownTime') ?? 24,
      customIptvUserAgent: HivePrefUtil.getString('customIptvUserAgent') ?? '',
      m3uDirectory: HivePrefUtil.getString('m3uDirectory') ?? 'm3uDirectory',
    );
  }

  void _initAutoSync() {
    Future.delayed(const Duration(seconds: 3), () {
      if (HivePrefUtil.getStringList('hotAreasList')?.contains(Sites.iptvSite) ?? false) {
        AutoSyncScheduler.instance.checkAndExecuteAutoSync();
        AutoSyncScheduler.instance.loadHotResources();
        AutoSyncScheduler.instance.loadDefaultEpgResources();
      }
    });
  }

  void update(IptvSettingsModel newModel) {
    state = newModel;
    _persist();
  }

  void _persist() {
    HivePrefUtil.setString('selectedSourceName', state.selectedSourceName);
    HivePrefUtil.setString('selectedSourceId', state.selectedSourceId);
    HivePrefUtil.setBool('isAutoSyncEnabled', state.isAutoSyncEnabled);
    HivePrefUtil.setInt('autoShutDownTime', state.autoSyncHoursInterval);
    HivePrefUtil.setString('customIptvUserAgent', state.customIptvUserAgent);
    HivePrefUtil.setString('m3uDirectory', state.m3uDirectory);
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = IptvSettingsModel.fromJson(json);
    _persist();
  }
}
