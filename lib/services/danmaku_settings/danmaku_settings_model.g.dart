// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'danmaku_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DanmakuSettingsModel _$DanmakuSettingsModelFromJson(
  Map<String, dynamic> json,
) => _DanmakuSettingsModel(
  hideDanmaku: json['hideDanmaku'] as bool? ?? false,
  noEmojiMode: json['noEmojiMode'] as bool? ?? false,
  danmakuTopArea: (json['danmakuTopArea'] as num?)?.toDouble() ?? 0.0,
  danmakuArea: (json['danmakuArea'] as num?)?.toDouble() ?? 1.0,
  danmakuBottomArea: (json['danmakuBottomArea'] as num?)?.toDouble() ?? 0.5,
  danmakuSpeed: (json['danmakuSpeed'] as num?)?.toDouble() ?? 8.0,
  danmakuFontSize: (json['danmakuFontSize'] as num?)?.toDouble() ?? 16.0,
  danmakuFontWeight: (json['danmakuFontWeight'] as num?)?.toInt() ?? 500,
  danmakuFontBorder: (json['danmakuFontBorder'] as num?)?.toDouble() ?? 4.0,
  danmakuOpacity: (json['danmakuOpacity'] as num?)?.toDouble() ?? 1.0,
  enableDanmakuDisplay: json['enableDanmakuDisplay'] as bool? ?? true,
  enableDanmakuStroke: json['enableDanmakuStroke'] as bool? ?? true,
  danmakuFps: (json['danmakuFps'] as num?)?.toInt() ?? 60,
  danmakuAutoFps: json['danmakuAutoFps'] as bool? ?? true,
  enableDanmakuTapInteraction:
      json['enableDanmakuTapInteraction'] as bool? ?? true,
  enableDanmakuLongPressInteraction:
      json['enableDanmakuLongPressInteraction'] as bool? ?? true,
  collapseRepeatedDanmaku: json['collapseRepeatedDanmaku'] as bool? ?? false,
  repeatedDanmakuWindowSeconds:
      (json['repeatedDanmakuWindowSeconds'] as num?)?.toInt() ?? 5,
  danmakuInteractionMigration:
      (json['danmakuInteractionMigration'] as num?)?.toInt() ?? 0,
  savedDanmakuTemplate: json['savedDanmakuTemplate'] as String? ?? '',
  danmakuFontFamilyName: json['danmakuFontFamilyName'] as String? ?? 'Default',
  enablePipDanmaku: json['enablePipDanmaku'] as bool? ?? true,
  pipDanmakuAutoScale: json['pipDanmakuAutoScale'] as bool? ?? true,
  pipDanmakuNoEmojiMode: json['pipDanmakuNoEmojiMode'] as bool? ?? false,
  pipDanmakuUseOriginalColor:
      json['pipDanmakuUseOriginalColor'] as bool? ?? true,
  pipDanmakuColor: (json['pipDanmakuColor'] as num?)?.toInt() ?? 0xFFFFFFFF,
  pipDanmakuFontSize: (json['pipDanmakuFontSize'] as num?)?.toDouble() ?? 12.0,
  pipDanmakuFontWeight: (json['pipDanmakuFontWeight'] as num?)?.toInt() ?? 500,
  pipDanmakuSpeed: (json['pipDanmakuSpeed'] as num?)?.toDouble() ?? 90.0,
  pipDanmakuOpacity: (json['pipDanmakuOpacity'] as num?)?.toDouble() ?? 0.9,
  pipDanmakuArea: (json['pipDanmakuArea'] as num?)?.toDouble() ?? 0.5,
  pipDanmakuMaxVisibleCount:
      (json['pipDanmakuMaxVisibleCount'] as num?)?.toInt() ?? 6,
  pipDanmakuEmitInterval:
      (json['pipDanmakuEmitInterval'] as num?)?.toDouble() ?? 0.35,
  pipDanmakuFps: (json['pipDanmakuFps'] as num?)?.toInt() ?? 30,
  pipDanmakuAutoFps: json['pipDanmakuAutoFps'] as bool? ?? true,
  filterDouyuSuspectedAutomatedMessages:
      json['filterDouyuSuspectedAutomatedMessages'] as bool? ?? true,
  enableDanmakuSimilarityFilter:
      json['enableDanmakuSimilarityFilter'] as bool? ?? false,
  danmakuSimilarityThreshold:
      (json['danmakuSimilarityThreshold'] as num?)?.toInt() ?? 85,
  danmakuSimilarityCacheDuration:
      (json['danmakuSimilarityCacheDuration'] as num?)?.toInt() ?? 3,
  danmakuSimilarityMaxCacheSize:
      (json['danmakuSimilarityMaxCacheSize'] as num?)?.toInt() ?? 100,
);

