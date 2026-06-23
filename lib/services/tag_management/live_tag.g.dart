// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveTag _$LiveTagFromJson(Map<String, dynamic> json) => _LiveTag(
  id: json['id'] as String,
  name: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '',
  order: (json['order'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$LiveTagToJson(_LiveTag instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'order': instance.order,
};
