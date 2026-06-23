// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'log_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LogSettingsModel _$LogSettingsModelFromJson(Map<String, dynamic> json) =>
    _LogSettingsModel(
      serverAddress: json['serverAddress'] as String? ?? '',
      serverPort: (json['serverPort'] as num?)?.toInt() ?? 7890,
      storedEnableLog: json['storedEnableLog'] as bool? ?? false,
    );

Map<String, dynamic> _$LogSettingsModelToJson(_LogSettingsModel instance) =>
    <String, dynamic>{
      'serverAddress': instance.serverAddress,
      'serverPort': instance.serverPort,
      'storedEnableLog': instance.storedEnableLog,
    };
