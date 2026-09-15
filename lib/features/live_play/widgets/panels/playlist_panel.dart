import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/widgets/panels/live_panel_shell.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Playlist panel shown inside the player, used for channel switching.
///
/// See [LivePlayController.channelRooms] for the source: the rooms from the
/// entry page win, otherwise watch history is used. Selecting switches channel
/// through a route replace, the same path as the room switcher,
/// so the previous playback session is released properly.
class PlaylistPanel extends ConsumerWidget {
  const PlaylistPanel({super.key, required this.args});

  final LivePlayArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(livePlayControllerProvider(args));
    final controller = ref.read(livePlayControllerProvider(args).notifier);
    final tvTheme = context.tvTheme;
    final rooms = controller.channelRooms;
    final current = state.room;

    return LivePanelShell(
      title: i18nOr('ui_playlist', 'Playlist'),
      hint: i18nOr('ui_playlist_hint', 'Up/Down to pick a channel, OK to switch'),
      child: rooms.isEmpty
          ? Center(
              child: Text(
                i18n('ui_none'),
                style: AppTextStyles.t16W500.copyWith(color: tvTheme.secondaryTextColor),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(vertical: 8.sp),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                final isCurrent = current != null && room.hasSameIdentity(current);
                return LiveActionRow(
                  autofocus: isCurrent || (index == 0 && current == null),
                  highlighted: isCurrent,
                  title: room.title,
                  subtitle: room.nick,
                  leading: TvCommonAvatar(avatarUrl: room.avatar, fallbackName: room.nick, radius: 18.sp),
                  trailing: isCurrent
                      ? Icon(Icons.play_arrow_rounded, size: 22.sp, color: tvTheme.focusColor)
                      : null,
                  onSelect: () => _openRoom(context, room, rooms, isCurrent),
                );
              },
            ),
    );
  }

  void _openRoom(BuildContext context, LiveRoom room, List<LiveRoom> rooms, bool isCurrent) {
    if (isCurrent) return;
    context.replace(
      AppRoutes.kLivePlay,
      extra: LivePlayArgs.fromRoom(room, playlist: rooms, showChannelBanner: true),
    );
  }
}
