import 'refresh_config_model.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/settings/settings_value.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'refresh_config_controller.g.dart';

@riverpod
class RefreshConfigController extends _$RefreshConfigController {
  static RefreshConfigController get to => SettingsService.to.refresh;

  /// 供后台任务等非 widget 代码读取「关注列表自动刷新」开关。
  SettingsValue<bool> get autoRefreshFavoriteValue =>
      SettingsValue(() => state.autoRefreshFavorite, (value) => updateSettings(state.copyWith(autoRefreshFavorite: value)));

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
