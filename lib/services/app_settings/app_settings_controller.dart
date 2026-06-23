import 'app_settings_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_controller.g.dart';

@riverpod
class AppSettingsController extends _$AppSettingsController {
  static AppSettingsController get to => SettingsService.to.app;
  @override
  AppSettingsModel build() {
    return AppSettingsModel(
      autoRefreshTime: HivePrefUtil.getInt('autoRefreshTime') ?? 3,
      enableDenseFavorites: HivePrefUtil.getBool('enableDenseFavorites') ?? true,
      enableBackgroundPlay: HivePrefUtil.getBool('enableBackgroundPlay') ?? false,
      enableRotateScreen: HivePrefUtil.getBool('enableRotateScreen') ?? false,
      enableScreenKeepOn: HivePrefUtil.getBool('enableScreenKeepOn') ?? true,
      enableAutoCheckUpdate: HivePrefUtil.getBool('enableAutoCheckUpdate') ?? true,
      enableFullScreenDefault: HivePrefUtil.getBool('enableFullScreenDefault') ?? false,
      showSplashPage: HivePrefUtil.getBool('showSplashPage') ?? true,
      savedMenuIds: HivePrefUtil.getStringList('savedMenuIds') ?? [],
    );
  }

  void update(AppSettingsModel newModel) {
    state = newModel;
    _persist();
  }

  void toggleMenuVisibility(String menuId, bool visible) {
    final ids = List<String>.from(state.savedMenuIds);
    if (visible) {
      if (!ids.contains(menuId)) ids.add(menuId);
    } else {
      ids.remove(menuId);
    }
    update(state.copyWith(savedMenuIds: ids));
  }

  void _persist() {
    HivePrefUtil.setInt('autoRefreshTime', state.autoRefreshTime);
    HivePrefUtil.setBool('enableDenseFavorites', state.enableDenseFavorites);
    HivePrefUtil.setBool('enableBackgroundPlay', state.enableBackgroundPlay);
    HivePrefUtil.setBool('enableRotateScreen', state.enableRotateScreen);
    HivePrefUtil.setBool('enableScreenKeepOn', state.enableScreenKeepOn);
    HivePrefUtil.setBool('enableAutoCheckUpdate', state.enableAutoCheckUpdate);
    HivePrefUtil.setBool('enableFullScreenDefault', state.enableFullScreenDefault);
    HivePrefUtil.setBool('showSplashPage', state.showSplashPage);
    HivePrefUtil.setStringList('savedMenuIds', state.savedMenuIds);
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = AppSettingsModel.fromJson(json);
    _persist();
  }
}
