import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/features/live_play/dialogs/room_switch_dialog.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';

/// "This room is not broadcasting" placeholder.
///
/// Ported from the reference client's `NotLivingVideoWidget`: the room loaded
/// fine, so this is not an error screen — nothing failed, there is simply no
/// stream yet. It therefore offers the two things that actually help:
///
/// - **切换直播间**: the same switch dialog the control bar opens, so the viewer
///   can move on without backing out to the list first.
/// - **重新检测**: re-runs the room bootstrap (site response included), which is
///   what clears the placeholder once the streamer is back.
///
/// Remote interaction is plain D-pad: two focusable buttons, right/left between
/// them, OK to activate. Nothing here touches the page's own focus tree — the
/// page keeps handling the rest of the keys.
class NotLivingVideoWidget extends ConsumerWidget {
  const NotLivingVideoWidget({super.key, required this.args});

  final LivePlayArgs args;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final LivePlayState state = ref.watch(livePlayControllerProvider(args));
    final LivePlayController controller = ref.read(livePlayControllerProvider(args).notifier);
    final TvThemeData tvTheme = context.tvTheme;
    final LiveRoom? room = state.room;
    final String title = _roomTitle(context, room);

    return Container(
      color: Colors.black.withValues(alpha: 0.86),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 主播头像旁边放一个"离线"图标，比单纯文字更快传达状态。
          _OfflineBadge(room: room, title: title),
          SizedBox(height: 18.sp),
          Text(
            i18n('room_offline'),
            textAlign: TextAlign.center,
            style: AppTextStyles.t24W600.copyWith(color: tvTheme.primaryTextColor),
          ),
          SizedBox(height: 8.sp),
          SizedBox(
            width: 640.sp,
            child: Text(
              i18n('switch_other_room_hint'),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.t18W300.copyWith(color: tvTheme.secondaryTextColor),
            ),
          ),
          SizedBox(height: 26.sp),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DpadFocusable(
                autofocus: true,
                effects: [
                  DpadScaleEffect(scale: 1.05),
                  DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.5)),
                ],
                onSelect: () => unawaited(
                  pickAndSwitchRoom(context, ref: ref, args: args, current: room ?? _fallbackRoom()),
                ),
                child: _pill(tvTheme.focusColor, i18n('switch_live_room'), Icons.swap_horiz_rounded),
              ),
              SizedBox(width: 16.sp),
              DpadFocusable(
                effects: [
                  DpadScaleEffect(scale: 1.05),
                  DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.5)),
                ],
                onSelect: () => unawaited(controller.refreshRoom()),
                child: _pill(Colors.white.withValues(alpha: 0.12), i18n('ui_refresh_room'), Icons.refresh_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Room the switch dialog removes from its lists. When the detail request
  /// never produced a room, the route's hint is all we have — an empty room
  /// still opens the dialog with every other channel available.
  LiveRoom _fallbackRoom() => args.room ?? LiveRoom(roomId: args.roomId, platform: args.platform);

  /// Title line: room title, else streamer, else room id — never blank.
  static String _roomTitle(BuildContext context, LiveRoom? room) {
    for (final candidate in <String>[room?.title ?? '', room?.nick ?? '', room?.roomId ?? '']) {
      final String value = candidate.trim();
      if (value.isNotEmpty) return value;
    }
    return i18n('untitled_room');
  }

  Widget _pill(Color background, String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22.sp, vertical: 12.sp),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12.sp)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20.sp, color: Colors.white),
          SizedBox(width: 8.sp),
          Text(label, style: AppTextStyles.t16W600.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}

/// Avatar (or a neutral disc) with an offline marker, plus the room title.
class _OfflineBadge extends StatelessWidget {
  const _OfflineBadge({required this.room, required this.title});

  final LiveRoom? room;
  final String title;

  @override
  Widget build(BuildContext context) {
    final TvThemeData tvTheme = context.tvTheme;
    final String avatar = (room?.avatar ?? '').trim();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            ClipOval(
              child: SizedBox(
                width: 72.sp,
                height: 72.sp,
                child: avatar.isEmpty
                    ? ColoredBox(
                        color: tvTheme.cardColor,
                        child: Icon(Icons.person_outline_rounded, size: 36.sp, color: tvTheme.secondaryTextColor),
                      )
                    : CachedNetworkImage(
                        imageUrl: avatar,
                        fit: BoxFit.cover,
                        errorWidget: (context, _, _) => ColoredBox(
                          color: tvTheme.cardColor,
                          child: Icon(Icons.person_outline_rounded, size: 36.sp, color: tvTheme.secondaryTextColor),
                        ),
                      ),
              ),
            ),
            // 右下角离线标记：一眼看出"人不在播"，而不是网络故障。
            Positioned(
              right: -2.sp,
              bottom: -2.sp,
              child: Container(
                padding: EdgeInsets.all(4.sp),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A3A3F),
                  shape: BoxShape.circle,
                  border: Border.all(color: tvTheme.backgroundColor, width: 2.sp),
                ),
                child: Icon(Icons.videocam_off_rounded, size: 16.sp, color: Colors.white70),
              ),
            ),
          ],
        ),
        SizedBox(height: 12.sp),
        SizedBox(
          width: 560.sp,
          child: Text(
            title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor),
          ),
        ),
      ],
    );
  }
}
