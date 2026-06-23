// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'refresh_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RefreshConfigModel _$RefreshConfigModelFromJson(Map<String, dynamic> json) =>
    _RefreshConfigModel(
      autoRefreshFavorite: json['autoRefreshFavorite'] as bool? ?? false,
      autoRefreshInterval: (json['autoRefreshInterval'] as num?)?.toInt() ?? 30,
      maxConcurrentRefresh:
          (json['maxConcurrentRefresh'] as num?)?.toInt() ?? 2,
    );

Map<String, dynamic> _$RefreshConfigModelToJson(_RefreshConfigModel instance) =>
    <String, dynamic>{
      'autoRefreshFavorite': instance.autoRefreshFavorite,
      'autoRefreshInterval': instance.autoRefreshInterval,
      'maxConcurrentRefresh': instance.maxConcurrentRefresh,
    };
