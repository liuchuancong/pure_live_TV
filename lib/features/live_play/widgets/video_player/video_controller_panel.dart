import 'dart:async';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/player/index.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/tv_focus_style.dart';
import 'package:pure_live/shared/widgets/app_status_view.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/features/live_play/dialogs/room_switch_dialog.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';

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
/// most reachable slots are better used by quality and line.
class VideoControllerPanel extends ConsumerStatefulWidget {
  final LivePlayArgs args;

  const VideoControllerPanel({super.key, required this.args});

  @override
  ConsumerState<VideoControllerPanel> createState() => _VideoControllerPanelState();
}

/// Which side of the layer the remote is steering.
enum _Zone { bar, options }

/// The option list shown next to the bar, if any.
enum _OptionsPanel { none, quality, line, fit, kernel }

class _VideoControllerPanelState extends ConsumerState<VideoControllerPanel> {
  static const double _barHeight = 52;
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
    // The focus system can still route a key here after this panel left the
    // tree (unmount races the dispatch); running actions then mutates
    // providers with a defunct listener and throws.
    if (!mounted) return KeyEventResult.ignored;
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
    final int optionCount = _optionsWithClose(state).length;
    if (barCount == 0) return;

    // Any key keeps the controls on screen while the user is working them.
    ref.read(livePlayControllerProvider(widget.args).notifier).keepControlsAlive();

    switch (_zone) {
      case _Zone.bar:
        switch (direction) {
          case TraversalDirection.left:
            setState(() => _barIndex = (_barIndex - 1 + barCount) % barCount);
            _revealBarSelection();
          case TraversalDirection.right:
            setState(() => _barIndex = (_barIndex + 1) % barCount);
            _revealBarSelection();
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
      final options = _optionsWithClose(state);
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

  String _fitLabel(LivePlayState state) => kLivePlayFitLabels[state.fitIndex.clamp(0, kLivePlayFitLabels.length - 1)];

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
      case _OptionsPanel.kernel:
        // The kernels are a list like every other value picker: the bar used to
        // open a modal dialog here, which was the one list in the player without
        // a close row (and the only one that did not live next to the bar).
        final String activeKey = _activeEngineKey();
        return <({String label, VoidCallback apply, bool active})>[
          for (final String key in PlayerConsts.engines.keys)
            (
              label: i18n(PlayerConsts.names[key] ?? key),
              active: key == activeKey,
              apply: () => unawaited(_switchKernel(key)),
            ),
        ];
      case _OptionsPanel.none:
        return const <({String label, VoidCallback apply, bool active})>[];
    }
  }

  /// The options with a close row last: the list is a selectable index list, so
  /// its way out is a row like any other — at the bottom, where the eye ends up
  /// after walking the list.
  List<({String label, VoidCallback apply, bool active})> _optionsWithClose(LivePlayState state) =>
      <({String label, VoidCallback apply, bool active})>[..._panelOptions(state)];

