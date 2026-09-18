import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Builds the right-hand side of a [TvSettingsRow], with the live focus state.
typedef TvSettingsTrailingBuilder =
    Widget Function(BuildContext context, bool focused);

/// The shared shell of every settings row.
///
/// One definition keeps the navigation rows, switches, option cycles and
/// sliders visually identical: same padding, same palette colours, and the same
/// focus treatment — a border plus a tinted fill rather than a rounded card
/// chrome. Rows only differ in what they put in [trailingBuilder] (and, for a
/// slider, in [footer]).
class TvSettingsRow extends StatefulWidget {
  const TvSettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailingBuilder,
    this.footer,
    this.onSelect,
    this.onDirection,
    this.autofocus = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Replaces [icon] when the row is identified by artwork or a swatch.
  final Widget? leading;

  final TvSettingsTrailingBuilder? trailingBuilder;

  /// Extra content below the title line, used by the slider row.
  final Widget? footer;

  final VoidCallback? onSelect;
  final DpadDirectionCallback? onDirection;
  final bool autofocus;

  @override
  State<TvSettingsRow> createState() => _TvSettingsRowState();
}

class _TvSettingsRowState extends State<TvSettingsRow> {
  /// The row's own stable focus node.
  ///
  /// `DpadFocusable` creates a fresh node on every rebuild, so a row whose
  /// value just changed through a dialog (选择解码器, 主题模式, ...) gets a new
  /// node while the dialog is closing — the node the dialog remembered, and the
  /// node the page's focus restorer remembered, both die, and the keyboard ends
  /// up on 返回 instead of back on the row. A state-owned node survives the
  /// rebuild, so both restores land where the user actually was.
  final FocusNode _focusNode = FocusNode(debugLabel: 'tv_settings_row');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return DpadFocusable(
      autofocus: widget.autofocus,
      focusNode: _focusNode,
      onSelect: widget.onSelect,
      onDirection: widget.onDirection,
      builder: (context, state, child) {
        final bool focused = state.focused;
        final Color accent = tvTheme.focusColor;
        final bool hasLeading = widget.leading != null || widget.icon != null;

        // Room-card focus treatment: the focused row fills with the palette's
        // focus surface, wears an accent ring and the same halo the room cards
        // glow with (no blur on light palettes), and its text flips to the
        // contrast-picked colours of that surface — instead of the old thin
        // border plus a faint accent tint.
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
          decoration: BoxDecoration(
            color: focused ? tvTheme.focusedCardColor : Colors.transparent,
            borderRadius: BorderRadius.circular(14.sp),
            border: Border.all(
              color: focused ? accent : Colors.transparent,
              width: 2.sp,
            ),
            boxShadow: focused
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: tvTheme.isLight ? 1.0 : 0.75),
                      blurRadius: tvTheme.isLight ? 0 : 18.sp,
                      spreadRadius: tvTheme.isLight ? 2.sp : 1.5.sp,
                    ),
                  ]
                : const <BoxShadow>[],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  // Give the value room, but never more than half the row: a
                  // long option (decoder names, loading styles) must not push
                  // the title out or spill past the row's edge.
                  final double trailingMaxWidth = constraints.maxWidth * 0.55;
                  // Single-line rows reserve the same content height as a
                  // title + subtitle row (title line + gap + subtitle line),
                  // so mixing both kinds inside one group keeps an even
                  // rhythm instead of alternating tall and squashed rows.
                  final double minContentHeight = 30.sp + 4.sp + 22.sp;
                  return Container(
                    constraints: BoxConstraints(minHeight: minContentHeight),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        if (widget.leading != null)
                          widget.leading!
                        else if (widget.icon != null)
                          Icon(
                            widget.icon,
                            size: 30.sp,
                            color: focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor,
                          ),
                        if (hasLeading) SizedBox(width: 16.sp),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.t22W600.copyWith(
                                  color: focused
                                      ? tvTheme.onFocusedCard
                                      : tvTheme.primaryTextColor,
                                ),
                              ),
                              if (widget.subtitle != null) ...[
                                SizedBox(height: 4.sp),
                                Text(
                                  widget.subtitle!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.t16W500.copyWith(
                                    color: focused
                                        ? tvTheme.onFocusedCardSecondary
                                        : tvTheme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        SizedBox(width: 12.sp),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: trailingMaxWidth,
                          ),
                          child:
                              widget.trailingBuilder?.call(context, focused) ??
                              const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (widget.footer != null) ...[SizedBox(height: 10.sp), widget.footer!],
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}

/// Chevron used by rows that open another page.
Widget tvSettingsChevron(BuildContext context, bool focused) {
  final tvTheme = context.tvTheme;
  return Icon(
    Icons.chevron_right_rounded,
    size: 30.sp,
    // The focused row fills with the palette's focus surface, so the chevron
    // wears that surface's ink — not the accent, which sits too close to it.
    color: focused ? tvTheme.onFocusedCard : tvTheme.secondaryTextColor,
  );
}

/// `value ›` used by rows whose value is picked from a list in a dialog.
///
/// The row deliberately does not step with Left/Right: a scrollable dialog
/// shows every alternative at once and leaves the horizontal keys for focus
/// traversal.
Widget tvSettingsValueLabel(BuildContext context, bool focused, String value) {
  final tvTheme = context.tvTheme;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: AppTextStyles.t20W600.copyWith(
              color: focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor,
            ),
          ),
        ),
      ),
      SizedBox(width: 8.sp),
      Icon(
        Icons.expand_more_rounded,
        size: 28.sp,
        color: focused ? tvTheme.onFocusedCard : tvTheme.secondaryTextColor,
      ),
    ],
  );
}

/// Bordered on/off indicator, so the switch row matches the bordered row style
/// instead of using the Material switch chrome.
class TvSettingsSwitchIndicator extends StatelessWidget {
  const TvSettingsSwitchIndicator({
    super.key,
    required this.value,
    required this.focused,
  });

  final bool value;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final Color on = tvTheme.focusColor;
    final Color off = tvTheme.secondaryTextColor;

    return SizedBox(
      width: 62.sp,
      height: 34.sp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: value
              ? on.withValues(alpha: focused ? 0.35 : 0.22)
              : Colors.transparent,
          border: Border.all(
            color: value ? on : off.withValues(alpha: 0.6),
            width: 2.sp,
          ),
          borderRadius: BorderRadius.circular(6.sp),
        ),
        padding: EdgeInsets.all(3.sp),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            width: 24.sp,
            decoration: BoxDecoration(
              color: value ? on : off.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3.sp),
            ),
          ),
        ),
      ),
    );
  }
}
