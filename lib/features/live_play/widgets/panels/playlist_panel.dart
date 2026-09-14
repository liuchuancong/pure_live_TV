import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/widgets/panels/live_panel_shell.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 播放页内的播放列表（换台）面板。
///
/// 列表来源见 [LivePlayController.channelRooms]：优先使用入口页带来的当页房间，
/// 否则回退到观看历史。选中即切台，切换沿用路由 replace（与「切换直播间」一致），
/// 所以上一路播放会话会被正确释放。
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
      title: i18nOr('ui_playlist', '播放列表'),
      hint: i18nOr('ui_playlist_hint', '上下键选择频道，确认键切台'),
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
