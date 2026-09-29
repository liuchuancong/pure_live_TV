import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/core/models/live_anchor_item/live_anchor_item.dart';

part 'live_search_result.freezed.dart';
part 'live_search_result.g.dart';

@freezed
abstract class LiveSearchRoomResult with _$LiveSearchRoomResult {
  const factory LiveSearchRoomResult({@Default(false) bool hasMore, @Default([]) List<LiveRoom> items}) =
      _LiveSearchRoomResult;

  factory LiveSearchRoomResult.fromJson(Map<String, dynamic> json) => _$LiveSearchRoomResultFromJson(json);
}

@freezed
abstract class LiveSearchAnchorResult with _$LiveSearchAnchorResult {
  const factory LiveSearchAnchorResult({@Default(false) bool hasMore, @Default([]) List<LiveAnchorItem> items}) =
      _LiveSearchAnchorResult;

  factory LiveSearchAnchorResult.fromJson(Map<String, dynamic> json) => _$LiveSearchAnchorResultFromJson(json);
}
