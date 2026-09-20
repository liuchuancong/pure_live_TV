import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/features/live_play/player_panel_layout.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/services/app_settings/app_settings_model.dart';

/// One room, drawn as the mobile app's *small-screen* room card
/// (`PlayOther` → `_RoomSwitchCard._buildMobileLayout`): the avatar, the room
/// title with its streamer underneath, then the platform badge and the current
/// read-out (audience, or replay/replay for a replay) on the right.
///
/// Used by the player's playlist panel and by room switcher, so both lists look the
/// same and show more than a bare title.
///
/// Colours come from the active palette — dark themes keep a light-on-dark row,
/// light themes get dark text on the light card — and the selected row is the
/// accent fill with white content, which is the focus colour every player list
/// uses.
class PlayerRoomRow extends ConsumerWidget {
  const PlayerRoomRow({
    super.key,
    required this.room,
    required this.selected,
    this.active = false,
    this.favorite = false,
    this.trailing,
  });

  final LiveRoom room;
  final bool selected;

  /// The room that is playing right now, tinted so the playlist shows where the
  /// session is.
  final bool active;

  /// Shows the follow heart (the playlist panel marks followed rooms).
  final bool favorite;

  /// Overrides the right-hand read-out; defaults to the audience, or the
  /// replay/record label.
  final String? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TvThemeData tvTheme = context.tvTheme;
    final double scale = PlayerPanelLayout.fontSize;
    final AppSettingsModel app = ref.watch(appSettingsControllerProvider);

    final String title = room.title.trim().isNotEmpty ? room.title.trim() : i18n('untitled_room');
    final String nick = room.nick.trim();

    final Color foreground = selected ? Colors.white : tvTheme.primaryTextColor;
    final Color muted = selected ? Colors.white70 : tvTheme.secondaryTextColor;

    return Container(
      height: (60 * scale).sp,
      margin: EdgeInsets.symmetric(vertical: (3 * scale).sp),
      padding: EdgeInsets.symmetric(horizontal: 12.sp),
      decoration: BoxDecoration(
        color: selected
            ? tvTheme.focusColor
            : (active ? tvTheme.focusColor.withValues(alpha: 0.22) : tvTheme.subtleRowFill),
        borderRadius: BorderRadius.circular(10.sp),
      ),
      child: Row(
        children: [
          TvCommonAvatar(avatarUrl: room.avatar, fallbackName: nick, radius: 20.sp * scale),
          SizedBox(width: 12.sp),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t16W600.copyWith(color: foreground, fontSize: 16.sp * scale),
                      ),
                    ),
                    if (favorite)
                      Padding(
                        padding: EdgeInsets.only(left: 6.sp),
                        child: Icon(Icons.favorite, size: 16.sp * scale, color: selected ? Colors.white : tvTheme.focusColor),
                      ),
                  ],
                ),
                if (nick.isNotEmpty)
                  Text(
                    nick,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t14W500.copyWith(color: muted, fontSize: 14.sp * scale),
                  ),
              ],
            ),
          ),
          SizedBox(width: 8.sp),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (room.platform.trim().isNotEmpty)
                Text(
                  room.platform.toUpperCase(),
                  style: AppTextStyles.t14W600.copyWith(color: muted, fontSize: 13.sp * scale),
                ),
              Text(
                trailing ?? _meta(app, ref.read(appSettingsControllerProvider.notifier)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.t14W500.copyWith(
                  color: selected ? Colors.white : tvTheme.focusColor,
                  fontSize: 13.sp * scale,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// The right-hand read-out: the replay label for a recording, otherwise the
  /// audience the app currently prefers (heat or real online viewers).
  ///
  /// The per-platform real-viewer switch lives on the controller, not on the
  /// state, so both are needed here.
  String _meta(AppSettingsModel app, AppSettingsController controller) {
    if (room.isRecord || room.effectiveLiveStatus == LiveStatus.replay) {
      return i18nOr('ui_replay', '重播');
    }
    final String audience = room.audienceValue(
      preferRealOnline: app.preferRealOnlineCounts,
      platformEnabled: controller.isRealOnlineEnabledFor(room.platform),
    );
    return audience.isEmpty ? i18n('audience_unknown') : readableCount(audience);
  }
}
