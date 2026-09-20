// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'iptv_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_IptvSettingsModel _$IptvSettingsModelFromJson(Map<String, dynamic> json) =>
    _IptvSettingsModel(
      isAutoSyncEnabled: json['isAutoSyncEnabled'] as bool? ?? false,
      autoSyncHoursInterval:
          (json['autoSyncHoursInterval'] as num?)?.toInt() ?? 24,
      customIptvUserAgent: json['customIptvUserAgent'] as String? ?? '',
      customIptvReferer: json['customIptvReferer'] as String? ?? '',
      customIptvCookie: json['customIptvCookie'] as String? ?? '',
      m3uDirectory: json['m3uDirectory'] as String? ?? 'm3uDirectory',
      hotResourceUrl: json['hotResourceUrl'] as String? ?? '',
    );

Map<String, dynamic> _$IptvSettingsModelToJson(_IptvSettingsModel instance) =>
    <String, dynamic>{
      'isAutoSyncEnabled': instance.isAutoSyncEnabled,
      'autoSyncHoursInterval': instance.autoSyncHoursInterval,
      'customIptvUserAgent': instance.customIptvUserAgent,
      'customIptvReferer': instance.customIptvReferer,
      'customIptvCookie': instance.customIptvCookie,
      'm3uDirectory': instance.m3uDirectory,
      'hotResourceUrl': instance.hotResourceUrl,
    };
