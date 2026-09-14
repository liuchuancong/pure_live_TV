// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_task_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BackgroundTaskSettings _$BackgroundTaskSettingsFromJson(
  Map<String, dynamic> json,
) => _BackgroundTaskSettings(
  enabled: json['enabled'] as bool? ?? true,
  tasks: json['tasks'] == null
      ? const <BackgroundTaskConfig>[]
      : _taskConfigsFromJson(json['tasks']),
);

Map<String, dynamic> _$BackgroundTaskSettingsToJson(
  _BackgroundTaskSettings instance,
) => <String, dynamic>{
  'enabled': instance.enabled,
  'tasks': _taskConfigsToJson(instance.tasks),
};
