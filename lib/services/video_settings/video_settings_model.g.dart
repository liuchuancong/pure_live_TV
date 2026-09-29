// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'video_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_VideoSettingsModel _$VideoSettingsModelFromJson(Map<String, dynamic> json) =>
    _VideoSettingsModel(
      preferredQuality: (json['preferredQuality'] as num?)?.toInt() ?? 0,
      defaultSpeed: (json['defaultSpeed'] as num?)?.toDouble() ?? 1.0,
      showVideoDetail: json['showVideoDetail'] as bool? ?? true,
      persistentProgress: json['persistentProgress'] as bool? ?? true,
      startSection: (json['startSection'] as num?)?.toInt() ?? 0,
      homeTabIndex: (json['homeTabIndex'] as num?)?.toInt() ?? 1,
      personalTabIndex: (json['personalTabIndex'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$VideoSettingsModelToJson(_VideoSettingsModel instance) =>
    <String, dynamic>{
      'preferredQuality': instance.preferredQuality,
      'defaultSpeed': instance.defaultSpeed,
      'showVideoDetail': instance.showVideoDetail,
      'persistentProgress': instance.persistentProgress,
      'startSection': instance.startSection,
      'homeTabIndex': instance.homeTabIndex,
      'personalTabIndex': instance.personalTabIndex,
    };
