import 'package:flutter_svg/flutter_svg.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/live_play/player_panel_layout.dart';

/// One row of an index panel.
class PlayerPanelRow {
  const PlayerPanelRow({required this.label, this.subtitle, this.value, this.active = false, this.asset, this.icon});

  final String label;
  final String? subtitle;

  /// Current value shown on the right (stepper rows) — the reference's
  /// `SettingsItemWidget` prints it next to the title.
  final String? value;
  final bool active;
  final String? asset;
  final IconData? icon;
}

/// A right-hand panel steered by a **selected index**, like the reference
/// player's side panels: one [Focus] owns the keys, Up/Down walk the list, OK
/// applies, Left closes (and adjusts the value on stepper rows).
///
/// No d-pad focusables, so nothing can steal the keys and the highlight is always
/// where the remote is.
class PlayerIndexPanel extends StatefulWidget {
  const PlayerIndexPanel({
    super.key,
    required this.title,
    required this.rows,
    required this.selectedIndex,
    required this.onSelectionChanged,
    required this.onSelect,
    required this.onClose,
    this.onAdjustLeft,
    this.onAdjustRight,
    this.rowBuilder,
    this.rowExtent,
    this.header,
    this.footer,
    this.emptyHint,
    this.width = 400,
    this.showCloseRow = true,
  });

  final String title;
  final List<PlayerPanelRow> rows;
  final int selectedIndex;

  /// Called when Up/Down move the highlight — the action only runs on OK.
  final ValueChanged<int> onSelectionChanged;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  /// Stepper rows (danmaku settings) adjust with Left/Right instead of closing.
  final ValueChanged<int>? onAdjustLeft;
  final ValueChanged<int>? onAdjustRight;

  /// Draws one row itself instead of the default label/value row, so a room list
  /// can keep its avatars and platform badges while this panel still owns the
  /// selection and the keys. [index] is the *real* row index; the close row is not
  /// passed here.
  final Widget Function(BuildContext context, int index, bool selected)? rowBuilder;

  /// Height of one row, margins included, when [rowBuilder] draws them.
  ///
  /// Must be the height the row widget really renders — the list uses it as its
  /// `itemExtent` and to decide how far to scroll, so a mismatch either squeezes
  /// the rows or walks the highlight off screen. Defaults to the panel's own
  /// label row.
  final double? rowExtent;

  /// Widget between the title and the list — the shield panel's phone QR
  /// lives here so it stays visible whatever the list length is.
  final Widget? header;

  final Widget? footer;
  final String? emptyHint;
  final double width;

  /// Appends the trailing close row.
  ///
  /// Off for every side panel the player ships (playlist, danmaku settings,
  /// shield): they are left with Back / Escape, which the key scope routes to the
  /// same close action, so their rows are content only. The bar's own option
  /// lists (clarity / line / aspect / kernel) still end with a close row — those
  /// are drawn by the control bar, not by this widget.
  final bool showCloseRow;

  @override
  State<PlayerIndexPanel> createState() => _PlayerIndexPanelState();
}

