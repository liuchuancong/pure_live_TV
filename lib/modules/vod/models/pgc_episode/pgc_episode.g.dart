// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pgc_episode.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PgcEpisode _$PgcEpisodeFromJson(Map<String, dynamic> json) => _PgcEpisode(
  epId: json['id'] == null ? 0 : lenientIntOf(json['id']),
  cid: json['cid'] == null ? 0 : lenientIntOf(json['cid']),
  title: json['title'] as String? ?? '',
  longTitle: json['long_title'] as String? ?? '',
  cover: json['cover'] == null ? '' : httpsUrlOf(json['cover']),
  durationMs: json['duration'] == null ? 0 : lenientIntOf(json['duration']),
  badge: json['badge'] as String? ?? '',
);

Map<String, dynamic> _$PgcEpisodeToJson(_PgcEpisode instance) =>
    <String, dynamic>{
      'id': instance.epId,
      'cid': instance.cid,
      'title': instance.title,
      'long_title': instance.longTitle,
      'cover': instance.cover,
      'duration': instance.durationMs,
      'badge': instance.badge,
    };
