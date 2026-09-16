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
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// The player's control layer, driven by a **selected index** instead of Flutter
/// focus.
///
/// Modelled on the reference player (`pure_live_TV/lib/modules/live_play`), where
/// one value tracks which button is selected (`currentBottomClickType`,
/// `qualityCurrentIndex`, `lineCurrentIndex`) and a key handler moves it. On a
/// remote that is far more predictable than focus traversal: Left/Right always
/// walk the bar, OK always activates what is highlighted, Up moves into the open
/// panel, Left closes it. Nothing can lose focus, and there is no per-button
/// focus ring to hunt for.
///
/// Volume buttons are gone: a TV has hardware volume and an on-screen pair only
/// ate two of the most reachable positions.
class VideoControllerPanel extends ConsumerStatefulWidget {
  final LivePlayArgs args;

  const VideoControllerPanel({super.key, required this.args});

  @override
  ConsumerState<VideoControllerPanel> createState() => _VideoControllerPanelState();
}

/// Which side of the layer the remote is steering.
enum _Zone { bar, options }

/// The option list shown next to the bar, if any.
enum _OptionsPanel { none, quality, line, fit }

class _VideoControllerPanelState extends ConsumerState<VideoControllerPanel> {
  static const double _barHeight = 56;
  static const double _optionsWidth = 380;

  /// Remembered across appear/disappear so the controls come back where they
  /// were left, like the reference's index values.
  int _barIndex = 0;
  int _optionIndex = 0;
  _Zone _zone = _Zone.bar;
  _OptionsPanel _panel = _OptionsPanel.none;

  // =========================
  // data helpers
  // =========================

  String _qualityLabel(LivePlayState state) {
    if (state.qualities.isEmpty) return '-';
    return state.qualities[state.qualityIndex.clamp(0, state.qualities.length - 1)].quality;
  }

  String _fitLabel(LivePlayState state) =>
      kLivePlayFitLabels[state.fitIndex.clamp(0, kLivePlayFitLabels.length - 1)];

  String _engineLabel() {
    final key = ref.read(playerSettingsControllerProvider).videoPlayerKey;
    return i18n(PlayerConsts.names[key] ?? PlayerConsts.names[PlayerConsts.defaultKey] ?? key);
  }

  /// Options of the open panel, as (label, apply) pairs.
  List<({String label, VoidCallback apply, bool active})> _panelOptions(LivePlayState state) {
    switch (_panel) {
      case _OptionsPanel.quality:
        return <({String label, VoidCallback apply, bool active})>[
          for (int i = 0; i < state.qualities.length; i++)
            (
              label: state.qualities[i].quality,
              active: i == state.qualityIndex,
              apply: () => unawaited(_changeQuality(i)),
            ),
        ];
      case _OptionsPanel.line:
        return <({String label, VoidCallback apply, bool active})>[
          for (int i = 0; i < state.playUrls.length; i++)
            (
              label: i18n('multiview_line', args: {'index': '${i + 1}'}),
              active: i == state.lineIndex,
              apply: () => unawaited(_changeLine(i)),
            ),
        ];
      case _OptionsPanel.fit:
        return <({String label, VoidCallback apply, bool active})>[
          for (int i = 0; i < kLivePlayFitLabels.length; i++)
            (
              label: kLivePlayFitLabels[i],
              active: i == state.fitIndex,
              apply: () => _setFit(i),
            ),
        ];
      case _OptionsPanel.none:
        return const <({String label, VoidCallback apply, bool active})>[];
    }
  }

  String get _panelTitle => switch (_panel) {
    _OptionsPanel.quality => i18n('recorder_stage_quality'),
    _OptionsPanel.line => i18n('multiview_line_selector'),
    _OptionsPanel.fit => i18n('ui_aspect_ratio'),
    _OptionsPanel.none => '',
  };

  Future<void> _changeQuality(int index) async {
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    controller.keepControlsAlive();
    await controller.changeQuality(index);
  }

  Future<void> _changeLine(int index) async {
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    controller.keepControlsAlive();
    await controller.changeLine(index);
  }

