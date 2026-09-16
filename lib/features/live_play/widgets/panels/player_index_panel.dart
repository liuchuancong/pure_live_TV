import 'package:flutter_svg/flutter_svg.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';

/// One row of an index panel.
class PlayerPanelRow {
  const PlayerPanelRow({
    required this.label,
    this.subtitle,
    this.value,
    this.active = false,
    this.asset,
    this.icon,
  });

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
    this.footer,
    this.emptyHint,
    this.width = 400,
  });

  final String title;
  final List<PlayerPanelRow> rows;
  final int selectedIndex;

  /// Called when Up/Down move the highlight — the action only runs on OK.
  final ValueChanged<int> onSelectionChanged;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  /// Stepper rows (弹幕设置) adjust with Left/Right instead of closing.
  final ValueChanged<int>? onAdjustLeft;
  final ValueChanged<int>? onAdjustRight;
  final Widget? footer;
  final String? emptyHint;
  final double width;

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
  void _scrollToSelection() {
    if (!_scrollController.hasClients) return;
    const double rowExtent = 64;
    final double target = (widget.selectedIndex * rowExtent) - 120;
    _scrollController.animateTo(
      target.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
    );
  }

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
      if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.escape) widget.onClose();
      return KeyEventResult.handled;
    }

    if (_isConfirm(key)) {
      final int index = widget.selectedIndex.clamp(0, count - 1);
      if (_isBackRow(index)) {
        widget.onClose();
      } else {
        widget.onSelect(index - 1);
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
      if (widget.onAdjustLeft != null && !_isBackRow(index)) {
        widget.onAdjustLeft!(index - 1);
      } else {
        widget.onClose();
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      final int index = widget.selectedIndex.clamp(0, count - 1);
      if (widget.onAdjustRight != null && !_isBackRow(index)) widget.onAdjustRight!(index - 1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// The rendered list: a 返回 row first, so every panel has a visible way out
  /// and the remote always has a close target. Its index shifts the real rows by
  /// one.
  List<PlayerPanelRow> get _renderedRows => <PlayerPanelRow>[
        PlayerPanelRow(label: i18nOr('ui_back', 'Back'), icon: Icons.arrow_back_rounded),
        ...widget.rows,
      ];

  bool _isBackRow(int index) => index == 0;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final List<PlayerPanelRow> rows = _renderedRows;
    final int count = rows.length;
    final int selected = widget.selectedIndex.clamp(0, count - 1);

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _onKeyEvent,
      child: Container(
        width: widget.width.sp,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(16.sp),
          border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 14.sp, 20.sp, 6.sp),
              child: Text(
                widget.title,
                style: AppTextStyles.t20W600.copyWith(color: Colors.white),
              ),
            ),
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
                      itemBuilder: (context, index) => _PanelRow(
                        row: rows[index],
                        selected: index == selected,
                        accent: tvTheme.focusColor,
                      ),
                    ),
            ),
            if (widget.footer != null) widget.footer!,
            Padding(
              padding: EdgeInsets.fromLTRB(20.sp, 0, 20.sp, 12.sp),
              child: Text(
                widget.onAdjustLeft != null
                    ? i18nOr('ui_panel_keys_adjust', '↑↓ 选择 · ←→ 调整 · OK 确认')
                    : i18nOr('ui_panel_keys', '↑↓ 选择 · OK 确认 · ← 返回'),
                style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PanelRow extends StatelessWidget {
  const _PanelRow({required this.row, required this.selected, required this.accent});

  final PlayerPanelRow row;
  final bool selected;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final Color foreground = selected ? Colors.black : Colors.white;
    return Container(
      height: 60.sp,
      margin: EdgeInsets.symmetric(vertical: 3.sp),
      padding: EdgeInsets.symmetric(horizontal: 16.sp),
      decoration: BoxDecoration(
        color: selected
            ? accent
            : (row.active ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06)),
        borderRadius: BorderRadius.circular(10.sp),
      ),
      child: Row(
        children: [
          if (row.asset != null)
            Padding(
              padding: EdgeInsets.only(right: 10.sp),
              child: SvgOrIcon(asset: row.asset, icon: row.icon, color: foreground, size: 24.sp),
            )
          else if (row.icon != null)
            Padding(
              padding: EdgeInsets.only(right: 10.sp),
              child: Icon(row.icon, size: 24.sp, color: foreground),
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
                  style: AppTextStyles.t16W500.copyWith(color: foreground, fontWeight: FontWeight.w600),
                ),
                if (row.subtitle != null && row.subtitle!.isNotEmpty)
                  Text(
                    row.subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t14W500.copyWith(
                      color: selected ? Colors.black54 : Colors.white70,
                    ),
                  ),
              ],
            ),
          ),
          if (row.value != null) ...[
            SizedBox(width: 12.sp),
            Text(
              row.value!,
              style: AppTextStyles.t16W500.copyWith(color: foreground),
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
