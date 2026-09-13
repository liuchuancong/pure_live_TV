import 'package:freezed_annotation/freezed_annotation.dart';

part 'danmaku_settings_model.freezed.dart';
part 'danmaku_settings_model.g.dart';

/// 与 pure_live 的弹幕设置字段全量对齐：
/// 画中画弹幕/交互/相似度过滤等字段在 TV 上无 UI 也不消费，
/// 但保留在模型中，使备份导出/导入与 pure_live 双向兼容。
@freezed
abstract class DanmakuSettingsModel with _$DanmakuSettingsModel {
  const factory DanmakuSettingsModel({
    @Default(false) bool hideDanmaku,
    @Default(false) bool noEmojiMode,
    @Default(0.0) double danmakuTopArea,
    @Default(1.0) double danmakuArea,
    @Default(0.5) double danmakuBottomArea,
    @Default(8.0) double danmakuSpeed,
    @Default(16.0) double danmakuFontSize,
    @Default(500) int danmakuFontWeight,
    @Default(4.0) double danmakuFontBorder,
    @Default(1.0) double danmakuOpacity,
    @Default(true) bool enableDanmakuDisplay,
    @Default(true) bool enableDanmakuStroke,
    @Default(60) int danmakuFps,
    @Default(true) bool danmakuAutoFps,
    @Default(true) bool enableDanmakuTapInteraction,
    @Default(true) bool enableDanmakuLongPressInteraction,
    @Default(false) bool collapseRepeatedDanmaku,
    @Default(5) int repeatedDanmakuWindowSeconds,
    @Default(0) int danmakuInteractionMigration,
    @Default('') String savedDanmakuTemplate,
    @Default('Default') String danmakuFontFamilyName,
    // 画中画弹幕（TV 不消费，仅同步保留）
    @Default(true) bool enablePipDanmaku,
    @Default(true) bool pipDanmakuAutoScale,
    @Default(false) bool pipDanmakuNoEmojiMode,
    @Default(true) bool pipDanmakuUseOriginalColor,
    @Default(0xFFFFFFFF) int pipDanmakuColor,
    @Default(12.0) double pipDanmakuFontSize,
    @Default(500) int pipDanmakuFontWeight,
    @Default(90.0) double pipDanmakuSpeed,
    @Default(0.9) double pipDanmakuOpacity,
    @Default(0.5) double pipDanmakuArea,
    @Default(6) int pipDanmakuMaxVisibleCount,
    @Default(0.35) double pipDanmakuEmitInterval,
    @Default(30) int pipDanmakuFps,
    @Default(true) bool pipDanmakuAutoFps,
    // 消息过滤
    @Default(true) bool filterDouyuSuspectedAutomatedMessages,
    @Default(false) bool enableDanmakuSimilarityFilter,
    @Default(85) int danmakuSimilarityThreshold,
    @Default(3) int danmakuSimilarityCacheDuration,
    @Default(100) int danmakuSimilarityMaxCacheSize,
  }) = _DanmakuSettingsModel;

  factory DanmakuSettingsModel.fromJson(Map<String, dynamic> json) => _$DanmakuSettingsModelFromJson(json);
}
