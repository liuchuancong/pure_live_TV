import 'package:pure_live/shared/models/live_room/live_room.dart';

/// Arguments for entering the live playback page.
///
/// Two entry shapes are supported:
/// - A [LiveRoom] is already available (favourites, popular, search cards or a
///   resolved link): playback starts from that detail.
/// - Only roomId and platform are known: the room is fetched through Sites
///   once the page opens.
///
/// [playlist] is the room list the player was opened from. It backs remote
/// up/down channel switching and the playlist panel;
/// when empty, watch history is used as the channel list instead.
class LivePlayArgs {
  final String platform;
  final String roomId;
  final LiveRoom? room;

  /// Room list the player was opened from, used for channel switching.
  final List<LiveRoom> playlist;

  /// Whether this entry came from an up/down channel switch, which shows the
  /// channel name toast.
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
