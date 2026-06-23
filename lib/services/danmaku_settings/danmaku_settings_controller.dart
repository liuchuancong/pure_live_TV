import 'danmaku_settings_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'danmaku_settings_controller.g.dart';

@riverpod
class DanmakuSettingsController extends _$DanmakuSettingsController {
  static DanmakuSettingsController get to => SettingsService.to.danmaku;

  @override
  DanmakuSettingsModel build() {
    return DanmakuSettingsModel(
      hideDanmaku: HivePrefUtil.getBool('hideDanmaku') ?? false,
      danmakuTopArea: HivePrefUtil.getDouble('danmakuTopArea') ?? 0.0,
      danmakuArea: HivePrefUtil.getDouble('danmakuArea') ?? 1.0,
      danmakuBottomArea: HivePrefUtil.getDouble('danmakuBottomArea') ?? 0.5,
      danmakuSpeed: HivePrefUtil.getDouble('danmakuSpeed') ?? 8.0,
      danmakuFontSize: HivePrefUtil.getDouble('danmakuFontSize') ?? 16.0,
      danmakuFontBorder: HivePrefUtil.getDouble('danmakuFontBorder') ?? 4.0,
      danmakuOpacity: HivePrefUtil.getDouble('danmakuOpacity') ?? 1.0,
      enableDanmakuDisplay: HivePrefUtil.getBool('enableDanmakuDisplay') ?? true,
      enableDanmakuStroke: HivePrefUtil.getBool('enableDanmakuStroke') ?? true,
      danmakuFps: HivePrefUtil.getInt('danmakuFps') ?? 60,
      danmakuFontFamilyName: HivePrefUtil.getString('danmakuFontFamilyName') ?? 'Default',
    );
  }

  void updateSettings(DanmakuSettingsModel newSettings) {
    state = newSettings;
    _persist();
  }

  void _persist() {
    HivePrefUtil.setBool('hideDanmaku', state.hideDanmaku);
    HivePrefUtil.setDouble('danmakuTopArea', state.danmakuTopArea);
    HivePrefUtil.setDouble('danmakuArea', state.danmakuArea);
    HivePrefUtil.setDouble('danmakuBottomArea', state.danmakuBottomArea);
    HivePrefUtil.setDouble('danmakuSpeed', state.danmakuSpeed);
    HivePrefUtil.setDouble('danmakuFontSize', state.danmakuFontSize);
    HivePrefUtil.setDouble('danmakuFontBorder', state.danmakuFontBorder);
    HivePrefUtil.setDouble('danmakuOpacity', state.danmakuOpacity);
    HivePrefUtil.setBool('enableDanmakuDisplay', state.enableDanmakuDisplay);
    HivePrefUtil.setBool('enableDanmakuStroke', state.enableDanmakuStroke);
    HivePrefUtil.setInt('danmakuFps', state.danmakuFps);
    HivePrefUtil.setString('danmakuFontFamilyName', state.danmakuFontFamilyName);
  }

  void importFromJson(Map<String, dynamic> json) {
    state = DanmakuSettingsModel.fromJson(json);
    _persist();
  }

  Map<String, dynamic> toJson() => state.toJson();
}
