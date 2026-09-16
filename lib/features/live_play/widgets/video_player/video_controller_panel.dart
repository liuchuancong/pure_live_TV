import 'dart:async';

import 'package:flutter_svg/flutter_svg.dart';
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

/// The player's control layer: **no d-pad, no Flutter focus traversal**.
///
/// Ported from the reference player (`E:/project/pure_live_TV/lib/modules/
/// live_play`), which installs one key handler for the whole video page and
/// keeps a selected index per area (`currentNodeIndex`, `qualityCurrentIndex`,
/// `lineCurrentIndex`, `danmukuNodeIndex`). One [Focus] owns the keys here and
/// steers those indexes, so:
///
/// * Left/Right always walk the bar with wrap, OK always activates what is
///   highlighted, Up enters the open option list, Left closes it;
/// * nothing can steal focus, and there is no per-button focus ring to hunt for;
/// * the bar looks like the reference's: a black strip of pill buttons with an
///   icon and, where the current value matters, its text.
///
/// Volume buttons are omitted on purpose — a TV has hardware volume, and the two
/// most reachable slots are better used by 清晰度 and 线路.
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
  static const double _barHeight = 64;
  static const double _optionsWidth = 380;

  final FocusNode _focusNode = FocusNode(debugLabel: 'live_play/controls');

  /// Remembered across hide/show, like the reference's index values.
  int _barIndex = 0;
  int _optionIndex = 0;
  _Zone _zone = _Zone.bar;
  _OptionsPanel _panel = _OptionsPanel.none;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // =========================
  // key handling (the reference's isConfirmKey set)
  // =========================

  static bool _isConfirm(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA;

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    final state = ref.read(livePlayControllerProvider(widget.args));
    final key = event.logicalKey;

    if (_isConfirm(key)) {
      _onSelect(state);
      return KeyEventResult.handled;
    }

    final TraversalDirection? direction = switch (key) {
      LogicalKeyboardKey.arrowLeft => TraversalDirection.left,
      LogicalKeyboardKey.arrowRight => TraversalDirection.right,
      LogicalKeyboardKey.arrowUp => TraversalDirection.up,
      LogicalKeyboardKey.arrowDown => TraversalDirection.down,
      _ => null,
    };
    if (direction == null) return KeyEventResult.ignored;

    _onDirection(direction, state);
    return KeyEventResult.handled;
  }

  void _onDirection(TraversalDirection direction, LivePlayState state) {
    final int barCount = _barActions(state).length;
    final int optionCount = _optionsWithBack(state).length;
    if (barCount == 0) return;

    // Any key keeps the controls on screen while the user is working them.
    ref.read(livePlayControllerProvider(widget.args).notifier).keepControlsAlive();

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
        if (optionCount == 0) {
          setState(() => _zone = _Zone.bar);
          return;
        }
        switch (direction) {
          case TraversalDirection.up:
            setState(() => _optionIndex = (_optionIndex - 1 + optionCount) % optionCount);
          case TraversalDirection.down:
            setState(() => _optionIndex = (_optionIndex + 1) % optionCount);
          case TraversalDirection.left:
            _closePanel();
          case TraversalDirection.right:
            break;
        }
    }
  }

  void _onSelect(LivePlayState state) {
    ref.read(livePlayControllerProvider(widget.args).notifier).keepControlsAlive();

    if (_zone == _Zone.options) {
      final options = _optionsWithBack(state);
      if (options.isEmpty) return;
      options[_optionIndex.clamp(0, options.length - 1)].apply();
      return;
    }

    final actions = _barActions(state);
    if (actions.isEmpty) return;
    actions[_barIndex.clamp(0, actions.length - 1)].onSelect();
  }

  // =========================
  // data
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
            (label: kLivePlayFitLabels[i], active: i == state.fitIndex, apply: () => _setFit(i)),
        ];
      case _OptionsPanel.none:
        return const <({String label, VoidCallback apply, bool active})>[];
    }
  }

  /// Options plus a leading 返回 entry: every overlay needs a visible way out,
  /// and in an index-driven UI that is a selectable row.
  List<({String label, VoidCallback apply, bool active})> _optionsWithBack(LivePlayState state) =>
      <({String label, VoidCallback apply, bool active})>[
        (label: i18nOr('ui_back', 'Back'), apply: _closePanel, active: false),
        ..._panelOptions(state),
      ];

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
        _OptionsPanel.quality => state.qualityIndex + 1,
        _OptionsPanel.line => state.lineIndex + 1,
        _OptionsPanel.fit => state.fitIndex + 1,
        _OptionsPanel.none => 0,
      };
    });
  }

  void _closePanel() => setState(() {
    _panel = _OptionsPanel.none;
    _zone = _Zone.bar;
  });

  /// Bottom bar, in the reference's order: 关注 / 刷新 / 播放暂停 / 弹幕 / 弹幕设置 /
  /// 清晰度 / 线路 / 比例 / 弹幕过滤 / 播放列表 / 房间信息 / 内核 / 切换房间 / 背景.
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
      // The reference ships these two as SVG; the same assets are used here.
      _PanelAction(
        asset: danmakuOn ? 'assets/images/video/danmu_open.svg' : 'assets/images/video/danmu_close.svg',
        label: danmakuOn ? i18n('ui_danmaku_on') : i18n('ui_danmaku_off'),
        active: danmakuOn,
        onSelect: () => danmakuNotifier.updateSettings(
          danmakuSettings.copyWith(enableDanmakuDisplay: !danmakuOn, hideDanmaku: danmakuOn),
        ),
      ),
      _PanelAction(
        asset: 'assets/images/video/danmu_setting.svg',
        label: i18n('danmaku_settings'),
        active: state.showSidePanel && state.panel == LivePlayPanel.danmakuSettings,
        onSelect: () => controller.togglePanel(LivePlayPanel.danmakuSettings),
      ),
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

  Future<void> _pickEngine() async {
    final engineKeys = PlayerConsts.engines.keys.toList(growable: false);
    final playerSettings = ref.read(playerSettingsControllerProvider);
    final String activeKey = PlayerConsts.engines.containsKey(playerSettings.videoPlayerKey)
        ? playerSettings.videoPlayerKey
        : PlayerConsts.defaultKey;

    // The dialog takes the keyboard while it is open, then the bar takes it back.
    _focusNode.unfocus();
    final String? key = await TvDialogUtils.showSelect<String>(
      context: context,
      title: i18n('kernel_switch'),
      selectedValue: activeKey,
      items: <TvSelectItem<String>>[
        for (final String k in engineKeys) TvSelectItem<String>(title: i18n(PlayerConsts.names[k] ?? k), value: k),
      ],
    );
    if (mounted) _focusNode.requestFocus();
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
    _focusNode.unfocus();
    final selected = await showRoomSwitchDialog(context, current: room);
    if (mounted) _focusNode.requestFocus();
    if (selected == null || !mounted) return;
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
    final options = _optionsWithBack(state);
    if (_barIndex >= actions.length) _barIndex = actions.isEmpty ? 0 : actions.length - 1;
    if (options.isNotEmpty && _optionIndex >= options.length) _optionIndex = options.length - 1;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Container(
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
            if (_panel != _OptionsPanel.none && options.isNotEmpty) _buildOptionsPanel(options, tvTheme),
            _buildBar(actions, tvTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsPanel(
    List<({String label, VoidCallback apply, bool active})> options,
    TvThemeData tvTheme,
  ) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.sp),
      child: Center(child: Container(
        width: _optionsWidth.sp,
        constraints: BoxConstraints(maxHeight: 560.sp),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(16.sp),
          border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(24.sp, 14.sp, 24.sp, 6.sp),
              child: Text(_panelTitle, style: AppTextStyles.t20W600.copyWith(color: Colors.white)),
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
                    child: _Pill(
                      label: option.label,
                      selected: selected,
                      accent: tvTheme.focusColor,
                      trailing: option.active ? Icons.check_rounded : null,
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      )),
    );
  }

  Widget _buildBar(List<_PanelAction> actions, TvThemeData tvTheme) {
    return Container(
      height: _barHeight.sp + 24.sp,
      alignment: Alignment.centerLeft,
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: actions.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.sp),
        itemBuilder: (context, index) {
          final action = actions[index];
          return _Pill(
            icon: action.icon,
            asset: action.asset,
            label: action.label,
            selected: _zone == _Zone.bar && index == _barIndex,
            accent: tvTheme.focusColor,
            tinted: action.active,
          );
        },
      ),
    );
  }
}

