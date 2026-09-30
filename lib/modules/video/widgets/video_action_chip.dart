import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';

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

    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(horizontal: 16.ts(context), vertical: 10.ts(context)),
        decoration: BoxDecoration(
          color: active
              ? accent.withValues(alpha: 0.2)
              : focused
              ? tvTheme.focusedCardColor
              : tvTheme.cardColor,
          borderRadius: BorderRadius.circular(24.ts(context)),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22.ts(context), color: active ? accent : tvTheme.secondaryTextColor),
            SizedBox(width: 8.ts(context)),
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
