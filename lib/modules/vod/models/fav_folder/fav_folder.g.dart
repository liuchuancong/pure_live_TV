// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fav_folder.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FavFolder _$FavFolderFromJson(Map<String, dynamic> json) => _FavFolder(
  id: (json['id'] as num?)?.toInt() ?? 0,
  title: json['title'] as String? ?? '',
  mediaCount: (json['mediaCount'] as num?)?.toInt() ?? 0,
  cover: json['cover'] as String? ?? '',
  isPublic: json['isPublic'] as bool? ?? true,
);

Map<String, dynamic> _$FavFolderToJson(_FavFolder instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'mediaCount': instance.mediaCount,
      'cover': instance.cover,
      'isPublic': instance.isPublic,
    };
