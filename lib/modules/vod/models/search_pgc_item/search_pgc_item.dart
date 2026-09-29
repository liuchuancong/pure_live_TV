import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/json_converters.dart';

part 'search_pgc_item.freezed.dart';
part 'search_pgc_item.g.dart';

/// One search result of type `movie` (a PGC season): the episode count rides
/// along as the `episodes` list's length.
@freezed
abstract class SearchPgcItem with _$SearchPgcItem {
  const factory SearchPgcItem({
    @JsonKey(name: 'season_id', fromJson: lenientIntOf) @Default(0) int seasonId,
    @JsonKey(fromJson: stripHtmlOf) @Default('') String title,
    @JsonKey(fromJson: httpsUrlOf) @Default('') String cover,
    @JsonKey(name: 'episodes', readValue: _readEpisodesCount) @Default(0) int episodeCount,
  }) = _SearchPgcItem;

  factory SearchPgcItem.fromJson(Map<String, dynamic> json) => _$SearchPgcItemFromJson(json);
}

dynamic _readEpisodesCount(Map<dynamic, dynamic> json, String key) => (json['episodes'] as List?)?.length ?? 0;
