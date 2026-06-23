// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cache_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CacheModel _$CacheModelFromJson(Map<String, dynamic> json) => _CacheModel(
  cacheSizeMB: (json['cacheSizeMB'] as num?)?.toDouble() ?? 0.0,
  refreshTurns: (json['refreshTurns'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$CacheModelToJson(_CacheModel instance) =>
    <String, dynamic>{
      'cacheSizeMB': instance.cacheSizeMB,
      'refreshTurns': instance.refreshTurns,
    };
