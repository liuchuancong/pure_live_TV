// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_area.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveArea _$LiveAreaFromJson(Map<String, dynamic> json) => _LiveArea(
  platform: json['platform'] as String? ?? '',
  areaType: json['areaType'] as String? ?? '',
  typeName: json['typeName'] as String? ?? '',
  areaId: json['areaId'] as String? ?? '',
  areaName: json['areaName'] as String? ?? '',
  areaPic: json['areaPic'] as String? ?? '',
  shortName: json['shortName'] as String? ?? '',
);

Map<String, dynamic> _$LiveAreaToJson(_LiveArea instance) => <String, dynamic>{
  'platform': instance.platform,
  'areaType': instance.areaType,
  'typeName': instance.typeName,
  'areaId': instance.areaId,
  'areaName': instance.areaName,
  'areaPic': instance.areaPic,
  'shortName': instance.shortName,
};
