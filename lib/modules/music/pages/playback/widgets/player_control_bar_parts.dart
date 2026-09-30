part of 'player_control_bar.dart';


/// Which part of the control layer the remote is steering.
enum _BarZone { bar, seek, options }

/// The value lists the bar can open above itself (the live player's
/// quality/line/fit/kernel panels).
enum _BarPanel { none, quality, kernel }

/// One bar button, data-driven like the live player's _PanelAction: the
/// highlight walks THIS list, so what is highlighted is always a button that
/// exists. The old bar carried a fixed 14-slot index while three of its
/// there.
class _BarAction {
  const _BarAction({required this.icon, required this.label, required this.onSelect, this.active = false});

  final IconData icon;
  final String label;
  final VoidCallback onSelect;

  /// A state this button currently represents (an open panel).
  final bool active;
}

/// Transport row + progress bar, steered by an index rather than by focus
/// traversal — the live player's control bar, in the music player's shape.
///
/// One [FocusNode] owns the keys and the highlighted item is drawn by
/// `selected:`, so what the viewer sees highlighted is exactly what OK
/// activates: no per-button focus ring to lose, and no d-pad hop that can land
/// on a button next to the one the ring was on.
class MusicControlBar extends ConsumerStatefulWidget {
  const MusicControlBar({super.key,
    required this.active,
    required this.activateInSeekZone,
    required this.onQueue,
    required this.onSettings,
    required this.onInteraction,
    required this.onPickLyric,
  });

  /// Whether the controls are on screen; becoming active takes the keyboard.
  final bool active;

  /// Consumed at activation: a seek-raised bar opens with the keyboard in the
  /// seek zone, so the following arrows keep seeking instead of walking rows.
  final bool activateInSeekZone;

  final VoidCallback onQueue;
  final VoidCallback onSettings;

  /// Every key the bar consumes re-arms the page's auto-hide countdown.
  final VoidCallback onInteraction;

  final VoidCallback onPickLyric;

  @override
  ConsumerState<MusicControlBar> createState() => MusicControlBarState();
}

class MusicControlBarState extends ConsumerState<MusicControlBar> {
  final FocusNode _node = FocusNode(debugLabel: 'music/controls');

  /// Remembered across hide/show, like the live player's index values.
  int _barIndex = 1;
  int _optionIndex = 0;
  _BarZone _zone = _BarZone.bar;
  _BarPanel _panel = _BarPanel.none;

  /// GlobalKeys so the highlighted pill can be revealed while the index walks
  /// the bar. The bar wraps to a second row at the largest font (a Wrap, not
  /// the live player's scrolling list), so the reveal is usually a no-op —
  /// but a narrow window can still overflow one row.
  final Map<int, GlobalKey> _barKeys = <int, GlobalKey>{};
  GlobalKey _barKey(int index) => _barKeys.putIfAbsent(index, GlobalKey.new);

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

  @override
  void initState() {
    super.initState();
    if (widget.active) _takeFocus();
  }

