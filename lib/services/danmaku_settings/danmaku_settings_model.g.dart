// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'danmaku_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DanmakuSettingsModel _$DanmakuSettingsModelFromJson(
  Map<String, dynamic> json,
) => _DanmakuSettingsModel(
  hideDanmaku: json['hideDanmaku'] as bool? ?? false,
  danmakuTopArea: (json['danmakuTopArea'] as num?)?.toDouble() ?? 0.0,
  danmakuArea: (json['danmakuArea'] as num?)?.toDouble() ?? 1.0,
  danmakuBottomArea: (json['danmakuBottomArea'] as num?)?.toDouble() ?? 0.5,
  danmakuSpeed: (json['danmakuSpeed'] as num?)?.toDouble() ?? 8.0,
  danmakuFontSize: (json['danmakuFontSize'] as num?)?.toDouble() ?? 16.0,
  danmakuFontBorder: (json['danmakuFontBorder'] as num?)?.toDouble() ?? 4.0,
  danmakuOpacity: (json['danmakuOpacity'] as num?)?.toDouble() ?? 1.0,
  enableDanmakuDisplay: json['enableDanmakuDisplay'] as bool? ?? true,
  enableDanmakuStroke: json['enableDanmakuStroke'] as bool? ?? true,
  danmakuFps: (json['danmakuFps'] as num?)?.toInt() ?? 60,
  danmakuFontFamilyName: json['danmakuFontFamilyName'] as String? ?? 'Default',
);

Map<String, dynamic> _$DanmakuSettingsModelToJson(
  _DanmakuSettingsModel instance,
) => <String, dynamic>{
  'hideDanmaku': instance.hideDanmaku,
  'danmakuTopArea': instance.danmakuTopArea,
  'danmakuArea': instance.danmakuArea,
  'danmakuBottomArea': instance.danmakuBottomArea,
  'danmakuSpeed': instance.danmakuSpeed,
  'danmakuFontSize': instance.danmakuFontSize,
  'danmakuFontBorder': instance.danmakuFontBorder,
  'danmakuOpacity': instance.danmakuOpacity,
  'enableDanmakuDisplay': instance.enableDanmakuDisplay,
  'enableDanmakuStroke': instance.enableDanmakuStroke,
  'danmakuFps': instance.danmakuFps,
  'danmakuFontFamilyName': instance.danmakuFontFamilyName,
};
