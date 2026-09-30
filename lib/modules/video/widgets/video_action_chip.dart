import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// One interaction chip: a compact icon+label pill in the focused palette.
class VideoActionChip extends StatelessWidget {
  const VideoActionChip({super.key, required this.icon, required this.label, this.active = false, this.onTap});

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    // The chip's box is padding-driven and grows with its label; the glyph
    // rides the same factor instead of staying at its drafted pixels.
    final double scale = TvTextScale.factorOf(context);

    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(horizontal: 16.ts(context) * scale, vertical: 10.ts(context) * scale),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: 0.2)
              : focused
              ? tvTheme.focusedCardColor
              : tvTheme.cardColor,
          borderRadius: BorderRadius.circular(24.sp),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22.sp * scale, color: active ? accent : tvTheme.secondaryTextColor),
            SizedBox(width: 8.sp * scale),
            Text(
              label,
              style: AppTextStyles.t14.copyWith(
                fontWeight: FontWeight.w600,
                color: active ? accent : (focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
