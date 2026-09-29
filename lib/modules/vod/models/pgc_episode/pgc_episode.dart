import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/json_converters.dart';

part 'pgc_episode.freezed.dart';
part 'pgc_episode.g.dart';

/// One episode of a season — the unit the player queue plays.
@freezed
abstract class PgcEpisode with _$PgcEpisode {
  const factory PgcEpisode({
    @JsonKey(name: 'id', fromJson: lenientIntOf) @Default(0) int epId,
    @JsonKey(fromJson: lenientIntOf) @Default(0) int cid,

    @Default('') String title,
    @JsonKey(name: 'long_title') @Default('') String longTitle,
    @JsonKey(name: 'cover', fromJson: httpsUrlOf) @Default('') String cover,
    @JsonKey(name: 'duration', fromJson: lenientIntOf) @Default(0) int durationMs,
    @Default('') String badge,
  }) = _PgcEpisode;

  factory PgcEpisode.fromJson(Map<String, dynamic> json) => _$PgcEpisodeFromJson(json);
}
