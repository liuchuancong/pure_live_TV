// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'player_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlayerSettingsModel _$PlayerSettingsModelFromJson(Map<String, dynamic> json) =>
    _PlayerSettingsModel(
      videoFitIndex: (json['videoFitIndex'] as num?)?.toInt() ?? 0,
      videoPlayerKey: json['videoPlayerKey'] as String? ?? 'mpv',
      preferResolution: json['preferResolution'] as String? ?? '',
      preferResolutionCellular:
          json['preferResolutionCellular'] as String? ?? '',
      enableCodec: json['enableCodec'] as bool? ?? true,
      playerCompatMode: json['playerCompatMode'] as bool? ?? false,
      customPlayerOutput: json['customPlayerOutput'] as bool? ?? false,
      videoOutputDriver: json['videoOutputDriver'] as String? ?? 'gpu',
      audioOutputDriver: json['audioOutputDriver'] as String? ?? 'auto',
      videoHardwareDecoder: json['videoHardwareDecoder'] as String? ?? 'auto',
      floatPlay: json['floatPlay'] as bool? ?? false,
      audioOnly: json['audioOnly'] as bool? ?? false,
      useHardStopOnExit: json['useHardStopOnExit'] as bool? ?? false,
    );

Map<String, dynamic> _$PlayerSettingsModelToJson(
  _PlayerSettingsModel instance,
) => <String, dynamic>{
  'videoFitIndex': instance.videoFitIndex,
  'videoPlayerKey': instance.videoPlayerKey,
  'preferResolution': instance.preferResolution,
  'preferResolutionCellular': instance.preferResolutionCellular,
  'enableCodec': instance.enableCodec,
  'playerCompatMode': instance.playerCompatMode,
  'customPlayerOutput': instance.customPlayerOutput,
  'videoOutputDriver': instance.videoOutputDriver,
  'audioOutputDriver': instance.audioOutputDriver,
  'videoHardwareDecoder': instance.videoHardwareDecoder,
  'floatPlay': instance.floatPlay,
  'audioOnly': instance.audioOnly,
  'useHardStopOnExit': instance.useHardStopOnExit,
};
