import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_room.freezed.dart';
part 'live_room.g.dart';

enum LiveStatus { live, offline, replay, unknown, banned }

@freezed
abstract class LiveRoom with _$LiveRoom {
  const LiveRoom._();

  const factory LiveRoom({
    @Default('') String roomId,
    @Default('') String userId,
    @Default('') String link,
    @Default('') String title,
    @Default('') String nick,
    @Default('') String avatar,
    @Default('') String cover,
    @Default('') String area,
    @Default('0') String watching,
    @Default('0') String followers,
    @Default('UNKNOWN') String platform,
    @Default([]) List<String> tagIds,
    @Default('') String introduction,
    @Default('') String notice,
    @Default(false) bool status,
    @Default(false) bool isRecord,
    @Default(LiveStatus.offline) LiveStatus liveStatus,
    @Default('') String epgId,
    @Default('') String currentProgramme,
    @Default('') String currentProgrammeDescription,
    String? catchUpUrl,
    @Default(false) bool isCatchUp,
    int? catchUpStart,
    int? catchUpEnd,
    @JsonKey(includeFromJson: false, includeToJson: false) dynamic data,
    @JsonKey(includeFromJson: false, includeToJson: false) dynamic danmakuData,
  }) = _LiveRoom;

  factory LiveRoom.fromJson(Map<String, dynamic> json) => _$LiveRoomFromJson(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _LiveRoom && other.runtimeType == runtimeType && other.platform == platform && other.roomId == roomId);

  @override
  int get hashCode => Object.hash(platform, roomId);
}
