import 'refresh_config_model.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'refresh_config_controller.g.dart';

@riverpod
class RefreshConfigController extends _$RefreshConfigController {
  static RefreshConfigController get to => SettingsService.to.refresh;
  @override
  RefreshConfigModel build() {
    return RefreshConfigModel(
      autoRefreshFavorite: HivePrefUtil.getBool('autoRefreshFavorite') ?? false,
      autoRefreshInterval: HivePrefUtil.getInt('autoRefreshInterval') ?? 30,
      // 4 matches the mobile app's default (and the value its dialog marks as
      // 推荐); the TV app defaulted to 2, so the same profile behaved
      // differently on the two clients.
      maxConcurrentRefresh: HivePrefUtil.getInt('maxConcurrentRefresh') ?? 4,
      homeKeepAlive: HivePrefUtil.getBool('homeKeepAlive') ?? true,
    );
  }

  void updateSettings(RefreshConfigModel newModel) {
    state = newModel;
    _persist();
  }

  void _persist() {
    HivePrefUtil.setBool('autoRefreshFavorite', state.autoRefreshFavorite);
    HivePrefUtil.setInt('autoRefreshInterval', state.autoRefreshInterval);
    HivePrefUtil.setInt('maxConcurrentRefresh', state.maxConcurrentRefresh);
    HivePrefUtil.setBool('homeKeepAlive', state.homeKeepAlive);
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = RefreshConfigModel.fromJson(json);
    _persist();
  }
}
