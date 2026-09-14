import 'danmaku_settings_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/settings/settings_value.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'danmaku_settings_controller.g.dart';

@riverpod
class DanmakuSettingsController extends _$DanmakuSettingsController {
  static DanmakuSettingsController get to => SettingsService.to.danmaku;

  // 供播放器核心等非 widget 代码反应式读取。
  SettingsValue<bool> get filterDouyuSuspectedAutomatedMessages =>
      SettingsValue(() => state.filterDouyuSuspectedAutomatedMessages);

  @override
  DanmakuSettingsModel build() {
    return DanmakuSettingsModel(
      hideDanmaku: HivePrefUtil.getBool('hideDanmaku') ?? false,
      noEmojiMode: HivePrefUtil.getBool('noEmojiMode') ?? false,
      danmakuTopArea: HivePrefUtil.getDouble('danmakuTopArea') ?? 0.0,
      danmakuArea: HivePrefUtil.getDouble('danmakuArea') ?? 1.0,
      danmakuBottomArea: HivePrefUtil.getDouble('danmakuBottomArea') ?? 0.5,
      danmakuSpeed: HivePrefUtil.getDouble('danmakuSpeed') ?? 8.0,
      danmakuFontSize: HivePrefUtil.getDouble('danmakuFontSize') ?? 16.0,
      danmakuFontWeight: HivePrefUtil.getInt('danmakuFontWeight') ?? 500,
      danmakuFontBorder: HivePrefUtil.getDouble('danmakuFontBorder') ?? 4.0,
      danmakuOpacity: HivePrefUtil.getDouble('danmakuOpacity') ?? 1.0,
      enableDanmakuDisplay: HivePrefUtil.getBool('enableDanmakuDisplay') ?? true,
      enableDanmakuStroke: HivePrefUtil.getBool('enableDanmakuStroke') ?? true,
      danmakuFps: HivePrefUtil.getInt('danmakuFps') ?? 60,
      danmakuAutoFps: HivePrefUtil.getBool('danmakuAutoFps') ?? true,
      enableDanmakuTapInteraction: HivePrefUtil.getBool('enableDanmakuTapInteraction') ?? true,
      enableDanmakuLongPressInteraction: HivePrefUtil.getBool('enableDanmakuLongPressInteraction') ?? true,
      collapseRepeatedDanmaku: HivePrefUtil.getBool('collapseRepeatedDanmaku') ?? false,
      repeatedDanmakuWindowSeconds: HivePrefUtil.getInt('repeatedDanmakuWindowSeconds') ?? 5,
      danmakuInteractionMigration: HivePrefUtil.getInt('danmakuInteractionMigration') ?? 0,
      savedDanmakuTemplate: HivePrefUtil.getString('savedDanmakuTemplate') ?? '',
      danmakuFontFamilyName: HivePrefUtil.getString('danmakuFontFamilyName') ?? 'Default',
      enablePipDanmaku: HivePrefUtil.getBool('enablePipDanmaku') ?? true,
      pipDanmakuAutoScale: HivePrefUtil.getBool('pipDanmakuAutoScale') ?? true,
      pipDanmakuNoEmojiMode: HivePrefUtil.getBool('pipDanmaNoEmojiMode') ?? false,
      pipDanmakuUseOriginalColor: HivePrefUtil.getBool('pipDanmakuUseOriginalColor') ?? true,
      pipDanmakuColor: HivePrefUtil.getInt('pipDanmakuColor') ?? 0xFFFFFFFF,
      pipDanmakuFontSize: HivePrefUtil.getDouble('pipDanmakuFontSize') ?? 12.0,
      pipDanmakuFontWeight: HivePrefUtil.getInt('pipDanmakuFontWeight') ?? 500,
      pipDanmakuSpeed: HivePrefUtil.getDouble('pipDanmakuSpeed') ?? 90.0,
      pipDanmakuOpacity: HivePrefUtil.getDouble('pipDanmakuOpacity') ?? 0.9,
      pipDanmakuArea: HivePrefUtil.getDouble('pipDanmakuArea') ?? 0.5,
      pipDanmakuMaxVisibleCount: HivePrefUtil.getInt('pipDanmakuMaxVisibleCount') ?? 6,
      pipDanmakuEmitInterval: HivePrefUtil.getDouble('pipDanmakuEmitInterval') ?? 0.35,
      pipDanmakuFps: HivePrefUtil.getInt('pipDanmakuFps') ?? 30,
      pipDanmakuAutoFps: HivePrefUtil.getBool('pipDanmakuAutoFps') ?? true,
      filterDouyuSuspectedAutomatedMessages: HivePrefUtil.getBool('filterDouyuSuspectedAutomatedMessages') ?? true,
      enableDanmakuSimilarityFilter: HivePrefUtil.getBool('enableDanmakuSimilarityFilter') ?? false,
      danmakuSimilarityThreshold: HivePrefUtil.getInt('danmakuSimilarityThreshold') ?? 85,
      danmakuSimilarityCacheDuration: HivePrefUtil.getInt('danmakuSimilarityCacheDuration') ?? 3,
      danmakuSimilarityMaxCacheSize: HivePrefUtil.getInt('danmakuSimilarityMaxCacheSize') ?? 100,
    );
  }

