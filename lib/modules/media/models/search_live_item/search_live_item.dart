import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/media/models/json_converters.dart';

part 'search_live_item.freezed.dart';
part 'search_live_item.g.dart';

/// One search result of type `live`.
@freezed
abstract class SearchLiveItem with _$SearchLiveItem {
  const factory SearchLiveItem({
    @JsonKey(name: 'roomid', fromJson: lenientIntOf) @Default(0) int roomId,
    @JsonKey(fromJson: stripHtmlOf) @Default('') String title,

    /// A room row carries its own cover; a live-search row falls back to the
    /// uploader's.
    @JsonKey(name: 'cover', readValue: _readCoverOrUserCover, fromJson: httpsUrlOf) @Default('') String cover,
    @JsonKey(fromJson: stripHtmlOf) @Default('') String uname,
    @JsonKey(fromJson: lenientIntOf) @Default(0) int online,
    @JsonKey(name: 'live_status', fromJson: lenientIntOf) @Default(0) int liveStatus,
  }) = _SearchLiveItem;

  factory SearchLiveItem.fromJson(Map<String, dynamic> json) => _$SearchLiveItemFromJson(json);
}

dynamic _readCoverOrUserCover(Map<dynamic, dynamic> json, String key) => json['cover'] ?? json['user_cover'];
