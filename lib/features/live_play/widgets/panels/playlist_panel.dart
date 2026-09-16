import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/widgets/panels/player_index_panel.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';

/// Playlist panel shown inside the player, as an index list.
///
/// See [LivePlayController.channelRooms] for the source: the rooms from the entry
/// page win, otherwise watch history is used. Up/Down walk the list, OK switches
/// channel (a route replace, so the previous session is released), and Left/Right
/// follow or unfollow, exactly like the reference's playlist panel.
class PlaylistPanel extends ConsumerStatefulWidget {
  const PlaylistPanel({super.key, required this.args});

  final LivePlayArgs args;

  @override
  ConsumerState<PlaylistPanel> createState() => _PlaylistPanelState();
}

class _PlaylistPanelState extends ConsumerState<PlaylistPanel> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livePlayControllerProvider(widget.args));
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    final List<LiveRoom> rooms = controller.channelRooms;
    final current = state.room;
    final favorites = ref.watch(favoriteRoomControllerProvider).favoriteRooms;
    final int index = rooms.isEmpty ? 0 : _index.clamp(0, rooms.length - 1);

    return PlayerIndexPanel(
      title: i18nOr('ui_playlist', 'Playlist'),
      rows: <PlayerPanelRow>[
        for (final LiveRoom room in rooms)
          PlayerPanelRow(
            label: room.title,
            subtitle: room.nick,
            active: current != null && room.hasSameIdentity(current),
            icon: favorites.any((item) => item.hasSameIdentity(room))
                ? Icons.favorite
                : Icons.play_circle_outline_rounded,
          ),
      ],
      selectedIndex: index,
      onSelectionChanged: (i) => setState(() => _index = i),
      emptyHint: i18n('ui_none'),
      onSelect: (i) => _openRoom(rooms[i], rooms),
      onAdjustLeft: (i) => _toggleFollow(rooms[i]),
      onAdjustRight: (i) => _toggleFollow(rooms[i]),
      onClose: controller.toggleSidePanel,
    );
  }

  void _openRoom(LiveRoom room, List<LiveRoom> rooms) {
    final current = ref.read(livePlayControllerProvider(widget.args)).room;
    if (current != null && room.hasSameIdentity(current)) return;
    context.replace(
      AppRoutes.kLivePlay,
      extra: LivePlayArgs.fromRoom(room, playlist: rooms, showChannelBanner: true),
    );
  }

  void _toggleFollow(LiveRoom room) {
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    if (fav.isFavorite(room)) {
      fav.removeRoom(room);
    } else {
      fav.addRoom(room);
    }
  }
}