  void updateSettings(DanmakuSettingsModel newSettings) {
    state = newSettings;
    _persist();
  }

  void _persist() {
    HivePrefUtil.setBool('hideDanmaku', state.hideDanmaku);
    HivePrefUtil.setBool('noEmojiMode', state.noEmojiMode);
    HivePrefUtil.setDouble('danmakuTopArea', state.danmakuTopArea);
    HivePrefUtil.setDouble('danmakuArea', state.danmakuArea);
    HivePrefUtil.setDouble('danmakuBottomArea', state.danmakuBottomArea);
    HivePrefUtil.setDouble('danmakuSpeed', state.danmakuSpeed);
    HivePrefUtil.setDouble('danmakuFontSize', state.danmakuFontSize);
    HivePrefUtil.setInt('danmakuFontWeight', state.danmakuFontWeight);
    HivePrefUtil.setDouble('danmakuFontBorder', state.danmakuFontBorder);
    HivePrefUtil.setDouble('danmakuOpacity', state.danmakuOpacity);
    HivePrefUtil.setBool('enableDanmakuDisplay', state.enableDanmakuDisplay);
    HivePrefUtil.setBool('enableDanmakuStroke', state.enableDanmakuStroke);
    HivePrefUtil.setInt('danmakuFps', state.danmakuFps);
    HivePrefUtil.setBool('danmakuAutoFps', state.danmakuAutoFps);
    HivePrefUtil.setBool('enableDanmakuTapInteraction', state.enableDanmakuTapInteraction);
    HivePrefUtil.setBool('enableDanmakuLongPressInteraction', state.enableDanmakuLongPressInteraction);
    HivePrefUtil.setBool('collapseRepeatedDanmaku', state.collapseRepeatedDanmaku);
    HivePrefUtil.setInt('repeatedDanmakuWindowSeconds', state.repeatedDanmakuWindowSeconds);
    HivePrefUtil.setInt('danmakuInteractionMigration', state.danmakuInteractionMigration);
    HivePrefUtil.setString('savedDanmakuTemplate', state.savedDanmakuTemplate);
    HivePrefUtil.setString('danmakuFontFamilyName', state.danmakuFontFamilyName);
    HivePrefUtil.setBool('enablePipDanmaku', state.enablePipDanmaku);
    HivePrefUtil.setBool('pipDanmakuAutoScale', state.pipDanmakuAutoScale);
    HivePrefUtil.setBool('pipDanmaNoEmojiMode', state.pipDanmakuNoEmojiMode);
    HivePrefUtil.setBool('pipDanmakuUseOriginalColor', state.pipDanmakuUseOriginalColor);
    HivePrefUtil.setInt('pipDanmakuColor', state.pipDanmakuColor);
    HivePrefUtil.setDouble('pipDanmakuFontSize', state.pipDanmakuFontSize);
    HivePrefUtil.setInt('pipDanmakuFontWeight', state.pipDanmakuFontWeight);
    HivePrefUtil.setDouble('pipDanmakuSpeed', state.pipDanmakuSpeed);
    HivePrefUtil.setDouble('pipDanmakuOpacity', state.pipDanmakuOpacity);
    HivePrefUtil.setDouble('pipDanmakuArea', state.pipDanmakuArea);
    HivePrefUtil.setInt('pipDanmakuMaxVisibleCount', state.pipDanmakuMaxVisibleCount);
    HivePrefUtil.setDouble('pipDanmakuEmitInterval', state.pipDanmakuEmitInterval);
    HivePrefUtil.setInt('pipDanmakuFps', state.pipDanmakuFps);
    HivePrefUtil.setBool('pipDanmakuAutoFps', state.pipDanmakuAutoFps);
    HivePrefUtil.setBool('filterDouyuSuspectedAutomatedMessages', state.filterDouyuSuspectedAutomatedMessages);
    HivePrefUtil.setBool('enableDanmakuSimilarityFilter', state.enableDanmakuSimilarityFilter);
    HivePrefUtil.setInt('danmakuSimilarityThreshold', state.danmakuSimilarityThreshold);
    HivePrefUtil.setInt('danmakuSimilarityCacheDuration', state.danmakuSimilarityCacheDuration);
    HivePrefUtil.setInt('danmakuSimilarityMaxCacheSize', state.danmakuSimilarityMaxCacheSize);
  }

  void importFromJson(Map<String, dynamic> json) {
    state = DanmakuSettingsModel.fromJson(json);
    _persist();
  }

  Map<String, dynamic> toJson() => state.toJson();
}
