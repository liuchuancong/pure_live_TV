import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/media/models/json_converters.dart';
import 'package:pure_live/modules/media/models/pgc_episode/pgc_episode.dart';

part 'pgc_season.freezed.dart';
part 'pgc_season.g.dart';

/// The full season detail (`pgc/view/web/season`). The styles arrive as name
/// objects, the rating as `{score: …}` and the publish time inside `publish`,
/// so [fromJson] flattens those first.
@freezed
abstract class PgcSeason with _$PgcSeason {
  const factory PgcSeason({
    @JsonKey(name: 'season_id', fromJson: lenientIntOf) @Default(0) int seasonId,
    @Default('') String title,
    @JsonKey(name: 'cover', fromJson: httpsUrlOf) @Default('') String cover,
    @Default('') String evaluate,
    @Default([]) List<PgcEpisode> episodes,
    @Default('') String badge,
    @JsonKey(fromJson: lenientDoubleOf) @Default(0) double rating,
    @Default([]) List<String> styles,
    @Default('') String pubTime,
  }) = _PgcSeason;

  factory PgcSeason.fromJson(Map<String, dynamic> json) => _$PgcSeasonFromJson(_normalizePgcSeasonJson(json));
}

Map<String, dynamic> _normalizePgcSeasonJson(Map<String, dynamic> json) => <String, dynamic>{
  'season_id': json['season_id'],
  'title': json['title'],
  'cover': json['cover'],
  'evaluate': json['evaluate'],
  'episodes': json['episodes'],
  'badge': json['badge'],
  'rating': json['rating']?['score'],
  'styles': [
    for (final s in (json['styles'] as List?) ?? const <dynamic>[]) s['name']?.toString() ?? '',
  ].where((s) => s.isNotEmpty).toList(),
  'pubTime': json['publish']?['pub_time'],
};
