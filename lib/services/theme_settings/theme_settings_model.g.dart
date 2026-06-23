// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ThemeSettingsModel _$ThemeSettingsModelFromJson(Map<String, dynamic> json) =>
    _ThemeSettingsModel(
      themeModeName: json['themeModeName'] as String? ?? "System",
      enableDynamicTheme: json['enableDynamicTheme'] as bool? ?? false,
      themeColor: json['themeColor'] == null
          ? Colors.blue
          : const HexColorConverter().fromJson(json['themeColor'] as String),
      languageName: json['languageName'] as String? ?? "简体中文",
      crossAxisSpacing: (json['crossAxisSpacing'] as num?)?.toDouble() ?? 6.0,
      mainAxisSpacing: (json['mainAxisSpacing'] as num?)?.toDouble() ?? 6.0,
      loadingStyle: json['loadingStyle'] as String? ?? "default",
      loadingStyleColor: _$JsonConverterFromJson<String, Color>(
        json['loadingStyleColor'],
        const HexColorConverter().fromJson,
      ),
    );

Map<String, dynamic> _$ThemeSettingsModelToJson(_ThemeSettingsModel instance) =>
    <String, dynamic>{
      'themeModeName': instance.themeModeName,
      'enableDynamicTheme': instance.enableDynamicTheme,
      'themeColor': const HexColorConverter().toJson(instance.themeColor),
      'languageName': instance.languageName,
      'crossAxisSpacing': instance.crossAxisSpacing,
      'mainAxisSpacing': instance.mainAxisSpacing,
      'loadingStyle': instance.loadingStyle,
      'loadingStyleColor': _$JsonConverterToJson<String, Color>(
        instance.loadingStyleColor,
        const HexColorConverter().toJson,
      ),
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
