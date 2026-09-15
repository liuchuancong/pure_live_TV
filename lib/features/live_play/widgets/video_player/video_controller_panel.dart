import 'package:dpad/dpad.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/dialogs/room_switch_dialog.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// Bottom control bar of the video area, driven entirely by D-pad focus.
///
/// No button from the legacy app is missing: play/pause, volume, aspect ratio,
/// danmaku toggle, follow, danmaku settings, danmaku filter, playlist,
/// background settings, switch room and retry.
/// They do not fit in one row, so the bar scrolls horizontally and wraps at
/// the edges ([DpadEdgeBehavior.wrap]).
class VideoControllerPanel extends ConsumerStatefulWidget {
  final LivePlayArgs args;

  const VideoControllerPanel({super.key, required this.args});

  @override
  ConsumerState<VideoControllerPanel> createState() => _VideoControllerPanelState();
}

class _VideoControllerPanelState extends ConsumerState<VideoControllerPanel> {
  static const double _barHeight = 56;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livePlayControllerProvider(widget.args));
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    final danmakuSettings = ref.watch(danmakuSettingsControllerProvider);
    final danmakuNotifier = ref.read(danmakuSettingsControllerProvider.notifier);
    final favoriteRooms = ref.watch(favoriteRoomControllerProvider).favoriteRooms;
    final tvTheme = context.tvTheme;

    final room = state.room;
    final bool playing = state.status == LivePlayStatus.playing || state.status == LivePlayStatus.buffering;
    final bool isFavorite = room != null && favoriteRooms.any((item) => item.hasSameIdentity(room));
    final bool danmakuOn = danmakuSettings.enableDanmakuDisplay && !danmakuSettings.hideDanmaku;

    void keepAlive() => controller.keepControlsAlive();

    final actions = <_PanelAction>[
      _PanelAction(
        icon: playing ? Icons.pause : Icons.play_arrow,
        label: playing ? i18n('multiview_pause') : i18n('multiview_play'),
        // The region's entry target, not `autofocus`: the bar is removed from
        // the tree while the controls are hidden, so an autofocus would grab
        // focus back to play/pause every time the bar reappeared — even when
        // the user had been on another button. The region remembers the last
        // focused button and falls back to this entry target the first time.
        entry: true,
        onSelect: () {
          keepAlive();
          controller.togglePlayPause();
        },
      ),
      _PanelAction(
        icon: Icons.volume_down,
        label: i18n('ui_volume_down'),
        onSelect: () {
          keepAlive();
          controller.volumeDown();
        },
      ),
      _PanelAction(
        icon: Icons.volume_up,
        label: i18n('ui_volume_up'),
        onSelect: () {
          keepAlive();
          controller.volumeUp();
        },
      ),
      _PanelAction(
        icon: Icons.aspect_ratio,
        label: kLivePlayFitLabels[state.fitIndex.clamp(0, kLivePlayFitLabels.length - 1)],
        onSelect: () {
          keepAlive();
          controller.cycleFit();
        },
      ),
      _PanelAction(
        icon: Icons.subtitles,
        label: danmakuOn ? i18n('ui_danmaku_on') : i18n('ui_danmaku_off'),
        onSelect: () {
          keepAlive();
          danmakuNotifier.updateSettings(
            danmakuSettings.copyWith(enableDanmakuDisplay: !danmakuOn, hideDanmaku: danmakuOn),
          );
        },
      ),
      _PanelAction(
        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
        label: isFavorite ? i18n('followed') : i18n('follow'),
        highlighted: isFavorite,
        onSelect: () {
          keepAlive();
          if (room == null) return;
          final fav = ref.read(favoriteRoomControllerProvider.notifier);
          if (isFavorite) {
            fav.removeRoom(room);
          } else {
            fav.addRoom(room);
          }
        },
      ),
      _PanelAction(
        icon: Icons.tune_rounded,
        label: i18n('danmaku_settings'),
        highlighted: state.showSidePanel && state.panel == LivePlayPanel.danmakuSettings,
        onSelect: () {
          keepAlive();
          controller.togglePanel(LivePlayPanel.danmakuSettings);
        },
      ),
      _PanelAction(
        icon: Icons.filter_alt_outlined,
        label: i18n('danmaku_filter'),
        highlighted: state.showSidePanel && state.panel == LivePlayPanel.shield,
        onSelect: () {
          keepAlive();
          controller.togglePanel(LivePlayPanel.shield);
        },
      ),
      _PanelAction(
        icon: Icons.playlist_play_rounded,
        label: i18nOr('ui_playlist', 'Playlist'),
        highlighted: state.showSidePanel && state.panel == LivePlayPanel.playlist,
        onSelect: () {
          keepAlive();
          controller.togglePanel(LivePlayPanel.playlist);
        },
      ),
      _PanelAction(
        icon: Icons.info_outline_rounded,
        label: i18nOr('ui_room_info', 'Room info'),
        highlighted: state.showSidePanel && state.panel == LivePlayPanel.info,
        onSelect: () {
          keepAlive();
          controller.togglePanel(LivePlayPanel.info);
        },
      ),
      _PanelAction(
        icon: Icons.wallpaper_rounded,
        label: i18nOr('ui_background_settings', 'Background'),
        onSelect: () {
          keepAlive();
          context.push(AppRoutes.kWallpaperPage);
        },
      ),
      _PanelAction(
        icon: Icons.swap_horiz_rounded,
        label: i18n('switch_live_room'),
        onSelect: () async {
          keepAlive();
          if (room == null) return;
          final selected = await showRoomSwitchDialog(context, current: room);
          if (selected == null || !context.mounted) return;
          // Replacing the route disposes this room's controller and starts
          // the selected room through the same page.
          context.replace(AppRoutes.kLivePlay, extra: selected);
        },
      ),
      _PanelAction(
        icon: Icons.refresh,
        label: i18n('retry'),
        onSelect: () {
          keepAlive();
          controller.retry();
        },
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.85), Colors.black.withValues(alpha: 0.0)],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 16.sp),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: _barHeight.sp,
              child: DpadRegion(
                memoryKey: 'live_play/controls',
                horizontalEdge: DpadEdgeBehavior.wrap,
                verticalEdge: DpadEdgeBehavior.leave,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: actions.length,
                  separatorBuilder: (_, _) => SizedBox(width: 16.sp),
                  itemBuilder: (context, index) {
                    final action = actions[index];
                    return _PanelButton(
                      icon: action.icon,
                      label: action.label,
                      entry: action.entry,
                      highlighted: action.highlighted,
                      onFocusChange: (_) => keepAlive(),
                      onSelect: action.onSelect,
                    );
                  },
                ),
              ),
            ),
          ),
          SizedBox(width: 16.sp),
          Text(
            '${(state.volume.clamp(0.0, 1.0) * 100).round()}%',
            style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor),
          ),
        ],
      ),
    );
  }
}

class _PanelAction {
  const _PanelAction({
    required this.icon,
    required this.label,
    required this.onSelect,
    this.entry = false,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelect;

  /// Marks the region entry target; see the play/pause action.
  final bool entry;

  /// Panel buttons stay highlighted while their panel is open.
  final bool highlighted;
}

class _PanelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onSelect;
  final ValueChanged<bool> onFocusChange;
  final bool entry;
  final bool highlighted;

  const _PanelButton({
    required this.icon,
    required this.label,
    required this.onSelect,
    required this.onFocusChange,
    this.entry = false,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return DpadFocusable(
      entry: entry,
      effects: [
        DpadScaleEffect(scale: 1.05),
        DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.5)),
      ],
      onFocusChange: onFocusChange,
      onSelect: onSelect,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.sp, vertical: 10.sp),
        decoration: BoxDecoration(
          color: highlighted ? tvTheme.focusColor.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.sp),
          border: Border.all(
            color: highlighted ? tvTheme.focusColor : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20.sp, color: Colors.white),
            SizedBox(width: 8.sp),
            Text(label, style: AppTextStyles.t16W500.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