  @override
  void didUpdateWidget(MusicControlBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _zone = widget.activateInSeekZone ? _BarZone.seek : _BarZone.bar;
      _panel = _BarPanel.none;
      _takeFocus();
    }
    // An option list whose values vanished (a muxed fallback cleared the
    // rendition list) closes itself instead of steering a ghost.
    if (_panel != _BarPanel.none && _panelOptions().isEmpty) {
      _panel = _BarPanel.none;
      _zone = _BarZone.bar;
    }
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  void _takeFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active && !_node.hasFocus) _node.requestFocus();
    });
  }

  static bool _isConfirm(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (!mounted) return KeyEventResult.ignored;
    final key = event.logicalKey;
    widget.onInteraction();

    if (_isConfirm(key)) {
      _onSelect();
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

    // Up on the plain bar (no option list open) is the page's key: it opens
    // the queue — the layer above the bar, mirroring the live player, where
    // up on the plain bar bubbles to the page and switches rooms.
    if (_zone == _BarZone.bar && _panel == _BarPanel.none && direction == TraversalDirection.up) {
      return KeyEventResult.ignored;
    }

    _onDirection(direction);
    return KeyEventResult.handled;
  }

  void _onDirection(TraversalDirection direction) {
    final int barCount = _barActions().length;
    final int optionCount = _panelOptions().length;
    if (barCount == 0) return;
    if (_barIndex >= barCount) _barIndex = barCount - 1;

    switch (_zone) {
      case _BarZone.bar:
        switch (direction) {
          case TraversalDirection.left:
            setState(() => _barIndex = (_barIndex - 1 + barCount) % barCount);
            _revealBarSelection();
          case TraversalDirection.right:
            setState(() => _barIndex = (_barIndex + 1) % barCount);
            _revealBarSelection();
          case TraversalDirection.up:
            if (_panel != _BarPanel.none && optionCount > 0) {
              setState(() => _zone = _BarZone.options);
            }
          case TraversalDirection.down:
            setState(() => _zone = _BarZone.seek);
        }
      case _BarZone.seek:
        final controller = ref.read(musicPlayerControllerProvider.notifier);
        switch (direction) {
          case TraversalDirection.left:
            controller.seekAccelerated(-1);
          case TraversalDirection.right:
            controller.seekAccelerated(1);
          case TraversalDirection.up:
            setState(() => _zone = _BarZone.bar);
          case TraversalDirection.down:
            break;
        }
      case _BarZone.options:
        if (optionCount == 0) {
          _closePanel();
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

  void _onSelect() {
    if (_zone == _BarZone.options) {
      final options = _panelOptions();
      if (options.isEmpty) return;
      options[_optionIndex.clamp(0, options.length - 1)].apply();
      return;
    }
    if (_zone == _BarZone.seek) {
      setState(() => _zone = _BarZone.bar);
      return;
    }
    final actions = _barActions();
    if (actions.isEmpty) return;
    if (_barIndex >= actions.length) _barIndex = actions.length - 1;
    actions[_barIndex].onSelect();
  }

  // =========================
  // data
  // =========================

  /// The bar: transport, the quality/picture group, the queue and lyric
  /// entries, then the kernel and settings. The play-mode button lives in the
  /// settings panel now — a mode flip from a stray press reordered the whole
  /// queue's behaviour. The seek ±10s buttons are gone —
  /// the seek zone under the bar owns left/right with press acceleration,
  /// exactly like the live player, whose bar carries no seek buttons either.
  /// on the mini bar and the detail page, and they were what grew this bar to
  /// fourteen buttons.
  List<_BarAction> _barActions() {
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final state = ref.watch(musicPlayerControllerProvider);
    final bool playing = controller.handle?.isPlaying ?? false;

    return <_BarAction>[
      _BarAction(
        icon: Icons.skip_previous_rounded,
        label: i18n('music_prev'),
        onSelect: () => unawaited(controller.previous()),
      ),
      _BarAction(
        icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
        label: i18n(playing ? 'music_pause' : 'music_play'),
        onSelect: () => unawaited(controller.togglePlayPause()),
      ),
      _BarAction(
        icon: Icons.skip_next_rounded,
        label: i18n('music_next'),
        onSelect: () => unawaited(controller.next()),
      ),
      // Quality rides with the DASH answer: a muxed mp4 fallback offers no
      // rendition list, so the button only exists when there is one to pick —
      // the data-driven list simply carries one entry fewer.
      if (state.qualityOptions.isNotEmpty)
        _BarAction(
          icon: Icons.high_quality_rounded,
          label: BilibiliMusicApi.qualityLabel(state.quality),
          active: _panel == _BarPanel.quality,
          onSelect: () => _openPanel(_BarPanel.quality, state.quality),
        ),
      _BarAction(
        icon: state.audioOnly ? Icons.videocam_outlined : Icons.headphones_rounded,
        label: i18n(state.audioOnly ? 'music_video_on' : 'music_audio_only'),
        onSelect: () => unawaited(controller.toggleAudioOnly()),
      ),
      _BarAction(icon: Icons.queue_music_rounded, label: i18n('music_tab_queue'), onSelect: widget.onQueue),
      _BarAction(icon: Icons.lyrics_outlined, label: i18n('music_lyric_pick'), onSelect: widget.onPickLyric),
      _BarAction(
        icon: Icons.memory_rounded,
        label: _engineLabel(),
        active: _panel == _BarPanel.kernel,
        onSelect: () => _openPanel(_BarPanel.kernel, null),
      ),
      _BarAction(icon: Icons.settings_outlined, label: i18n('settings'), onSelect: widget.onSettings),
    ];
  }

  String _engineLabel() {
    final String key = MusicPlayerController.preferredBackend;
    return switch (key) {
      BackendIds.mediaKit => i18n('player_mpv'),
      BackendIds.fijk => i18n('player_ijk'),
      BackendIds.betterPlayer => i18nOr('player_better_player', 'Exo 播放器'),
      BackendIds.fvp => i18n('player_fvp'),
      _ => key,
    };
  }

  List<({String label, VoidCallback apply, bool active})> _panelOptions() {
    switch (_panel) {
      case _BarPanel.quality:
        final state = ref.watch(musicPlayerControllerProvider);
        return <({String label, VoidCallback apply, bool active})>[
          for (final option in state.qualityOptions)
            (
              label: BilibiliMusicApi.qualityLabel(option.quality),
              active: option.quality == state.quality,
              // The list stays open so the renditions can be compared, like
              // the live player's quality list.
              apply: () => unawaited(ref.read(musicPlayerControllerProvider.notifier).switchQuality(option.quality)),
            ),
        ];
      case _BarPanel.kernel:
        final String activeKey = MusicPlayerController.preferredBackend;
        return <({String label, VoidCallback apply, bool active})>[
          for (final String key in const [
            BackendIds.mediaKit,
            BackendIds.fijk,
            BackendIds.betterPlayer,
            BackendIds.fvp,
          ])
            (
              label: switch (key) {
                BackendIds.mediaKit => i18n('player_mpv'),
                BackendIds.fijk => i18n('player_ijk'),
                BackendIds.betterPlayer => i18nOr('player_better_player', 'Exo 播放器'),
                _ => i18n('player_fvp'),
              },
              active: key == activeKey,
              // Taking a kernel re-opens the stream: the list closes first,
              // like the live player's kernel list.
              apply: () {
                _closePanel();
                unawaited(ref.read(musicPlayerControllerProvider.notifier).switchBackend(key));
              },
            ),
        ];
      case _BarPanel.none:
        return const <({String label, VoidCallback apply, bool active})>[];
    }
  }

  void _openPanel(_BarPanel panel, int? currentQuality) {
    setState(() {
      _panel = panel;
      _zone = _BarZone.options;
      _optionIndex = switch (panel) {
        _BarPanel.quality => currentQuality == null
            ? 0
            : ref
                  .read(musicPlayerControllerProvider)
                  .qualityOptions
                  .indexWhere((option) => option.quality == currentQuality),
        _BarPanel.kernel => const [
          BackendIds.mediaKit,
          BackendIds.fijk,
          BackendIds.betterPlayer,
          BackendIds.fvp,
        ].indexOf(MusicPlayerController.preferredBackend),
        _BarPanel.none => 0,
      };
      if (_optionIndex < 0) _optionIndex = 0;
    });
  }

  void _closePanel() => setState(() {
    _panel = _BarPanel.none;
    _zone = _BarZone.bar;
  });

  static String _timeLabel(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final bool seekZone = _zone == _BarZone.seek;
    final actions = _barActions();
    final options = _panelOptions();
    if (_barIndex >= actions.length) _barIndex = actions.isEmpty ? 0 : actions.length - 1;
    if (options.isNotEmpty && _optionIndex >= options.length) _optionIndex = options.length - 1;

    return Focus(
      focusNode: _node,
      onKeyEvent: _onKey,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 18.sp),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(24.sp),
          border: Border.all(
            color: tvTheme.focusColor.withValues(alpha: seekZone ? 0.9 : 0.35),
            width: seekZone ? 2.sp : 1.sp,
          ),
        ),
        child: StreamBuilder<PlaybackState>(
          // One stream drives the whole bar: the progress row and the play/pause
          // glyph, which otherwise went stale until the next controller state
          // change.
          stream: ref.read(musicPlayerControllerProvider.notifier).playbackStream,
          builder: (context, snapshot) {
            final playback = snapshot.data;
            final position = playback?.position ?? Duration.zero;
            final duration = playback?.duration ?? Duration.zero;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_panel != _BarPanel.none && options.isNotEmpty)
                  Padding(
                    padding: EdgeInsets.only(bottom: 12.sp),
                    child: Container(
                      constraints: BoxConstraints(maxHeight: 480.sp),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(16.sp),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.fromLTRB(24.sp, 14.sp, 24.sp, 6.sp),
                            child: Text(
                              _panel == _BarPanel.quality ? i18n('music_quality') : i18n('music_core_title'),
                              style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              padding: EdgeInsets.only(bottom: 12.sp),
                              itemCount: options.length,
                              itemBuilder: (context, index) {
                                final option = options[index];
                                final bool selected = index == _optionIndex;
                                return Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
                                  child: _OptionPill(
                                    label: option.label,
                                    selected: selected,
                                    accent: tvTheme.focusColor,
                                    active: option.active,
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 120.sp),
                      child: Text(_timeLabel(position), style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white70)),
                    ),
                    SizedBox(width: 16.sp),
                    Expanded(
                      child: MusicProgressBar(
                        position: position,
                        duration: duration,
                        focused: seekZone,
                        onInteraction: widget.onInteraction,
                      ),
                    ),
                    SizedBox(width: 16.sp),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 120.sp),
                      child: Text(_timeLabel(duration), style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white70)),
                    ),
                  ],
                ),
                SizedBox(height: 16.sp),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12.sp,
                  runSpacing: 10.sp,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final (index, action) in actions.indexed)
                      _excluded(
                        KeyedSubtree(
                          key: _barKey(index),
                          child: TvButton(
                            title: action.label,
                            icon: Icon(action.icon, size: 22.sp),
                            size: TvButtonSize.mini,
                            isSecondary: !action.active,
                            selected: _zone == _BarZone.bar && _barIndex == index,
                            onTap: () => _activateAt(index),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// A tap highlights the button it hit and runs it, so the mouse and the
  /// remote can never disagree about what is selected.
  void _activateAt(int index) {
    if (mounted) {
      setState(() {
        _zone = _BarZone.bar;
        _panel = _BarPanel.none;
        _barIndex = index;
      });
    }
    widget.onInteraction();
    final actions = _barActions();
    if (index < actions.length) actions[index].onSelect();
  }

  /// The buttons draw the highlight but never take focus: one node owns the
  /// keys, and a d-pad hop can no longer land on a button next to the one the
  /// highlight was on. They stay tappable for a mouse.
  Widget _excluded(Widget child) => ExcludeFocus(child: child);
}

/// One row of an option list: the same focus recipe the app's standard
/// controls use (TvFocusStyle), with the value in force carrying a check.
class _OptionPill extends StatelessWidget {
  const _OptionPill({required this.label, required this.selected, required this.accent, required this.active});

  final String label;
  final bool selected;
  final Color accent;
  final bool active;

  @override
  Widget build(BuildContext context) {
    // The pill is padding-driven around a resolver-scaled t16 label; the check
    // glyph rides the same factor.
    final double scale = TvTextScale.factorOf(context);
    return AnimatedContainer(
      duration: TvFocusStyle.focusDuration(selected),
      curve: TvFocusStyle.curve,
      padding: EdgeInsets.symmetric(horizontal: 20.sp * scale, vertical: 10.sp * scale),
      decoration: BoxDecoration(
        color: selected ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12.sp),
        border: Border.all(color: selected ? accent : Colors.transparent, width: 2.sp),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: selected ? Colors.white : Colors.white70),
            ),
          ),
          if (active) ...[SizedBox(width: 8.sp * scale), Icon(Icons.check_rounded, size: 20.sp * scale, color: accent)],
        ],
      ),
    );
  }
}

/// The seek bar. It has no FocusNode of its own — the bar's index steers it, so
/// the highlight it draws is the zone the remote is in.
class MusicProgressBar extends StatelessWidget {
  const MusicProgressBar({super.key,
    required this.position,
    required this.duration,
    required this.focused,
    required this.onInteraction,
  });

  final Duration position;
  final Duration duration;
  final bool focused;
  final VoidCallback onInteraction;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final double progress = duration > Duration.zero
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: onInteraction,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: focused ? 22.sp : 16.sp,
        margin: EdgeInsets.symmetric(vertical: focused ? 6.sp : 10.sp),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(11.sp),
          border: Border.all(color: focused ? accent : Colors.white24, width: focused ? 2.sp : 1.sp),
        ),
        child: Stack(
          children: [
            FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                margin: EdgeInsets.all(3.sp),
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(8.sp),
                ),
              ),
            ),
            if (focused)
              Align(
                alignment: Alignment.lerp(Alignment.centerLeft, Alignment.centerRight, progress) ??
                    Alignment.centerLeft,
                child: Container(
                  width: 4.sp,
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
