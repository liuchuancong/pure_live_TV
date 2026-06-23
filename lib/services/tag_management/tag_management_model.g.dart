// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag_management_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TagManagementModel _$TagManagementModelFromJson(Map<String, dynamic> json) =>
    _TagManagementModel(
      tags:
          (json['tags'] as List<dynamic>?)
              ?.map((e) => LiveTag.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      roomTagsMap:
          (json['roomTagsMap'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(
              k,
              (e as List<dynamic>).map((e) => e as String).toList(),
            ),
          ) ??
          const {},
    );

Map<String, dynamic> _$TagManagementModelToJson(_TagManagementModel instance) =>
    <String, dynamic>{
      'tags': instance.tags,
      'roomTagsMap': instance.roomTagsMap,
    };
