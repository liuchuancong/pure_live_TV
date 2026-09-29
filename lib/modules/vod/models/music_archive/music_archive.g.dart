// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_archive.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MusicArchive _$MusicArchiveFromJson(Map<String, dynamic> json) =>
    _MusicArchive(
      aid: (json['aid'] as num?)?.toInt() ?? 0,
      bvid: json['bvid'] as String? ?? '',
      title: json['title'] as String? ?? '',
      cover: json['cover'] as String? ?? '',
      upName: json['upName'] as String? ?? '',
      tid: (json['tid'] as num?)?.toInt() ?? 0,
      upMid: (json['upMid'] as num?)?.toInt() ?? 0,
      upFace: json['upFace'] as String? ?? '',
      duration: (json['duration'] as num?)?.toInt() ?? 0,
      playCount: (json['playCount'] as num?)?.toInt() ?? 0,
      barrageCount: (json['barrageCount'] as num?)?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      tname: json['tname'] as String? ?? '',
      publishDate: json['publishDate'] as String? ?? '',
      parts:
          (json['parts'] as List<dynamic>?)
              ?.map((e) => MusicPart.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MusicArchiveToJson(_MusicArchive instance) =>
    <String, dynamic>{
      'aid': instance.aid,
      'bvid': instance.bvid,
      'title': instance.title,
      'cover': instance.cover,
      'upName': instance.upName,
      'tid': instance.tid,
      'upMid': instance.upMid,
      'upFace': instance.upFace,
      'duration': instance.duration,
      'playCount': instance.playCount,
      'barrageCount': instance.barrageCount,
      'description': instance.description,
      'tname': instance.tname,
      'publishDate': instance.publishDate,
      'parts': instance.parts,
    };