  void _setFit(int index) {
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    controller.keepControlsAlive();
    controller.setFit(index);
  }

  void _openPanel(_OptionsPanel panel, LivePlayState state) {
    setState(() {
      _panel = panel;
      _zone = _Zone.options;
      _optionIndex = switch (panel) {
        _OptionsPanel.quality => state.qualityIndex,
        _OptionsPanel.line => state.lineIndex,
        _OptionsPanel.fit => state.fitIndex,
        _OptionsPanel.none => 0,
      };
    });
  }

  void _closePanel() => setState(() {
    _panel = _OptionsPanel.none;
    _zone = _Zone.bar;
  });

  // =========================
  // key handling
  // =========================

  void _onDirection(TraversalDirection direction, LivePlayState state) {
    final int barCount = _barActions(state).length;
    final int optionCount = _panelOptions(state).length;

    switch (_zone) {
      case _Zone.bar:
        switch (direction) {
          case TraversalDirection.left:
            setState(() => _barIndex = (_barIndex - 1 + barCount) % barCount);
          case TraversalDirection.right:
            setState(() => _barIndex = (_barIndex + 1) % barCount);
          case TraversalDirection.up:
            if (_panel != _OptionsPanel.none && optionCount > 0) {
              setState(() => _zone = _Zone.options);
            }
          case TraversalDirection.down:
            break;
        }
      case _Zone.options:
        switch (direction) {
          case TraversalDirection.up:
            setState(() => _optionIndex = (_optionIndex - 1 + optionCount) % optionCount);
          case TraversalDirection.down:
            setState(() => _optionIndex = (_optionIndex + 1) % optionCount);
          // Left closes the list, like the reference's panels.
          case TraversalDirection.left:
            _closePanel();
          case TraversalDirection.right:
            break;
        }
    }
  }

  void _onSelect(LivePlayState state) {
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    controller.keepControlsAlive();

    if (_zone == _Zone.options) {
      final options = _panelOptions(state);
      if (options.isEmpty) return;
      options[_optionIndex.clamp(0, options.length - 1)].apply();
      // 清晰度/线路 reload the stream; the panel closes so the picture is visible.
      if (_panel == _OptionsPanel.quality || _panel == _OptionsPanel.line) {
        setState(() => _zone = _Zone.bar);
      }
      return;
    }

    _barActions(state)[_barIndex.clamp(0, _barActions(state).length - 1)].onSelect();
  }

