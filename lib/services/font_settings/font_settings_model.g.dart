// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FontSettingsModel _$FontSettingsModelFromJson(Map<String, dynamic> json) =>
    _FontSettingsModel(
      textScaleFactor: (json['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
      fontFamilyName: json['fontFamilyName'] as String? ?? 'Default',
    );

Map<String, dynamic> _$FontSettingsModelToJson(_FontSettingsModel instance) =>
    <String, dynamic>{
      'textScaleFactor': instance.textScaleFactor,
      'fontFamilyName': instance.fontFamilyName,
    };
