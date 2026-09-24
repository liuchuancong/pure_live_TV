// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ThemeSettingsModel _$ThemeSettingsModelFromJson(Map<String, dynamic> json) =>
    _ThemeSettingsModel(
      themeModeName: json['themeModeName'] as String? ?? "System",
      themeColor: json['themeColor'] == null
          ? Colors.blue
          : const HexColorConverter().fromJson(json['themeColor'] as String),
      languageName: json['languageName'] as String? ?? "简体中文",
      crossAxisSpacing: (json['crossAxisSpacing'] as num?)?.toDouble() ?? 6.0,
      mainAxisSpacing: (json['mainAxisSpacing'] as num?)?.toDouble() ?? 6.0,
      spacingDirectV2: json['spacingDirectV2'] as bool? ?? false,
      loadingStyle: json['loadingStyle'] as String? ?? "default",
      loadingStyleColor: _$JsonConverterFromJson<String, Color>(
        json['loadingStyleColor'],
        const HexColorConverter().fromJson,
      ),
      denseRoomLayout: (json['denseRoomLayout'] as num?)?.toInt() ?? 4,
    );

Map<String, dynamic> _$ThemeSettingsModelToJson(_ThemeSettingsModel instance) =>
    <String, dynamic>{
      'themeModeName': instance.themeModeName,
      'themeColor': const HexColorConverter().toJson(instance.themeColor),
      'languageName': instance.languageName,
      'crossAxisSpacing': instance.crossAxisSpacing,
      'mainAxisSpacing': instance.mainAxisSpacing,
      'spacingDirectV2': instance.spacingDirectV2,
      'loadingStyle': instance.loadingStyle,
      'loadingStyleColor': _$JsonConverterToJson<String, Color>(
        instance.loadingStyleColor,
        const HexColorConverter().toJson,
      ),
      'denseRoomLayout': instance.denseRoomLayout,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);