class _PanelAction {
  const _PanelAction({
    this.icon,
    this.asset,
    required this.label,
    required this.onSelect,
    this.active = false,
  }) : assert(icon != null || asset != null, 'A bar button needs an icon or an asset');

  final IconData? icon;

  /// SVG asset, for the buttons the reference ships as artwork (弹幕开关/弹幕设置).
  final String? asset;
  final String label;
  final VoidCallback onSelect;

  /// A state this button currently represents (followed, danmaku on, open panel).
  final bool active;
}

/// The reference's bottom-bar button: a pill that turns into the accent colour
/// with dark content when the index selects it, over a translucent white base.
class _Pill extends StatelessWidget {
  const _Pill({
    this.icon,
    this.asset,
    required this.label,
    required this.selected,
    required this.accent,
    this.tinted = false,
    this.trailing,
  });

  final IconData? icon;
  final String? asset;
  final String label;
  final bool selected;
  final Color accent;
  final bool tinted;
  final IconData? trailing;

  @override
  Widget build(BuildContext context) {
    // The same button as TvTabBar: a transparent pill that fills with the
    // accent colour only while the index is on it. Nothing else tints it, so a
    // button that merely represents an "on" state (弹幕开) is not coloured at
    // start-up — its label already says 开/关.
    final Color background = selected ? accent : Colors.transparent;
    final Color foreground = Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeInOut,
      height: 46.sp,
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 24.sp),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(23.sp)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (asset != null)
            SvgPicture.asset(asset!, width: 24.sp, height: 24.sp, colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn))
          else if (icon != null)
            Icon(icon, size: 24.sp, color: foreground),
          if (asset != null || icon != null) SizedBox(width: 8.sp),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: (selected ? AppTextStyles.t20W600 : AppTextStyles.t20).copyWith(color: foreground),
          ),
          if (trailing != null) ...[
            SizedBox(width: 8.sp),
            Icon(trailing, size: 22.sp, color: foreground),
          ],
        ],
      ),
    );
  }
}

/// Content colour on a filled accent pill, matching TvTabBar.
Color tvThemeFocusedCard(BuildContext context) => Theme.of(context).colorScheme.onPrimary;