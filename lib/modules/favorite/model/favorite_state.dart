import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';
import 'package:pure_live/services/tag_management/live_tag.dart';

part 'favorite_state.freezed.dart';

@freezed
abstract class FavoriteState with _$FavoriteState {
  const factory FavoriteState({
    @Default(0) int tabSiteIndex,
    @Default(0) int tabOnlineIndex,
    @Default('all') String selectedTagId,
    @Default([]) List<LiveRoom> onlineRooms,
    @Default([]) List<LiveRoom> offlineRooms,
    @Default([]) List<LiveRoom> replayRooms,
    @Default([]) List<LiveTag> visibleTags,
    @Default(false) bool isLoading,
  }) = _FavoriteState;
}
