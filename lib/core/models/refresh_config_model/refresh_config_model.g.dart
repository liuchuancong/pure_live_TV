// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RefreshConfig _$RefreshConfigFromJson(Map<String, dynamic> json) =>
    _RefreshConfig(
      autoRefreshFavorite: json['autoRefreshFavorite'] as bool? ?? true,
      autoRefreshInterval: (json['autoRefreshInterval'] as num?)?.toInt() ?? 60,
      maxConcurrentRefresh:
          (json['maxConcurrentRefresh'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$RefreshConfigToJson(_RefreshConfig instance) =>
    <String, dynamic>{
      'autoRefreshFavorite': instance.autoRefreshFavorite,
      'autoRefreshInterval': instance.autoRefreshInterval,
      'maxConcurrentRefresh': instance.maxConcurrentRefresh,
    };
