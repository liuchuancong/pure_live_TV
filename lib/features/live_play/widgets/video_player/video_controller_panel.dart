import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/player/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/dialogs/room_switch_dialog.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';
import 'package:pure_live/shared/dialog/index.dart';
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

  /// Width of the right-hand option column (`sp`): room for an icon plus a
  /// two-to-three character label such as 清晰度 or 画面比例.
  static const double _columnWidth = 168;

  String _qualityLabel(LivePlayState state) {
    if (state.qualities.isEmpty) return '-';
    final int index = state.qualityIndex.clamp(0, state.qualities.length - 1);
    return state.qualities[index].quality;
  }

  /// Label of the engine action: the kernel's localized name.
  String _engineLabel() {
    final key = ref.read(playerSettingsControllerProvider).videoPlayerKey;
    return i18n(PlayerConsts.names[key] ?? PlayerConsts.names[PlayerConsts.defaultKey] ?? key);
  }

  /// 清晰度 picker, over the video.
  Future<void> _pickQuality(LivePlayState state) async {
    if (state.qualities.isEmpty) return;
    final int? index = await TvDialogUtils.showSelect<int>(
      context: context,
      title: i18n('recorder_stage_quality'),
      selectedValue: state.qualityIndex,
      items: <TvSelectItem<int>>[
        for (int i = 0; i < state.qualities.length; i++)
          TvSelectItem<int>(title: state.qualities[i].quality, value: i),
      ],
    );
    if (index == null || !mounted) return;
    ref.read(livePlayControllerProvider(widget.args).notifier).keepControlsAlive();
    await ref.read(livePlayControllerProvider(widget.args).notifier).changeQuality(index);
  }

  /// 线路 picker, over the video.
  Future<void> _pickLine(LivePlayState state) async {
    if (state.playUrls.isEmpty) return;
    final int? index = await TvDialogUtils.showSelect<int>(
      context: context,
      title: i18n('multiview_line_selector'),
      selectedValue: state.lineIndex,
      items: <TvSelectItem<int>>[
        for (int i = 0; i < state.playUrls.length; i++)
          TvSelectItem<int>(title: i18n('multiview_line', args: {'index': '${i + 1}'}), value: i),
      ],
    );
    if (index == null || !mounted) return;
    ref.read(livePlayControllerProvider(widget.args).notifier).keepControlsAlive();
    await ref.read(livePlayControllerProvider(widget.args).notifier).changeLine(index);
  }

  /// 画面比例 picker, over the video. A dialog lists every option at once —
  /// stepping with OK offered no overview of what the modes even were.
  Future<void> _pickFit(LivePlayState state) async {
    final labels = kLivePlayFitLabels;
    if (labels.isEmpty) return;
    final int? index = await TvDialogUtils.showSelect<int>(
      context: context,
      title: i18n('ui_aspect_ratio'),
      selectedValue: state.fitIndex.clamp(0, labels.length - 1),
      items: <TvSelectItem<int>>[
        for (int i = 0; i < labels.length; i++) TvSelectItem<int>(title: labels[i], value: i),
      ],
    );
    if (index == null || !mounted) return;
    ref.read(livePlayControllerProvider(widget.args).notifier).keepControlsAlive();
    ref.read(livePlayControllerProvider(widget.args).notifier).setFit(index);
  }

  /// 播放器内核 picker: mpv / ijk / exo.
  ///
  /// Writing `videoPlayerKey` alone only reaches the next player created from
  /// scratch, so the engine is switched on the live service right away — the
  /// same flow the 设置 → 播放器内核 page uses.
  Future<void> _pickEngine() async {
    final engineKeys = PlayerConsts.engines.keys.toList(growable: false);
    final playerSettings = ref.read(playerSettingsControllerProvider);
    final String activeKey = PlayerConsts.engines.containsKey(playerSettings.videoPlayerKey)
        ? playerSettings.videoPlayerKey
        : PlayerConsts.defaultKey;

    final String? key = await TvDialogUtils.showSelect<String>(
      context: context,
      title: i18n('kernel_switch'),
      selectedValue: activeKey,
      items: <TvSelectItem<String>>[
        for (final String k in engineKeys)
          TvSelectItem<String>(title: i18n(PlayerConsts.names[k] ?? k), value: k),
      ],
    );
    if (key == null || !mounted || key == activeKey) return;

    ref.read(livePlayControllerProvider(widget.args).notifier).keepControlsAlive();
    ref
        .read(playerSettingsControllerProvider.notifier)
        .updateSettings(playerSettings.copyWith(videoPlayerKey: key));

    final engine = PlayerConsts.engines[key];
    final service = GlobalPlayerService.instance;
    if (engine == null || !service.initialized) return;
    unawaited(
      service.playerManager.switchEngine(engine, isManual: true).catchError((Object error, StackTrace stackTrace) {
        debugPrint('Switch player kernel to $key failed: $error');
      }),
    );
  }

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
        inColumn: true,
        label: kLivePlayFitLabels[state.fitIndex.clamp(0, kLivePlayFitLabels.length - 1)],
        onSelect: () {
          keepAlive();
          unawaited(_pickFit(state));
        },
      ),
      // 播放器内核 belongs beside the other playback choices: a broken stream
      // is exactly when a TV viewer wants to try another kernel.
      _PanelAction(
        icon: Icons.memory_rounded,
        inColumn: true,
        label: _engineLabel(),
        onSelect: () {
          keepAlive();
          unawaited(_pickEngine());
        },
      ),
      // 清晰度 and 线路 belong to the fullscreen controls, like every other
      // playback choice: a TV viewer switches them while watching, not in a
      // settings page.
      _PanelAction(
        icon: Icons.high_quality_rounded,
        label: '${i18n('recorder_stage_quality')} ${_qualityLabel(state)}',
        onSelect: () {
          keepAlive();
          unawaited(_pickQuality(state));
        },
      ),
      _PanelAction(
        icon: Icons.swap_vert_rounded,
        label: '${i18n('multiview_line_selector')} ${state.lineIndex + 1}',
        onSelect: () {
          keepAlive();
          unawaited(_pickLine(state));
        },
      ),
      _PanelAction(
        icon: Icons.subtitles,
        inColumn: true,
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
        inColumn: true,
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
        inColumn: true,
        label: i18n('danmaku_settings'),
        highlighted: state.showSidePanel && state.panel == LivePlayPanel.danmakuSettings,
        onSelect: () {
          keepAlive();
          controller.togglePanel(LivePlayPanel.danmakuSettings);
        },
      ),
      _PanelAction(
        icon: Icons.filter_alt_outlined,
        inColumn: true,
        label: i18n('danmaku_filter'),
        highlighted: state.showSidePanel && state.panel == LivePlayPanel.shield,
        onSelect: () {
          keepAlive();
          controller.togglePanel(LivePlayPanel.shield);
        },
      ),
      _PanelAction(
        icon: Icons.playlist_play_rounded,
        inColumn: true,
        label: i18nOr('ui_playlist', 'Playlist'),
        highlighted: state.showSidePanel && state.panel == LivePlayPanel.playlist,
        onSelect: () {
          keepAlive();
          controller.togglePanel(LivePlayPanel.playlist);
        },
      ),
      _PanelAction(
        icon: Icons.info_outline_rounded,
        inColumn: true,
        label: i18nOr('ui_room_info', 'Room info'),
        highlighted: state.showSidePanel && state.panel == LivePlayPanel.info,
        onSelect: () {
          keepAlive();
          controller.togglePanel(LivePlayPanel.info);
        },
      ),
      _PanelAction(
        icon: Icons.wallpaper_rounded,
        inColumn: true,
        label: i18nOr('ui_background_settings', 'Background'),
        onSelect: () {
          keepAlive();
          context.push(AppRoutes.kWallpaperPage);
        },
      ),
      _PanelAction(
        icon: Icons.swap_horiz_rounded,
        inColumn: true,
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

    // TV-box layout: bottom bar + right column, split by `inColumn`.
    final barActions = [for (final a in actions) if (!a.inColumn) a];
    final columnActions = [for (final a in actions) if (a.inColumn) a];

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
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
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
                        itemCount: barActions.length,
                        separatorBuilder: (_, _) => SizedBox(width: 16.sp),
                        itemBuilder: (context, index) {
                          final action = barActions[index];
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
          ),
          // The column shares the right edge with the side panel, so it steps
          // aside while a panel is open (the panel has its own focus region).
          if (!state.showSidePanel && columnActions.isNotEmpty) ...[
            SizedBox(width: 20.sp),
            SizedBox(
              width: _columnWidth.sp,
              child: DpadRegion(
                memoryKey: 'live_play/controls/options',
                verticalEdge: DpadEdgeBehavior.wrap,
                horizontalEdge: DpadEdgeBehavior.leave,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final action in columnActions)
                      Padding(
                        padding: EdgeInsets.only(top: 8.sp),
                        child: _PanelButton(
                          icon: action.icon,
                          label: action.label,
                          compact: true,
                          highlighted: action.highlighted,
                          onFocusChange: (_) => keepAlive(),
                          onSelect: action.onSelect,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
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
    this.inColumn = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelect;

  /// Marks the region entry target; see the play/pause action.
  final bool entry;

  /// Panel buttons stay highlighted while their panel is open.
  final bool highlighted;

  /// TV-box layout: the bottom bar carries what a viewer presses while watching
  /// (play/pause, 清晰度, 线路, 音量, 重试); everything that is a setting rather
  /// than a transport action moves to the vertical column on the right, so
  /// nothing needs a long horizontal scroll to reach.
  final bool inColumn;
}

class _PanelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onSelect;
  final ValueChanged<bool> onFocusChange;
  final bool entry;
  final bool highlighted;

  /// Column layout: stretches to the column width and ellipsises a long label
  /// instead of widening the column.
  final bool compact;

  const _PanelButton({
    required this.icon,
    required this.label,
    required this.onSelect,
    required this.onFocusChange,
    this.entry = false,
    this.highlighted = false,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final Widget content = compact
        ? Row(
            children: [
              Icon(icon, size: 20.sp, color: Colors.white),
              SizedBox(width: 8.sp),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t16W500.copyWith(color: Colors.white),
                ),
              ),
            ],
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 20.sp, color: Colors.white),
              SizedBox(width: 8.sp),
              Text(label, style: AppTextStyles.t16W500.copyWith(color: Colors.white)),
            ],
          );

    return DpadFocusable(
      entry: entry,
      effects: [
        DpadScaleEffect(scale: 1.05),
        DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.5)),
      ],
      onFocusChange: onFocusChange,
      onSelect: onSelect,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: compact ? 12.sp : 18.sp, vertical: compact ? 8.sp : 10.sp),
        decoration: BoxDecoration(
          color: highlighted ? tvTheme.focusColor.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.sp),
          border: Border.all(
            color: highlighted ? tvTheme.focusColor : Colors.white.withValues(alpha: 0.18),
          ),
        ),
        child: content,
      ),
    );
  }
}
