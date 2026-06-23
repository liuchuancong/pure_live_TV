// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FontSettingsModel _$FontSettingsModelFromJson(
  Map<String, dynamic> json,
) => _FontSettingsModel(
  textScaleFactor: (json['textScaleFactor'] as num?)?.toDouble() ?? 1.0,
  fontSizeBodySmall: (json['fontSizeBodySmall'] as num?)?.toDouble() ?? 12.0,
  fontSizeBodyMedium: (json['fontSizeBodyMedium'] as num?)?.toDouble() ?? 13.0,
  fontSizeBodyLarge: (json['fontSizeBodyLarge'] as num?)?.toDouble() ?? 14.0,
  fontSizeTitleMedium:
      (json['fontSizeTitleMedium'] as num?)?.toDouble() ?? 15.0,
  fontSizeTitleLarge: (json['fontSizeTitleLarge'] as num?)?.toDouble() ?? 20.0,
  fontFamilyName: json['fontFamilyName'] as String? ?? 'Default',
);

Map<String, dynamic> _$FontSettingsModelToJson(_FontSettingsModel instance) =>
    <String, dynamic>{
      'textScaleFactor': instance.textScaleFactor,
      'fontSizeBodySmall': instance.fontSizeBodySmall,
      'fontSizeBodyMedium': instance.fontSizeBodyMedium,
      'fontSizeBodyLarge': instance.fontSizeBodyLarge,
      'fontSizeTitleMedium': instance.fontSizeTitleMedium,
      'fontSizeTitleLarge': instance.fontSizeTitleLarge,
      'fontFamilyName': instance.fontFamilyName,
    };
