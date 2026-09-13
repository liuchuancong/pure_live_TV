// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CacheModel _$CacheModelFromJson(Map<String, dynamic> json) => _CacheModel(
  cacheSizeMB: (json['cacheSizeMB'] as num?)?.toDouble() ?? 0.0,
  refreshTurns: (json['refreshTurns'] as num?)?.toDouble() ?? 0.0,
  imageCacheEpoch: (json['imageCacheEpoch'] as num?)?.toInt() ?? 0,
  isScanning: json['isScanning'] as bool? ?? false,
  isClearing: json['isClearing'] as bool? ?? false,
  isRefreshingImages: json['isRefreshingImages'] as bool? ?? false,
);

Map<String, dynamic> _$CacheModelToJson(_CacheModel instance) =>
    <String, dynamic>{
      'cacheSizeMB': instance.cacheSizeMB,
      'refreshTurns': instance.refreshTurns,
      'imageCacheEpoch': instance.imageCacheEpoch,
      'isScanning': instance.isScanning,
      'isClearing': instance.isClearing,
      'isRefreshingImages': instance.isRefreshingImages,
    };
