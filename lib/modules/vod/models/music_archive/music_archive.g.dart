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
      likeCount: (json['likeCount'] as num?)?.toInt() ?? 0,
      coinCount: (json['coinCount'] as num?)?.toInt() ?? 0,
      favCount: (json['favCount'] as num?)?.toInt() ?? 0,
      replyCount: (json['replyCount'] as num?)?.toInt() ?? 0,
      parts:
          (json['parts'] as List<dynamic>?)
              ?.map((e) => MusicPart.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      season: json['season'] == null
          ? null
          : MusicSeason.fromJson(json['season'] as Map<String, dynamic>),
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
      'likeCount': instance.likeCount,
      'coinCount': instance.coinCount,
      'favCount': instance.favCount,
      'replyCount': instance.replyCount,
      'parts': instance.parts,
      'season': instance.season,
    };

_MusicSeason _$MusicSeasonFromJson(Map<String, dynamic> json) => _MusicSeason(
  id: (json['id'] as num?)?.toInt() ?? 0,
  title: json['title'] as String? ?? '',
  sections:
      (json['sections'] as List<dynamic>?)
          ?.map((e) => MusicSeasonSection.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$MusicSeasonToJson(_MusicSeason instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'sections': instance.sections,
    };

_MusicSeasonSection _$MusicSeasonSectionFromJson(Map<String, dynamic> json) =>
    _MusicSeasonSection(
      title: json['title'] as String? ?? '',
      episodes:
          (json['episodes'] as List<dynamic>?)
              ?.map((e) => MusicArchive.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );

Map<String, dynamic> _$MusicSeasonSectionToJson(_MusicSeasonSection instance) =>
    <String, dynamic>{'title': instance.title, 'episodes': instance.episodes};
