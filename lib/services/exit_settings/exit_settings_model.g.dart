// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exit_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExitSettingsModel _$ExitSettingsModelFromJson(Map<String, dynamic> json) =>
    _ExitSettingsModel(
      dontAskExit: json['dontAskExit'] as bool? ?? false,
      exitChoose: json['exitChoose'] as String? ?? '',
      autoShutDownTime: (json['autoShutDownTime'] as num?)?.toInt() ?? 120,
      enableAutoShutDownTime: json['enableAutoShutDownTime'] as bool? ?? false,
    );

Map<String, dynamic> _$ExitSettingsModelToJson(_ExitSettingsModel instance) =>
    <String, dynamic>{
      'dontAskExit': instance.dontAskExit,
      'exitChoose': instance.exitChoose,
      'autoShutDownTime': instance.autoShutDownTime,
      'enableAutoShutDownTime': instance.enableAutoShutDownTime,
    };