class _PlayerIndexPanelState extends State<PlayerIndexPanel> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'live_play/side-panel-index');
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
      _scrollToSelection();
    });
  }

  @override
  void didUpdateWidget(covariant PlayerIndexPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex != oldWidget.selectedIndex) _scrollToSelection();
    if (!_focusNode.hasFocus) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_focusNode.hasFocus) _focusNode.requestFocus();
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Keeps the highlighted row on screen while the user walks the list.
  ///
  /// The list only moves when the selected row would leave the visible band, and
  /// then just far enough to keep one whole row of context on that side. Walking
  /// down therefore reveals the next channel before the highlight reaches the
  /// edge, and the last row of a long list is still reachable.
  ///
  /// Two things this replaces, both of which lost the highlight: the previous
  /// version scrolled to `index * rowExtent - 120`, so every press restarted a
  /// 180 ms animation and a run of presses left the selection trailing off-screen;
  /// and it aimed at a fixed offset instead of the real viewport, which with a
  /// long list (history appended to the playlist) put the bottom rows below the
  /// fold.
  void _scrollToSelection() {
    if (!_scrollController.hasClients) return;

    final ScrollPosition position = _scrollController.position;
    final double viewport = position.viewportDimension;
    if (viewport <= 0) return;

    // One row of lead, so the row after the selected one stays visible.
    final double margin = _rowExtent;
    final double top = position.pixels;
    final double rowTop = _listPadding + widget.selectedIndex * _rowExtent;
    final double rowBottom = rowTop + _rowExtent;

    double? target;

    if (rowTop < top + margin) {
      target = rowTop - margin;
    } else if (rowBottom > top + viewport - margin) {
      target = rowBottom - viewport + margin;
    }

    if (target == null) return;

    _scrollController.animateTo(
      target.clamp(0, position.maxScrollExtent),
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
    );
  }

  /// Row height, including its margins, scaled by panel font size.
  ///
  /// Panels whose rows are drawn by a `rowBuilder` pass [rowExtent] instead: the
  /// playlist's room rows are taller than a plain label row, and the height has to
  /// match what the row widget actually renders or the highlight drifts a little
  /// further out of view with every step.
  double get _rowExtent => widget.rowExtent ?? (66 * PlayerPanelLayout.fontSize).sp;

  /// Top padding of the row list, matching the [ListView] below.
  double get _listPadding => 4.sp;

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
    final int count = _renderedRows.length;
    final LogicalKeyboardKey key = event.logicalKey;

    if (count == 0) {
      if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.escape) {
        widget.onClose();
      }
      return KeyEventResult.handled;
    }

    if (_isConfirm(key)) {
      final int index = widget.selectedIndex.clamp(0, count - 1);
      if (_isCloseRow(index)) {
        widget.onClose();
      } else {
        widget.onSelect(index);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      widget.onSelectionChanged((widget.selectedIndex - 1 + count) % count);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      widget.onSelectionChanged((widget.selectedIndex + 1) % count);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      // Stepper panels adjust; list panels close, as in the reference.
      final int index = widget.selectedIndex.clamp(0, count - 1);
      if (widget.onAdjustLeft != null && !_isCloseRow(index)) {
        widget.onAdjustLeft!(index);
      } else {
        widget.onClose();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      final int index = widget.selectedIndex.clamp(0, count - 1);
      if (widget.onAdjustRight != null && !_isCloseRow(index)) {
        widget.onAdjustRight!(index);
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The rendered list: the rows, then a close row when
  /// [PlayerIndexPanel.showCloseRow] is on. It used to be a back row *first*,
  /// which shifted every real row's index by one.
  List<PlayerPanelRow> get _renderedRows => <PlayerPanelRow>[
    ...widget.rows,
    if (widget.showCloseRow) PlayerPanelRow(label: i18nOr('close', '关闭'), icon: Icons.close_rounded),
  ];

  bool _isCloseRow(int index) => index == widget.rows.length;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final double scale = PlayerPanelLayout.fontSize;
    final List<PlayerPanelRow> rows = _renderedRows;
    final int count = rows.length;
    // count can be 0 now that panels may hide the close row (an empty shield
    // word list, for one) — clamp only against a real range.
    final int selected = count == 0 ? 0 : widget.selectedIndex.clamp(0, count - 1);

    return ValueListenableBuilder<int>(
      // panel font size/panel position are read from preferences, so the panel rebuilds when the
      // stepper inside it changes one of them.
      valueListenable: PlayerPanelLayout.revision,
      builder: (context, _, _) => Focus(
        focusNode: _focusNode,
        autofocus: true,
        onKeyEvent: _onKeyEvent,
        child: SizedBox(
          width: widget.width.sp,
          // No decoration of its own: the host container (live_play page's
          // side-panel frame) paints the surface and the single border. A
          // border here too drew two frames one inside the other.
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(20.sp, 14.sp, 20.sp, 6.sp),
                child: Text(
                  widget.title,
                  style: AppTextStyles.t20W600.copyWith(color: tvTheme.primaryTextColor, fontSize: 20.sp * scale),
                ),
              ),
              if (widget.header != null) widget.header!,
              Expanded(
                child: rows.isEmpty
                    ? Center(
                        child: Text(
                          widget.emptyHint ?? i18nOr('ui_empty', 'Empty'),
                          style: AppTextStyles.t16W500.copyWith(color: tvTheme.secondaryTextColor),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 4.sp),
                        itemCount: rows.length,
                        // Every row is exactly this tall, so the list knows its own
                        // scroll extent instead of estimating it from the children it
                        // has built — an estimate that left the last rows of a long
                        // playlist below the fold and out of reach.
                        itemExtent: _rowExtent,
                        itemBuilder: (context, index) {
                          final bool isSelected = index == selected;
                          final Widget? custom = index < widget.rows.length
                              ? widget.rowBuilder?.call(context, index, isSelected)
                              : null;
                          return custom ??
                              _PanelRow(
                                row: rows[index],
                                selected: isSelected,
                                accent: tvTheme.focusColor,
                                theme: tvTheme,
                                scale: scale,
                              );
                        },
                      ),
              ),
              if (widget.footer != null) widget.footer!,
              Padding(
                padding: EdgeInsets.fromLTRB(20.sp, 0, 20.sp, 12.sp),
                child: Text(
                  widget.onAdjustLeft != null
                      ? i18nOr('ui_panel_keys_adjust', '↑↓ 选择 · ←→ 调整 · OK 确认')
                      : i18nOr('ui_panel_keys', '↑↓ 选择 · OK 确认 · ← 返回'),
                  style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor, fontSize: 14.sp * scale),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PanelRow extends StatelessWidget {
  const _PanelRow({
    required this.row,
    required this.selected,
    required this.accent,
    required this.theme,
    required this.scale,
  });

  final PlayerPanelRow row;
  final bool selected;
  final Color accent;
  final TvThemeData theme;
  final double scale;

  @override
  Widget build(BuildContext context) {
    // The selected row keeps white content in both palettes: it sits on the
    // accent fill, where the theme's own text colours (dark on a light palette)
    // would be unreadable — danmaku settings used to paint its focused row black.
    final Color foreground = selected ? Colors.white : theme.primaryTextColor;
    final Color muted = selected ? Colors.white70 : theme.secondaryTextColor;
    return Container(
      height: (60 * scale).sp,
      margin: EdgeInsets.symmetric(vertical: (3 * scale).sp),
      padding: EdgeInsets.symmetric(horizontal: 16.sp),
      decoration: BoxDecoration(
        color: selected ? accent : (row.active ? accent.withValues(alpha: 0.22) : theme.subtleRowFill),
        borderRadius: BorderRadius.circular(10.sp),
      ),
      child: Row(
        children: [
          if (row.asset != null)
            Padding(
              padding: EdgeInsets.only(right: 10.sp),
              child: SvgOrIcon(asset: row.asset, icon: row.icon, color: foreground, size: 24.sp * scale),
            )
          else if (row.icon != null)
            Padding(
              padding: EdgeInsets.only(right: 10.sp),
              child: Icon(row.icon, size: 24.sp * scale, color: foreground),
            ),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t16W500.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w600,
                    fontSize: 16.sp * scale,
                  ),
                ),
                if (row.subtitle != null && row.subtitle!.isNotEmpty)
                  Text(
                    row.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t14W500.copyWith(color: muted, fontSize: 14.sp * scale),
                  ),
              ],
            ),
          ),
          if (row.value != null) ...[
            SizedBox(width: 12.sp),
            Text(
              row.value!,
              style: AppTextStyles.t16W500.copyWith(color: foreground, fontSize: 16.sp * scale),
            ),
          ],
        ],
      ),
    );
  }
}

/// Small helper so a row can use either an SVG asset or a Material icon.
class SvgOrIcon extends StatelessWidget {
  const SvgOrIcon({super.key, this.asset, this.icon, required this.color, required this.size});

  final String? asset;
  final IconData? icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (asset != null) {
      return SvgPicture.asset(asset!, width: size, height: size, colorFilter: ColorFilter.mode(color, BlendMode.srcIn));
    }
    return Icon(icon, size: size, color: color);
  }
}