  /// Bottom bar: what a viewer touches while watching. Icons where a picture
  /// says it, text where the current value matters (清晰度/线路/比例), exactly like
  /// the reference bar.
  List<_PanelAction> _barActions(LivePlayState state) {
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    final danmakuSettings = ref.watch(danmakuSettingsControllerProvider);
    final danmakuNotifier = ref.read(danmakuSettingsControllerProvider.notifier);
    final favoriteRooms = ref.watch(favoriteRoomControllerProvider).favoriteRooms;
    final room = state.room;
    final bool playing = state.status == LivePlayStatus.playing || state.status == LivePlayStatus.buffering;
    final bool isFavorite = room != null && favoriteRooms.any((item) => item.hasSameIdentity(room));
    final bool danmakuOn = danmakuSettings.enableDanmakuDisplay && !danmakuSettings.hideDanmaku;

    return <_PanelAction>[
      _PanelAction(
        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
        label: isFavorite ? i18n('followed') : i18n('follow'),
        active: isFavorite,
        onSelect: () {
          if (room == null) return;
          final fav = ref.read(favoriteRoomControllerProvider.notifier);
          if (isFavorite) {
            fav.removeRoom(room);
          } else {
            fav.addRoom(room);
          }
        },
      ),
      _PanelAction(icon: Icons.refresh_rounded, label: i18n('retry'), onSelect: controller.retry),
      _PanelAction(
        icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        label: playing ? i18n('multiview_pause') : i18n('multiview_play'),
        onSelect: controller.togglePlayPause,
      ),
      _PanelAction(
        icon: danmakuOn ? Icons.subtitles : Icons.subtitles_off,
        label: danmakuOn ? i18n('ui_danmaku_on') : i18n('ui_danmaku_off'),
        active: danmakuOn,
        onSelect: () => danmakuNotifier.updateSettings(
          danmakuSettings.copyWith(enableDanmakuDisplay: !danmakuOn, hideDanmaku: danmakuOn),
        ),
      ),
      _PanelAction(
        icon: Icons.tune_rounded,
        label: i18n('danmaku_settings'),
        active: state.showSidePanel && state.panel == LivePlayPanel.danmakuSettings,
        onSelect: () => controller.togglePanel(LivePlayPanel.danmakuSettings),
      ),
      // The three value buttons open the option list on the right.
      _PanelAction(
        icon: Icons.high_quality_rounded,
        label: _qualityLabel(state),
        active: _panel == _OptionsPanel.quality,
        onSelect: () => _openPanel(_OptionsPanel.quality, state),
      ),
      _PanelAction(
        icon: Icons.density_small_rounded,
        label: i18n('multiview_line', args: {'index': '${state.lineIndex + 1}'}),
        active: _panel == _OptionsPanel.line,
        onSelect: () => _openPanel(_OptionsPanel.line, state),
      ),
      _PanelAction(
        icon: Icons.video_settings_outlined,
        label: _fitLabel(state),
        active: _panel == _OptionsPanel.fit,
        onSelect: () => _openPanel(_OptionsPanel.fit, state),
      ),
      _PanelAction(
        icon: Icons.dynamic_feed_rounded,
        label: i18n('danmaku_filter'),
        active: state.showSidePanel && state.panel == LivePlayPanel.shield,
        onSelect: () => controller.togglePanel(LivePlayPanel.shield),
      ),
      _PanelAction(
        icon: Icons.playlist_play_rounded,
        label: i18nOr('ui_playlist', 'Playlist'),
        active: state.showSidePanel && state.panel == LivePlayPanel.playlist,
        onSelect: () => controller.togglePanel(LivePlayPanel.playlist),
      ),
      _PanelAction(
        icon: Icons.info_outline_rounded,
        label: i18nOr('ui_room_info', 'Room info'),
        active: state.showSidePanel && state.panel == LivePlayPanel.info,
        onSelect: () => controller.togglePanel(LivePlayPanel.info),
      ),
      _PanelAction(
        icon: Icons.memory_rounded,
        label: _engineLabel(),
        onSelect: () => unawaited(_pickEngine()),
      ),
      _PanelAction(
        icon: Icons.swap_horiz_rounded,
        label: i18n('switch_live_room'),
        onSelect: () => unawaited(_switchRoom(state.room)),
      ),
      _PanelAction(
        icon: Icons.wallpaper_rounded,
        label: i18nOr('ui_background_settings', 'Background'),
        onSelect: () => context.push(AppRoutes.kWallpaperPage),
      ),
    ];
  }

