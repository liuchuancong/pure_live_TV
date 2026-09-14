import 'package:pure_live/shared/models/live_room/live_room.dart';

/// 进入直播播放页的参数。
///
/// 兼容两种入口：
/// - 已持有 [LiveRoom]（收藏/热门/搜索卡片、链接解析）：直接带 detail 起播。
/// - 仅持有 roomId + platform：进页后通过 Sites 拉取房间详情。
///
/// [playlist] 是进入播放页时所在的房间列表，用于遥控器上下键切台与播放列表面板；
/// 为空时回退到「观看历史」作为换台列表。
class LivePlayArgs {
  final String platform;
  final String roomId;
  final LiveRoom? room;

  /// 进入播放页时所在的房间列表（换台用）。
  final List<LiveRoom> playlist;

  /// 本次进入是否由上下键切台触发（用于显示频道名提示条）。
  final bool showChannelBanner;

  const LivePlayArgs({
    required this.platform,
    required this.roomId,
    this.room,
    this.playlist = const <LiveRoom>[],
    this.showChannelBanner = false,
  });

  factory LivePlayArgs.fromRoom(
    LiveRoom room, {
    List<LiveRoom> playlist = const <LiveRoom>[],
    bool showChannelBanner = false,
  }) => LivePlayArgs(
    platform: room.normalizedPlatformId,
    roomId: room.normalizedRoomId,
    room: room,
    playlist: playlist,
    showChannelBanner: showChannelBanner,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is LivePlayArgs && other.platform == platform && other.roomId == roomId);

  @override
  int get hashCode => '$platform:$roomId'.hashCode;
}
