// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iptv_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IptvSettingsModel _$IptvSettingsModelFromJson(Map<String, dynamic> json) =>
    _IptvSettingsModel(
      selectedSourceName: json['selectedSourceName'] as String? ?? '',
      selectedSourceId: json['selectedSourceId'] as String? ?? '',
      isAutoSyncEnabled: json['isAutoSyncEnabled'] as bool? ?? false,
      autoSyncHoursInterval:
          (json['autoSyncHoursInterval'] as num?)?.toInt() ?? 24,
      customIptvUserAgent: json['customIptvUserAgent'] as String? ?? '',
      m3uDirectory: json['m3uDirectory'] as String? ?? 'm3uDirectory',
    );

Map<String, dynamic> _$IptvSettingsModelToJson(_IptvSettingsModel instance) =>
    <String, dynamic>{
      'selectedSourceName': instance.selectedSourceName,
      'selectedSourceId': instance.selectedSourceId,
      'isAutoSyncEnabled': instance.isAutoSyncEnabled,
      'autoSyncHoursInterval': instance.autoSyncHoursInterval,
      'customIptvUserAgent': instance.customIptvUserAgent,
      'm3uDirectory': instance.m3uDirectory,
    };
