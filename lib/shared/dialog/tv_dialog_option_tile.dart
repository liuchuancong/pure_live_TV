import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/theme/index.dart';

/// One option inside a dialog.
///
/// Dialogs used to render their entries as [TvButton]s. In a list those stretch
/// to the dialog's full width and draw as stadium bars, so the entries read as
/// blocks with no shape of their own. These are rounded rectangles instead —
/// radius [radius], a 1px outline and a filled background — with the accent fill
/// and white content on the row the user is on, which is the same highlight the
/// player's lists and the settings rows use.
///
/// Wrapped in a [DpadFocusable] because a modal dialog is steered with the
/// remote's focus traversal (the player's own key-driven panels are the
/// exception).
class TvDialogOptionTile extends StatelessWidget {
  const TvDialogOptionTile({
    super.key,
    required this.title,
    required this.onTap,
    this.selected = false,
    this.autofocus = false,
    this.subtitle,
    this.icon,
    this.trailing,
    this.showCheck = true,
    this.radius = 16,
  });

  final String title;
  final VoidCallback onTap;

  /// The value in force: it keeps the accent fill and a check mark, so the list
  /// shows what is selected even while the highlight is elsewhere.
  final bool selected;
  final bool autofocus;
  final String? subtitle;
  final Widget? icon;
  final Widget? trailing;

  /// Off for lists that mark their own state with [icon] (a multi-select list
  /// draws a filled/empty circle, so a second check mark would be noise).
  final bool showCheck;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return DpadFocusable(
      autofocus: autofocus,
      onSelect: onTap,
      builder: (context, state, child) {
        final bool focused = state.focused;
        final bool highlighted = focused || selected;
        final Color foreground = highlighted ? Colors.white : tvTheme.primaryTextColor;
        final Color muted = highlighted ? Colors.white70 : tvTheme.secondaryTextColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          curve: Curves.easeInOut,
          constraints: BoxConstraints(minHeight: 60.sp),
          padding: EdgeInsets.symmetric(horizontal: 20.sp, vertical: 10.sp),
          decoration: BoxDecoration(
            color: highlighted ? tvTheme.focusColor : tvTheme.subtleRowFill,
            borderRadius: BorderRadius.circular(radius.sp),
            border: Border.all(
              color: focused ? tvTheme.focusColor : tvTheme.secondaryTextColor.withValues(alpha: 0.25),
              width: 1.sp,
            ),
          ),
          child: Row(
            children: [
              if (icon != null) ...[
                IconTheme(data: IconThemeData(size: 24.sp, color: foreground), child: icon!),
                SizedBox(width: 14.sp),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t20W500.copyWith(color: foreground, fontWeight: FontWeight.w600),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty)
                      Text(
                        subtitle!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t16W500.copyWith(color: muted),
                      ),
                  ],
                ),
              ),
              if (trailing != null) ...[SizedBox(width: 12.sp), trailing!],
              if (selected && showCheck) ...[
                SizedBox(width: 12.sp),
                Icon(Icons.check_circle_rounded, size: 26.sp, color: foreground),
              ],
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
