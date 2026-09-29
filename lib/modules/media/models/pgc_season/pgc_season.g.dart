// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pgc_season.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PgcSeason _$PgcSeasonFromJson(Map<String, dynamic> json) => _PgcSeason(
  seasonId: json['season_id'] == null ? 0 : lenientIntOf(json['season_id']),
  title: json['title'] as String? ?? '',
  cover: json['cover'] == null ? '' : httpsUrlOf(json['cover']),
  evaluate: json['evaluate'] as String? ?? '',
  episodes:
      (json['episodes'] as List<dynamic>?)
          ?.map((e) => PgcEpisode.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  badge: json['badge'] as String? ?? '',
  rating: json['rating'] == null ? 0 : lenientDoubleOf(json['rating']),
  styles:
      (json['styles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  pubTime: json['pubTime'] as String? ?? '',
);

Map<String, dynamic> _$PgcSeasonToJson(_PgcSeason instance) =>
    <String, dynamic>{
      'season_id': instance.seasonId,
      'title': instance.title,
      'cover': instance.cover,
      'evaluate': instance.evaluate,
      'episodes': instance.episodes,
      'badge': instance.badge,
      'rating': instance.rating,
      'styles': instance.styles,
      'pubTime': instance.pubTime,
    };
