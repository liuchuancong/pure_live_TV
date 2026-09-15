import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Builds the right-hand side of a [TvSettingsRow], with the live focus state.
typedef TvSettingsTrailingBuilder = Widget Function(BuildContext context, bool focused);

/// The shared shell of every settings row.
///
/// One definition keeps the navigation rows, switches, option cycles and
/// sliders visually identical: same padding, same palette colours, and the same
/// focus treatment — a border plus a tinted fill rather than a rounded card
/// chrome. Rows only differ in what they put in [trailingBuilder] (and, for a
/// slider, in [footer]).
class TvSettingsRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return DpadFocusable(
      autofocus: autofocus,
      onSelect: onSelect,
      onDirection: onDirection,
      builder: (context, state, child) {
        final bool focused = state.focused;
        final Color accent = tvTheme.focusColor;
        final bool hasLeading = leading != null || icon != null;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
          decoration: BoxDecoration(
            color: focused ? accent.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(14.sp),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (leading != null)
                    leading!
                  else if (icon != null)
                    Icon(icon, size: 30.sp, color: focused ? accent : tvTheme.primaryTextColor),
                  if (hasLeading) SizedBox(width: 16.sp),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.t22W600.copyWith(
                            color: focused ? accent : tvTheme.primaryTextColor,
                          ),
                        ),
                        if (subtitle != null) ...[
                          SizedBox(height: 4.sp),
                          Text(
                            subtitle!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t16W500.copyWith(
                              color: focused ? accent.withValues(alpha: 0.85) : tvTheme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  SizedBox(width: 12.sp),
                  trailingBuilder?.call(context, focused) ?? const SizedBox.shrink(),
                ],
              ),
              if (footer != null) ...[SizedBox(height: 10.sp), footer!],
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
    color: focused ? tvTheme.focusColor : tvTheme.secondaryTextColor,
  );
}

/// `‹ value ›` used by rows whose value is changed with Left/Right.
Widget tvSettingsValueStepper(BuildContext context, bool focused, String value) {
  final tvTheme = context.tvTheme;
  final Color accent = tvTheme.focusColor;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(Icons.chevron_left_rounded, size: 26.sp, color: focused ? accent : tvTheme.secondaryTextColor),
      SizedBox(width: 4.sp),
      ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 260.sp),
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: AppTextStyles.t20W600.copyWith(color: focused ? accent : tvTheme.primaryTextColor),
        ),
      ),
      SizedBox(width: 4.sp),
      Icon(Icons.chevron_right_rounded, size: 26.sp, color: focused ? accent : tvTheme.secondaryTextColor),
    ],
  );
}

/// Bordered on/off indicator, so the switch row matches the bordered row style
/// instead of using the Material switch chrome.
class TvSettingsSwitchIndicator extends StatelessWidget {
  const TvSettingsSwitchIndicator({super.key, required this.value, required this.focused});

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
          color: value ? on.withValues(alpha: focused ? 0.35 : 0.22) : Colors.transparent,
          border: Border.all(color: value ? on : off.withValues(alpha: 0.6), width: 2.sp),
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
