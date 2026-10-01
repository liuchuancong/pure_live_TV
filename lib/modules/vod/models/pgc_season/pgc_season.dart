import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/json_converters.dart';
import 'package:pure_live/modules/vod/models/pgc_episode/pgc_episode.dart';
import 'package:pure_live/modules/vod/models/pgc_item/pgc_item.dart';

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

    /// `user_status.follow` — the 追番 toggle's initial state.
    @JsonKey(fromJson: lenientIntOf) @Default(0) int follow,

    /// `new_ep.desc` — the "更新至第 X 话" line under the title.
    @Default('') String newEpDesc,

    /// `user_status.progress` — where the user last stopped watching.
    @JsonKey(name: 'lastEpId', fromJson: lenientIntOf) @Default(0) int lastEpId,
    @JsonKey(name: 'lastEpIndex') @Default('') String lastEpIndex,

    /// The `section[]` blocks (番外/PV/SP), empty ones already dropped.
    @Default([]) List<PgcSection> sections,

    /// `seasons[]` — the sibling seasons of the same series; the switcher
    /// chips only appear when this has more than the current season.
    @Default([]) List<PgcItem> altSeasons,
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
  'follow': json['user_status']?['follow'],
  'newEpDesc': json['new_ep']?['desc'],
  'lastEpId': json['user_status']?['progress']?['last_ep_id'],
  'lastEpIndex': json['user_status']?['progress']?['last_ep_index']?.toString() ?? '',
  'sections': [
    for (final s in (json['section'] as List?) ?? const <dynamic>[])
      if (s is Map && (s['episodes'] as List?)?.isNotEmpty == true) s,
  ],
  // Keep these as plain maps: `_$PgcSeasonFromJson` re-parses every element
  // through `PgcItem.fromJson`, so pre-building `PgcItem` objects here crashed
  // any season carrying sibling `seasons[]` ("type '_PgcItem' is not a subtype
  // of type 'Map<String, dynamic>' in type cast").
  'altSeasons': [
    for (final s in (json['seasons'] as List?) ?? const <dynamic>[])
      if (s is Map)
        <String, dynamic>{
          'season_id': s['season_id'],
          'title': s['season_title'] ?? s['title'],
          'cover': s['cover'],
        },
  ],
  'styles': [
    // ship name objects. Indexing a *string* element with 'name' crashed the
    // whole detail open ("type 'String' is not a subtype of type 'int' of
    // 'index'").
    for (final s in (json['styles'] as List?) ?? const <dynamic>[])
      s is Map ? s['name']?.toString() ?? '' : s.toString(),
  ].where((s) => s.isNotEmpty).toList(),
  'pubTime': json['publish']?['pub_time'],
};

/// One `section[]` block of a season — a titled group of bonus episodes
/// (番外/PV/预告) that the detail page renders under its own header.
@freezed
abstract class PgcSection with _$PgcSection {
  const factory PgcSection({
    @Default('') String title,
    @Default([]) List<PgcEpisode> episodes,
  }) = _PgcSection;

  factory PgcSection.fromJson(Map<String, dynamic> json) => _$PgcSectionFromJson(<String, dynamic>{
    'title': json['title']?.toString() ?? '',
    'episodes': json['episodes'],
  });
}
