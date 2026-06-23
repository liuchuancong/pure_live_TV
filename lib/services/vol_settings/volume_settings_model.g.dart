// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'volume_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VolumeSettingsModel _$VolumeSettingsModelFromJson(Map<String, dynamic> json) =>
    _VolumeSettingsModel(
      defaultMobileVolume:
          (json['defaultMobileVolume'] as num?)?.toDouble() ?? 0.5,
      defaultDesktopVolume:
          (json['defaultDesktopVolume'] as num?)?.toDouble() ?? 1.0,
      globalVolumeMute: json['globalVolumeMute'] as bool? ?? false,
      roomVolumes:
          (json['roomVolumes'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
    );

Map<String, dynamic> _$VolumeSettingsModelToJson(
  _VolumeSettingsModel instance,
) => <String, dynamic>{
  'defaultMobileVolume': instance.defaultMobileVolume,
  'defaultDesktopVolume': instance.defaultDesktopVolume,
  'globalVolumeMute': instance.globalVolumeMute,
  'roomVolumes': instance.roomVolumes,
};
