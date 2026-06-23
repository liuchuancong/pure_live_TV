// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_play_quality.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LivePlayQuality _$LivePlayQualityFromJson(Map<String, dynamic> json) =>
    _LivePlayQuality(
      quality: json['quality'] as String,
      data: json['data'],
      sort: (json['sort'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$LivePlayQualityToJson(_LivePlayQuality instance) =>
    <String, dynamic>{
      'quality': instance.quality,
      'data': instance.data,
      'sort': instance.sort,
    };
