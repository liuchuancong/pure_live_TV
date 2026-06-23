import 'refresh_config_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
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
      maxConcurrentRefresh: HivePrefUtil.getInt('maxConcurrentRefresh') ?? 2,
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
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = RefreshConfigModel.fromJson(json);
    _persist();
  }
}
