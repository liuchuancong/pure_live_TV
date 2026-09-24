import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/live_play/player_panel_layout.dart';
import 'package:pure_live/services/app_settings/app_settings_model.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';

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
    this.showFollowAction = false,
    this.trailing,
    this.large = false,
  });

  final LiveRoom room;
  final bool selected;

  /// The room that is playing right now, tinted so the playlist shows where the
  /// session is.
  final bool active;

  /// Whether the room is followed.
  final bool favorite;

  /// Draws the follow state as a text button on the row (follow / followed).
  ///
  /// The playlist panel turns this on: Left/Right follow or unfollow the row
  /// there, so the row shows what the key does. The room switcher leaves it off —
  /// its Left/Right walk the tabs, and a follow label would advertise an action
  /// that does not exist in that list.
  final bool showFollowAction;

  /// Overrides the right-hand read-out; defaults to the audience, or the
  /// replay/record label.
  final String? trailing;

  final bool large;

  /// Total height of one row, margins included.
  ///
  /// The row draws itself with these numbers and the host list sets its
  /// `itemExtent` and its keep-in-view arithmetic from the same source, so the
  /// highlight cannot drift away from the rows it is meant to mark.
  static double extentOf({bool large = false}) => large ? 96.sp : (66 * PlayerPanelLayout.fontSize).sp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final TvThemeData tvTheme = context.tvTheme;
    final double scale = PlayerPanelLayout.fontSize;
    final AppSettingsModel app = ref.watch(appSettingsControllerProvider);

    final String title = room.title.trim().isNotEmpty ? room.title.trim() : i18n('untitled_room');
    final String nick = room.nick.trim();

    final Color foreground = selected ? Colors.white : tvTheme.primaryTextColor;
    final Color muted = selected ? Colors.white70 : tvTheme.secondaryTextColor;

    final double rowHeight = large ? 88.sp : (60 * scale).sp;
    final double rowRadius = large ? 14.sp : 10.sp;
    final double horizontalPadding = large ? 18.sp : 12.sp;

    final double avatarRadius = large ? 30.sp : 20.sp * scale;

    final double titleSize = large ? 20.sp : 16.sp * scale;
    final double nickSize = large ? 16.sp : 14.sp * scale;
    final double platformSize = large ? 15.sp : 13.sp * scale;
    final double metaSize = large ? 15.sp : 13.sp * scale;

    return Container(
      height: rowHeight,
      margin: EdgeInsets.symmetric(vertical: large ? 4.sp : (3 * scale).sp),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: selected
            ? tvTheme.focusColor
            : (active ? tvTheme.focusColor.withValues(alpha: 0.22) : tvTheme.subtleRowFill),
        borderRadius: BorderRadius.circular(rowRadius),
      ),
      child: Row(
        children: [
          TvCommonAvatar(avatarUrl: room.avatar, fallbackName: nick, radius: avatarRadius),
          SizedBox(width: large ? 16.sp : 12.sp),
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
                        style: AppTextStyles.t16W600.copyWith(color: foreground, fontSize: titleSize),
                      ),
                    ),
                    if (showFollowAction)
                      Padding(
                        padding: EdgeInsets.only(left: 8.sp),
                        child: _FollowLabel(
                          followed: favorite,
                          selected: selected,
                          accent: tvTheme.focusColor,
                          scale: scale,
                        ),
                      ),
                  ],
                ),
                if (nick.isNotEmpty) SizedBox(height: large ? 3.sp : 0),
                if (nick.isNotEmpty)
                  Text(
                    nick,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t14W500.copyWith(color: muted, fontSize: nickSize),
                  ),
              ],
            ),
          ),
          SizedBox(width: large ? 18.sp : 8.sp),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (room.platform.trim().isNotEmpty)
                Text(
                  room.platform.toUpperCase(),
                  style: AppTextStyles.t14W600.copyWith(color: muted, fontSize: platformSize),
                ),
              SizedBox(height: large ? 3.sp : 0),
              Text(
                trailing ?? _meta(app, ref.read(appSettingsControllerProvider.notifier)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.t14W500.copyWith(
                  color: selected ? Colors.white : tvTheme.focusColor,
                  fontSize: metaSize,
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

/// The follow state as a text button: "follow" when not followed, "followed"
/// when it is.
///
/// A pill rather than an icon because the row is read at TV distance and the pill
/// also names the action the row's Left/Right performs; the word comes from the
/// same i18n keys the control bar's follow button uses.
class _FollowLabel extends StatelessWidget {
  const _FollowLabel({required this.followed, required this.selected, required this.accent, required this.scale});

  final bool followed;
  final bool selected;
  final Color accent;
  final double scale;

  @override
  Widget build(BuildContext context) {
    // On the accent fill the pill takes white, like the rest of the selected row;
    // on a normal row it is the accent itself. An unfollowed row is muted so the
    // followed ones stand out.
    final Color color = selected ? Colors.white : accent;
    final Color background = selected ? Colors.white.withValues(alpha: 0.22) : color.withValues(alpha: followed ? 0.22 : 0.10);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 2.sp),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6.sp),
        border: Border.all(color: color.withValues(alpha: selected ? 0.75 : (followed ? 0.75 : 0.35))),
      ),
      child: Text(
        followed ? i18n('followed') : i18n('follow'),
        style: AppTextStyles.t14W500.copyWith(
          color: color,
          fontSize: 14.sp * scale,
          fontWeight: followed ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}
