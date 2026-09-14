import 'package:pure_live/shared/models/live_room/live_room.dart';

/// 进入直播播放页的参数。
///
/// 兼容两种入口：
/// - 已持有 [LiveRoom]（收藏/热门/搜索卡片、链接解析）：直接带 detail 起播。
/// - 仅持有 roomId + platform：进页后通过 Sites 拉取房间详情。
class LivePlayArgs {
  final String platform;
  final String roomId;
  final LiveRoom? room;

  const LivePlayArgs({required this.platform, required this.roomId, this.room});

  factory LivePlayArgs.fromRoom(LiveRoom room) =>
      LivePlayArgs(platform: room.normalizedPlatformId, roomId: room.normalizedRoomId, room: room);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LivePlayArgs && other.platform == platform && other.roomId == roomId);

  @override
  int get hashCode => '$platform:$roomId'.hashCode;
}