  /// 播放器内核 picker: mpv / ijk / exo, switched on the live service right away.
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
        for (final String k in engineKeys) TvSelectItem<String>(title: i18n(PlayerConsts.names[k] ?? k), value: k),
      ],
    );
    if (key == null || !mounted || key == activeKey) return;

    ref.read(livePlayControllerProvider(widget.args).notifier).keepControlsAlive();
    ref.read(playerSettingsControllerProvider.notifier).updateSettings(playerSettings.copyWith(videoPlayerKey: key));

    final engine = PlayerConsts.engines[key];
    final service = GlobalPlayerService.instance;
    if (engine == null || !service.initialized) return;
    unawaited(
      service.playerManager.switchEngine(engine, isManual: true).catchError((Object error, StackTrace stackTrace) {
        debugPrint('Switch player kernel to $key failed: $error');
      }),
    );
  }

  Future<void> _switchRoom(LiveRoom? room) async {
    if (room == null) return;
    final selected = await showRoomSwitchDialog(context, current: room);
    if (selected == null || !mounted) return;
    // Replacing the route disposes this room's controller and starts the selected
    // room through the same page.
    context.replace(AppRoutes.kLivePlay, extra: selected);
  }

  // =========================
  // build
  // =========================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livePlayControllerProvider(widget.args));
    final tvTheme = context.tvTheme;
    final actions = _barActions(state);
    final options = _panelOptions(state);
    // The bar can shrink between frames (a room without qualities); keep the
    // selection inside it.
    if (_barIndex >= actions.length) _barIndex = actions.isEmpty ? 0 : actions.length - 1;
    if (options.isNotEmpty && _optionIndex >= options.length) _optionIndex = options.length - 1;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.9), Colors.black.withValues(alpha: 0.0)],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_panel != _OptionsPanel.none && options.isNotEmpty) _buildOptionsPanel(state, options, tvTheme),
          _buildBar(actions, tvTheme),
        ],
      ),
    );
  }

  /// Right-hand option list: one column, the selected row highlighted, the
  /// current value ticked.
  Widget _buildOptionsPanel(
    LivePlayState state,
    List<({String label, VoidCallback apply, bool active})> options,
    TvThemeData tvTheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(right: 24.sp, bottom: 12.sp),
      child: Container(
        width: _optionsWidth.sp,
        constraints: BoxConstraints(maxHeight: 560.sp),
        decoration: BoxDecoration(
          color: tvTheme.backgroundColor.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16.sp),
          border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.sp, 16.sp, 24.sp, 8.sp),
              child: Text(
                _panelTitle,
                style: AppTextStyles.t20W600.copyWith(color: tvTheme.primaryTextColor),
              ),
            ),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.only(bottom: 12.sp),
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final bool selected = index == _optionIndex;
                  final option = options[index];
                  return Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 10.sp),
                      decoration: BoxDecoration(
                        color: selected ? tvTheme.focusColor.withValues(alpha: 0.25) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10.sp),
                        border: Border.all(
                          color: selected ? tvTheme.focusColor : Colors.transparent,
                          width: 2.sp,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              option.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.t18W500.copyWith(
                                color: selected ? tvTheme.focusColor : tvTheme.primaryTextColor,
                              ),
                            ),
                          ),
                          if (option.active)
                            Icon(Icons.check_rounded, size: 22.sp, color: tvTheme.focusColor),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Bottom bar: one black strip of icon/text buttons, index-driven.
  Widget _buildBar(List<_PanelAction> actions, TvThemeData tvTheme) {
    return Container(
      height: _barHeight.sp + 24.sp,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
      child: DpadFocusable(
        // The controls are shown by the OK key; the bar is where the remote
        // lands, and the remembered index decides which button is highlighted.
        autofocus: true,
        effects: const [],
        excludeChildFocus: true,
        // Every direction is consumed here: the index is the only cursor, so
        // focus can never wander off the controls.
        onDirection: (direction) {
          _onDirection(direction, ref.read(livePlayControllerProvider(widget.args)));
          return true;
        },
        onSelect: () => _onSelect(ref.read(livePlayControllerProvider(widget.args))),
        child: SizedBox(
          height: _barHeight.sp,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.zero,
            itemCount: actions.length,
            separatorBuilder: (_, _) => SizedBox(width: 12.sp),
            itemBuilder: (context, index) {
              final action = actions[index];
              final bool selected = _zone == _Zone.bar && index == _barIndex;
              return _BarButton(
                icon: action.icon,
                label: action.label,
                selected: selected,
                active: action.active,
                accent: tvTheme.focusColor,
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PanelAction {
  const _PanelAction({required this.icon, required this.label, required this.onSelect, this.active = false});

  final IconData icon;
  final String label;
  final VoidCallback onSelect;

  /// A state this button currently represents (followed, danmaku on, open
  /// panel), shown as a tinted background even when it is not selected.
  final bool active;
}

/// One bar button: outlined when it is merely on, filled when the index is on it.
class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.active,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final bool active;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final Color background = selected
        ? accent
        : (active ? accent.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08));
    final Color foreground = selected ? Colors.black : Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.sp),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10.sp),
        border: Border.all(
          color: selected || active ? accent : Colors.white.withValues(alpha: 0.18),
          width: selected ? 2.sp : 1.sp,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22.sp, color: foreground),
          SizedBox(width: 8.sp),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.t16W500.copyWith(color: foreground, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