  String get _panelTitle => switch (_panel) {
    _OptionsPanel.quality => i18n('recorder_stage_quality'),
    _OptionsPanel.line => i18n('multiview_line_selector'),
    _OptionsPanel.fit => i18n('ui_aspect_ratio'),
    _OptionsPanel.kernel => i18n('kernel_switch'),
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
        // Open on the kernel that is in use, so OK on the row the list opens on
        // is the reset the user is looking for.
        _OptionsPanel.kernel => PlayerConsts.engines.keys.toList(growable: false).indexOf(_activeEngineKey()),
        _OptionsPanel.none => 0,
      };
    });
  }

  /// The kernel key actually in force: the stored one, or the default when the
  /// stored key is unknown to this build.
  String _activeEngineKey() {
    final String stored = ref.read(playerSettingsControllerProvider).videoPlayerKey;
    return PlayerConsts.engines.containsKey(stored) ? stored : PlayerConsts.defaultKey;
  }

  void _closePanel() => setState(() {
    _panel = _OptionsPanel.none;
    _zone = _Zone.bar;
  });

  /// Bottom bar: the transport, the danmaku group (toggle/settings/filter), the
  /// three value pickers, then the channel actions.
  ///
  /// background settings was dropped — it is a settings-page concern, and the bar had grown
  /// to fourteen buttons, so related items drifted apart.
  List<_PanelAction> _barActions(LivePlayState state) {
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    final danmakuSettings = ref.watch(danmakuSettingsControllerProvider);
    final danmakuNotifier = ref.read(danmakuSettingsControllerProvider.notifier);
    final playerSettings = ref.watch(playerSettingsControllerProvider);
    final playerNotifier = ref.read(playerSettingsControllerProvider.notifier);
    final favoriteRooms = ref.watch(favoriteRoomControllerProvider).favoriteRooms;
    final room = state.room;
    final bool playing = state.playerState.playing || state.playerState.buffering;
    final bool isFavorite = room != null && favoriteRooms.any((item) => item.hasSameIdentity(room));
    final bool danmakuOn = danmakuSettings.enableDanmakuDisplay && !danmakuSettings.hideDanmaku;
    final bool audioOnly = playerSettings.audioOnly;

    return <_PanelAction>[
      _PanelAction(
        icon: isFavorite ? Icons.favorite : Icons.favorite_border,
        label: isFavorite ? i18n('followed') : i18n('follow'),
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
      _PanelAction(
        icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        label: playing ? i18n('multiview_pause') : i18n('multiview_play'),
        onSelect: controller.togglePlayPause,
      ),
      _PanelAction(icon: Icons.refresh_rounded, label: i18n('retry'), onSelect: controller.retry),
      // danmaku toggle / danmaku settings / danmaku filter stay adjacent.
      _PanelAction(
        asset: danmakuOn ? 'assets/images/video/danmu_open.svg' : 'assets/images/video/danmu_close.svg',
        label: danmakuOn ? i18n('ui_danmaku_on') : i18n('ui_danmaku_off'),
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
        icon: Icons.dynamic_feed_rounded,
        label: i18n('danmaku_filter'),
        active: state.showSidePanel && state.panel == LivePlayPanel.shield,
        onSelect: () => controller.togglePanel(LivePlayPanel.shield),
      ),
      _PanelAction(
        icon: Icons.high_quality_rounded,
        label: _qualityLabel(state),
        active: _panel == _OptionsPanel.quality,
        loading: state.switchingStream,
        onSelect: () => _openPanel(_OptionsPanel.quality, state),
      ),
      _PanelAction(
        icon: Icons.density_small_rounded,
        label: i18n('multiview_line', args: {'index': '${state.lineIndex + 1}'}),
        active: _panel == _OptionsPanel.line,
        loading: state.switchingStream,
        onSelect: () => _openPanel(_OptionsPanel.line, state),
      ),
      _PanelAction(
        icon: Icons.video_settings_outlined,
        label: _fitLabel(state),
        active: _panel == _OptionsPanel.fit,
        onSelect: () => _openPanel(_OptionsPanel.fit, state),
      ),
      // Audio-only mode: the surface swaps the picture for the room card while
      // the stream keeps playing. The button writes the same setting the
      // settings page does — the live controller pushes that field into the
      // player — so the two can never disagree about which mode is on.
      _PanelAction(
        icon: audioOnly ? Remix.headphone_line : Remix.tv_2_line,
        label: audioOnly ? i18n('ui_audio_only') : i18n('ui_video_mode'),
        onSelect: () => playerNotifier.updateSettings(playerSettings.copyWith(audioOnly: !audioOnly)),
      ),
      _PanelAction(
        icon: Icons.swap_horiz_rounded,
        label: i18n('switch_live_room'),
        onSelect: () => unawaited(_switchRoom(state.room)),
      ),
      _PanelAction(
        icon: Icons.memory_rounded,
        label: _engineLabel(),
        active: _panel == _OptionsPanel.kernel,
        onSelect: () => _openPanel(_OptionsPanel.kernel, state),
      ),
    ];
  }

  /// GlobalKeys so the highlighted button can be revealed while the index walks
  /// the bar (the bar scrolls horizontally and the remote never scrolls it).
  final Map<int, GlobalKey> _barKeys = <int, GlobalKey>{};
  GlobalKey _barKey(int index) => _barKeys.putIfAbsent(index, () => GlobalKey());

  void _revealBarSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? context = _barKeys[_barIndex]?.currentContext;
      if (context == null) return;
      // Zero duration on purpose: the d-pad layer snaps scrolling, and an
      // animated reveal races with it.
      Scrollable.ensureVisible(context, duration: Duration.zero);
    });
  }

  /// Switches the kernel from the bar's index list.
  ///
  /// The list closes first: taking a kernel restarts the stream, so leaving the
  /// list open over a reloading player helps nobody — unlike quality/line/aspect ratio,
  /// where staying in the list is how you compare the options. The list still
  /// carries a close row at the bottom, like the others.
  ///
  /// Every pick is a real switch: PlayerManager hard-disposes the player that is
  /// running (`hardDispose()` on the current adapter, then the pool is asked for
  /// a replacement), so taking the kernel that is already active restarts the
  /// player instead of doing nothing — which is what a stuck picture needs.
  Future<void> _switchKernel(String key) async {
    _closePanel();
    final playerSettings = ref.read(playerSettingsControllerProvider);
    ref.read(livePlayControllerProvider(widget.args).notifier).keepControlsAlive();
    ref.read(playerSettingsControllerProvider.notifier).updateSettings(playerSettings.copyWith(videoPlayerKey: key));

    final engine = PlayerConsts.engines[key];
    final service = GlobalPlayerService.instance;
    if (engine == null || !service.initialized) return;

    try {
      await service.livePlayer?.switchEngine(engine, isManual: true);
    } catch (error, stackTrace) {
      debugPrint('Switch player kernel to $key failed: $error\n$stackTrace');
    }
  }

  Future<void> _switchRoom(LiveRoom? room) async {
    if (room == null) return;
    _focusNode.unfocus();
    final picked = await showRoomSwitchDialog(context, current: room);
    if (mounted) _focusNode.requestFocus();
    if (picked == null || !mounted) return;
    // Switching rooms is not switching context: the session keeps the playlist it
    // was opened with (the entry page's list plus history), so a room taken from
    // the followed tab does not silently turn the playlist into the followed list.
    final rooms = ref.read(livePlayControllerProvider(widget.args).notifier).channelRooms;
    LivePlayRoute(LivePlayArgs.fromRoom(picked, playlist: rooms, showChannelBanner: true)).replace(context);
  }

  // =========================
  // build
  // =========================

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livePlayControllerProvider(widget.args));
    final tvTheme = context.tvTheme;
    final actions = _barActions(state);
    final options = _optionsWithClose(state);
    if (_barIndex >= actions.length) {
      _barIndex = actions.isEmpty ? 0 : actions.length - 1;
    }
    if (options.isNotEmpty && _optionIndex >= options.length) {
      _optionIndex = options.length - 1;
    }

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Container(
        decoration: BoxDecoration(
          // A black gradient so the pills never fight the live picture: solid
          // enough at the bar itself, fading out over the options area above.
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.82), Colors.black.withValues(alpha: 0.0)],
            stops: const [0.0, 0.72],
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_panel != _OptionsPanel.none && options.isNotEmpty)
              _buildOptionsPanel(options, tvTheme, switching: state.switchingStream),
            _buildBar(actions, tvTheme),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsPanel(
    List<({String label, VoidCallback apply, bool active})> options,
    TvThemeData tvTheme, {
    required bool switching,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.sp),
      child: Center(
        child: Container(
          width: _optionsWidth.sp,
          constraints: BoxConstraints(maxHeight: 560.sp),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(16.sp),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 18.sp, offset: Offset(0, 4.sp)),
            ],
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
                        // The row being applied carries the ring; the list stays
                        // open so the options can still be compared.
                        loading: switching && option.active,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBar(List<_PanelAction> actions, TvThemeData tvTheme) {
    return Container(
      // A touch taller than the pills need, so the black band reads as the
      // bar's own ground rather than a tight box around the pills.
      height: _barHeight.sp + 32.sp,
      alignment: Alignment.center,
      // The band under the pills: live content above it stays clean, the
      // buttons always sit on black.
      color: Colors.black.withValues(alpha: 0.55),
      padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 16.sp),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: actions.length,
        separatorBuilder: (_, _) => SizedBox(width: 12.sp),
        itemBuilder: (context, index) {
          final action = actions[index];
          return KeyedSubtree(
            key: _barKey(index),
            child: _Pill(
              icon: action.icon,
              asset: action.asset,
              label: action.label,
              selected: _zone == _Zone.bar && index == _barIndex,
              accent: tvTheme.focusColor,
              tinted: action.active,
              loading: action.loading,
            ),
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
    this.loading = false,
  }) : assert(icon != null || asset != null, 'A bar button needs an icon or an asset');

  final IconData? icon;

  /// SVG asset, for the buttons the reference ships as artwork (danmaku toggle/danmaku settings).
  final String? asset;
  final String label;
  final VoidCallback onSelect;

  /// A state this button currently represents (followed, danmaku on, open panel).
  final bool active;

  /// A value this button offers is being applied right now (quality/line
  /// switching). The button swaps its glyph for a small ring instead of anything
  /// happening over the picture.
  final bool loading;
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
    this.loading = false,
  });

  // Pill geometry lives here so the bar can be retuned in one place.
  static const double _height = 52;
  static const double _hPadding = 18;
  static const double _gap = 8;
  static const double _iconSize = 24;
  static const double _trailingSize = 22;

  final IconData? icon;
  final String? asset;
  final String label;
  final bool selected;
  final Color accent;
  final bool tinted;
  final IconData? trailing;

  /// Replaces the glyph with a small ring: the value is being applied, the
  /// picture and the rest of the bar are untouched.
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final Color background = selected ? accent : Colors.transparent;
    final Color foreground = Colors.white;
    // The ring has to read on both the accent-filled and the translucent pill.
    final Color loadingColor = selected ? Colors.white : accent;

    // Bigger than the t20 the bar started with — the label is what the viewer
    // actually reads from the couch, so it should not be the smallest thing on
    // the pill.
    final TextStyle textStyle = (selected ? AppTextStyles.t20W600 : AppTextStyles.t20).copyWith(
      color: foreground,
      fontSize: 22.sp,
    );

    // The same focus recipe the app's standard controls use (TvFocusStyle):
    // a lift, an accent ring and a soft accent halo, so the bar's buttons glow
    // like the home page's back/menu buttons instead of only changing fill.
    final BorderRadius radius = BorderRadius.circular((_height / 3).sp);

    return AnimatedScale(
      scale: selected ? 1.05 : 1.0,
      duration: TvFocusStyle.focusDuration(selected),
      curve: TvFocusStyle.curve,
      child: AnimatedContainer(
        duration: TvFocusStyle.focusDuration(selected),
        curve: TvFocusStyle.curve,
        height: _height.sp,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: _hPadding.sp),
        decoration: BoxDecoration(
          color: background,
          borderRadius: radius,
          // No ring and no halo: a BoxDecoration border insets the fill by its
          // width, so even a transparent 2.5sp ring showed the dark bar through
          // as a black edge around the selected pill. The solid accent fill
          // plus the scale lift is the whole selected treatment.
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              tvInlineLoading(context, size: _iconSize.sp, color: loadingColor)
            else if (asset != null)
              SvgPicture.asset(
                asset!,
                width: _iconSize.sp,
                height: _iconSize.sp,
                colorFilter: ColorFilter.mode(foreground, BlendMode.srcIn),
              )
            else if (icon != null)
              Icon(icon, size: _iconSize.sp, color: foreground),
            if (loading || asset != null || icon != null) SizedBox(width: _gap.sp),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: textStyle),
            if (trailing != null) ...[
              SizedBox(width: _gap.sp),
              Icon(trailing, size: _trailingSize.sp, color: foreground),
            ],
          ],
        ),
      ),
    );
  }
}

/// Content colour on a filled accent pill, matching TvTabBar.
Color tvThemeFocusedCard(BuildContext context) => Theme.of(context).colorScheme.onPrimary;
