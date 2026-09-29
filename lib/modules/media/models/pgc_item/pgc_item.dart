import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/media/models/json_converters.dart';

part 'pgc_item.freezed.dart';
part 'pgc_item.g.dart';

/// One PGC card as the grids show it (feed / index / search result). The web
/// answers wobble between shapes — `subtitle` vs `sub_title`, `total` as a
/// map vs `total_count` — so [fromJson] normalizes first, then codegen reads
/// the canonical keys with the lenient converters.
@freezed
abstract class PgcItem with _$PgcItem {
  const factory PgcItem({
    @JsonKey(name: 'season_id', fromJson: lenientIntOf) @Default(0) int seasonId,
    @JsonKey(fromJson: stripHtmlOf) @Default('') String title,
    @JsonKey(name: 'cover', fromJson: httpsUrlOf) @Default('') String cover,
    @JsonKey(fromJson: stripHtmlOf) @Default('') String subtitle,
    @Default('') String badge,
    @JsonKey(fromJson: lenientDoubleOf) @Default(0) double rating,
    @JsonKey(fromJson: lenientIntOf) @Default(0) int episodeCount,
  }) = _PgcItem;

  factory PgcItem.fromJson(Map<String, dynamic> json) => _$PgcItemFromJson(_normalizePgcItemJson(json));
}

Map<String, dynamic> _normalizePgcItemJson(Map<String, dynamic> json) => <String, dynamic>{
  'season_id': json['season_id'],
  'title': json['title'],
  'cover': json['cover'],
  'subtitle': json['subtitle'] ?? json['sub_title'],
  'badge': json['badge'],
  'rating': json['rating'],
  'episodeCount': json['total'] is Map ? json['total']['value'] : json['total_count'],
};
