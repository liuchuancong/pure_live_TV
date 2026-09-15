import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Settings row that opens another page.
///
/// A navigation row intentionally does not react to Left/Right. The settings
/// catalog is a list of these rows only; the previous layout mixed them with
/// value rows that consumed Left/Right, so once focus landed in the settings
/// content it could not be moved back out to the module list.
class TvSettingsNavTile extends StatelessWidget {
  const TvSettingsNavTile({
    super.key,
    required this.title,
    required this.icon,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return DpadFocusable(
      onSelect: onTap,
      builder: (context, state, child) {
        final bool focused = state.focused;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
          decoration: BoxDecoration(
            color: focused ? tvTheme.focusColor.withValues(alpha: 0.22) : Colors.transparent,
            borderRadius: BorderRadius.circular(14.sp),
            border: Border.all(color: focused ? tvTheme.focusColor : Colors.transparent, width: 2.sp),
          ),
          child: Row(
            children: [
              Icon(icon, size: 30.sp, color: focused ? tvTheme.focusColor : tvTheme.primaryTextColor),
              SizedBox(width: 16.sp),
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
                        color: focused ? tvTheme.focusColor : tvTheme.primaryTextColor,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 4.sp),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t16W500.copyWith(
                          color: focused
                              ? tvTheme.focusColor.withValues(alpha: 0.85)
                              : tvTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 12.sp),
              Icon(
                Icons.chevron_right_rounded,
                size: 30.sp,
                color: focused ? tvTheme.focusColor : tvTheme.secondaryTextColor,
              ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}

/// Small coloured heading above a group of [TvSettingsNavTile]s.
class TvSettingsGroupTitle extends StatelessWidget {
  const TvSettingsGroupTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(left: 8.sp, bottom: 8.sp),
      child: Text(
        title,
        style: AppTextStyles.t16W600.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary.withValues(alpha: 0.65),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
