import 'theme_settings_model.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/consts/app_consts.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_settings_controller.g.dart';

@riverpod
class ThemeSettingsController extends _$ThemeSettingsController {
  static ThemeSettingsController get to => SettingsService.to.theme;
  @override
  ThemeSettingsModel build() {
    // 从 Hive 读取存储的完整 JSON 对象
    final savedJson = HivePrefUtil.getObject('theme_settings', (json) => json as Map<String, dynamic>);
    return savedJson != null ? ThemeSettingsModel.fromJson(savedJson) : const ThemeSettingsModel();
  }

  void updateSettings(ThemeSettingsModel newModel) {
    state = newModel;
    _persist();
  }

  void changeThemeMode(String mode) {
    state = state.copyWith(themeModeName: mode);
    _persist();
  }

  void changeThemeColor(Color color) {
    state = state.copyWith(themeColor: color);
    _persist();
  }

  void changeLanguage(String lang) {
    state = state.copyWith(languageName: lang);
    _persist();
  }

  void _persist() {
    HivePrefUtil.setObject('theme_settings', state.toJson());
  }

  // 获取辅助对象
  ThemeMode get themeMode => AppConsts.themeModes[state.themeModeName] ?? ThemeMode.system;
  Locale get locale => AppConsts.languages[state.languageName] ?? const Locale('zh', 'CN');

  // 备份与恢复
  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = ThemeSettingsModel.fromJson(json);
    _persist();
  }
}
