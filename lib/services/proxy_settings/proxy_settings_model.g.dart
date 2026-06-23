// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proxy_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ProxySettingsModel _$ProxySettingsModelFromJson(Map<String, dynamic> json) =>
    _ProxySettingsModel(
      enableProxy: json['enableProxy'] as bool? ?? false,
      proxyHost: json['proxyHost'] as String? ?? '',
      proxyPort: (json['proxyPort'] as num?)?.toInt() ?? 7897,
      enableAppProxy: json['enableAppProxy'] as bool? ?? false,
      appProxyHost: json['appProxyHost'] as String? ?? '',
      appProxyPort: (json['appProxyPort'] as num?)?.toInt() ?? 7897,
    );

Map<String, dynamic> _$ProxySettingsModelToJson(_ProxySettingsModel instance) =>
    <String, dynamic>{
      'enableProxy': instance.enableProxy,
      'proxyHost': instance.proxyHost,
      'proxyPort': instance.proxyPort,
      'enableAppProxy': instance.enableAppProxy,
      'appProxyHost': instance.appProxyHost,
      'appProxyPort': instance.appProxyPort,
    };
