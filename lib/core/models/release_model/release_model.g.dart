// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'release_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReleaseModel _$ReleaseModelFromJson(Map<String, dynamic> json) =>
    _ReleaseModel(
      version: json['version'] as String? ?? '',
      title: json['title'] as String? ?? '',
      date: json['date'] as String? ?? '',
      github: json['github'] as String? ?? '',
      author: AuthorModel.fromJson(json['author'] as Map<String, dynamic>),
      changeLog: json['changeLog'] as String? ?? '',
      files:
          (json['files'] as List<dynamic>?)
              ?.map((e) => ReleaseFileModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$ReleaseModelToJson(_ReleaseModel instance) =>
    <String, dynamic>{
      'version': instance.version,
      'title': instance.title,
      'date': instance.date,
      'github': instance.github,
      'author': instance.author,
      'changeLog': instance.changeLog,
      'files': instance.files,
    };

_AuthorModel _$AuthorModelFromJson(Map<String, dynamic> json) => _AuthorModel(
  name: json['name'] as String? ?? '',
  avatar: json['avatar'] as String? ?? '',
  profile: json['profile'] as String? ?? '',
);

Map<String, dynamic> _$AuthorModelToJson(_AuthorModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'avatar': instance.avatar,
      'profile': instance.profile,
    };

_ReleaseFileModel _$ReleaseFileModelFromJson(Map<String, dynamic> json) =>
    _ReleaseFileModel(
      name: json['name'] as String? ?? '',
      size: json['size'] as String? ?? '',
      downloads: (json['downloads'] as num?)?.toInt() ?? 0,
      url: json['url'] as String? ?? '',
    );

Map<String, dynamic> _$ReleaseFileModelToJson(_ReleaseFileModel instance) =>
    <String, dynamic>{
      'name': instance.name,
      'size': instance.size,
      'downloads': instance.downloads,
      'url': instance.url,
    };
