// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_category.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveCategory _$LiveCategoryFromJson(Map<String, dynamic> json) =>
    _LiveCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      children:
          (json['children'] as List<dynamic>?)
              ?.map((e) => LiveArea.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$LiveCategoryToJson(_LiveCategory instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'children': instance.children,
    };
