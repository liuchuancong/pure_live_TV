// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_pgc_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchPgcItem _$SearchPgcItemFromJson(Map<String, dynamic> json) =>
    _SearchPgcItem(
      seasonId: json['season_id'] == null ? 0 : lenientIntOf(json['season_id']),
      title: json['title'] == null ? '' : stripHtmlOf(json['title']),
      cover: json['cover'] == null ? '' : httpsUrlOf(json['cover']),
      episodeCount:
          (_readEpisodesCount(json, 'episodes') as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$SearchPgcItemToJson(_SearchPgcItem instance) =>
    <String, dynamic>{
      'season_id': instance.seasonId,
      'title': instance.title,
      'cover': instance.cover,
      'episodes': instance.episodeCount,
    };
