// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_part.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MusicPart _$MusicPartFromJson(Map<String, dynamic> json) => _MusicPart(
  cid: (json['cid'] as num?)?.toInt() ?? 0,
  page: (json['page'] as num?)?.toInt() ?? 1,
  title: json['title'] as String? ?? '',
  duration: (json['duration'] as num?)?.toInt() ?? 0,
  epId: (json['epId'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$MusicPartToJson(_MusicPart instance) =>
    <String, dynamic>{
      'cid': instance.cid,
      'page': instance.page,
      'title': instance.title,
      'duration': instance.duration,
      'epId': instance.epId,
    };
