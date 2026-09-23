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
    this.trailing,
    this.large = false,
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

  final bool large;

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
                    if (favorite)
                      Padding(
                        padding: EdgeInsets.only(left: 6.sp),
                        child: Icon(
                          Icons.favorite,
                          size: (large ? 18.sp : 16.sp * scale),
                          color: selected ? Colors.white : tvTheme.focusColor,
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
