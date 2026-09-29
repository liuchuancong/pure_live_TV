// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pgc_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PgcItem _$PgcItemFromJson(Map<String, dynamic> json) => _PgcItem(
  seasonId: json['season_id'] == null ? 0 : lenientIntOf(json['season_id']),
  title: json['title'] == null ? '' : stripHtmlOf(json['title']),
  cover: json['cover'] == null ? '' : httpsUrlOf(json['cover']),
  subtitle: json['subtitle'] == null ? '' : stripHtmlOf(json['subtitle']),
  badge: json['badge'] as String? ?? '',
  rating: json['rating'] == null ? 0 : lenientDoubleOf(json['rating']),
  episodeCount: json['episodeCount'] == null
      ? 0
      : lenientIntOf(json['episodeCount']),
);

Map<String, dynamic> _$PgcItemToJson(_PgcItem instance) => <String, dynamic>{
  'season_id': instance.seasonId,
  'title': instance.title,
  'cover': instance.cover,
  'subtitle': instance.subtitle,
  'badge': instance.badge,
  'rating': instance.rating,
  'episodeCount': instance.episodeCount,
};