Map<String, dynamic> _$DanmakuSettingsModelToJson(
  _DanmakuSettingsModel instance,
) => <String, dynamic>{
  'hideDanmaku': instance.hideDanmaku,
  'noEmojiMode': instance.noEmojiMode,
  'danmakuTopArea': instance.danmakuTopArea,
  'danmakuArea': instance.danmakuArea,
  'danmakuBottomArea': instance.danmakuBottomArea,
  'danmakuSpeed': instance.danmakuSpeed,
  'danmakuFontSize': instance.danmakuFontSize,
  'danmakuFontWeight': instance.danmakuFontWeight,
  'danmakuFontBorder': instance.danmakuFontBorder,
  'danmakuOpacity': instance.danmakuOpacity,
  'enableDanmakuDisplay': instance.enableDanmakuDisplay,
  'enableDanmakuStroke': instance.enableDanmakuStroke,
  'danmakuFps': instance.danmakuFps,
  'danmakuAutoFps': instance.danmakuAutoFps,
  'enableDanmakuTapInteraction': instance.enableDanmakuTapInteraction,
  'enableDanmakuLongPressInteraction':
      instance.enableDanmakuLongPressInteraction,
  'collapseRepeatedDanmaku': instance.collapseRepeatedDanmaku,
  'repeatedDanmakuWindowSeconds': instance.repeatedDanmakuWindowSeconds,
  'danmakuInteractionMigration': instance.danmakuInteractionMigration,
  'savedDanmakuTemplate': instance.savedDanmakuTemplate,
  'danmakuFontFamilyName': instance.danmakuFontFamilyName,
  'enablePipDanmaku': instance.enablePipDanmaku,
  'pipDanmakuAutoScale': instance.pipDanmakuAutoScale,
  'pipDanmakuNoEmojiMode': instance.pipDanmakuNoEmojiMode,
  'pipDanmakuUseOriginalColor': instance.pipDanmakuUseOriginalColor,
  'pipDanmakuColor': instance.pipDanmakuColor,
  'pipDanmakuFontSize': instance.pipDanmakuFontSize,
  'pipDanmakuFontWeight': instance.pipDanmakuFontWeight,
  'pipDanmakuSpeed': instance.pipDanmakuSpeed,
  'pipDanmakuOpacity': instance.pipDanmakuOpacity,
  'pipDanmakuArea': instance.pipDanmakuArea,
  'pipDanmakuMaxVisibleCount': instance.pipDanmakuMaxVisibleCount,
  'pipDanmakuEmitInterval': instance.pipDanmakuEmitInterval,
  'pipDanmakuFps': instance.pipDanmakuFps,
  'pipDanmakuAutoFps': instance.pipDanmakuAutoFps,
  'filterDouyuSuspectedAutomatedMessages':
      instance.filterDouyuSuspectedAutomatedMessages,
  'enableDanmakuSimilarityFilter': instance.enableDanmakuSimilarityFilter,
  'danmakuSimilarityThreshold': instance.danmakuSimilarityThreshold,
  'danmakuSimilarityCacheDuration': instance.danmakuSimilarityCacheDuration,
  'danmakuSimilarityMaxCacheSize': instance.danmakuSimilarityMaxCacheSize,
};
