import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

enum TvIconButtonSize { large, medium, small, mini }

class TvIconButton extends StatelessWidget {
  final Widget icon;
  final TvIconButtonSize size;
  final VoidCallback? onTap;
  final bool autofocus;
  final bool isSecondary;
  final bool selected;
  final bool useFadedFocus;

  const TvIconButton({
    super.key,
    required this.icon,
    this.size = TvIconButtonSize.medium,
    this.onTap,
    this.autofocus = false,
    this.isSecondary = false,
    this.selected = false,
    this.useFadedFocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.tvTheme;
    final (boxSize, iconSize) = _getSizeConfig();
    final borderRadius = BorderRadius.circular(boxSize / 2);

    Widget finalIcon = icon;

    return UnconstrainedBox(
      child: DpadFocusable(
        autofocus: autofocus,
        onSelect: onTap,
        effects: [
          DpadScaleEffect(
            scale: 1.06,
            pressedScale: 0.98,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
          ),
          DpadGlowEffect(
            color: activeTheme.focusColor.withValues(alpha: 0.35),
            blurRadius: 2.w,
            spreadRadius: 2.0.w,
            borderRadius: borderRadius,
          ),
          DpadCustomEffect((context, state, child) {
            final isFocused = state.focused;

            late Color bgColor;
            late Color foregroundColor;

            if (selected) {
              bgColor = activeTheme.focusColor;
              foregroundColor = activeTheme.focusedCardColor;
            } else if (isFocused && useFadedFocus) {
              bgColor = activeTheme.focusColor.withValues(alpha: 0.5);
              foregroundColor = activeTheme.focusedCardColor;
            } else if (isFocused) {
              bgColor = activeTheme.focusColor;
              foregroundColor = activeTheme.focusedCardColor;
            } else {
              bgColor = isSecondary ? activeTheme.cardColor.withValues(alpha: 0.5) : activeTheme.cardColor;
              foregroundColor = isSecondary ? activeTheme.secondaryTextColor : activeTheme.primaryTextColor;
            }

            return AnimatedContainer(
              duration: const Duration(milliseconds: 100),
              curve: Curves.easeInOut,
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
              child: IconTheme(
                data: IconThemeData(size: iconSize, color: foregroundColor),
                child: child,
              ),
            );
          }),
        ],
        child: Center(child: finalIcon),
      ),
    );
  }

  (double, double) _getSizeConfig() {
    return switch (size) {
      TvIconButtonSize.large => (80.0.w, 40.0.w),
      TvIconButtonSize.medium => (64.0.w, 32.0.w),
      TvIconButtonSize.small => (50.0.w, 24.0.w),
      TvIconButtonSize.mini => (38.0.w, 18.0.w),
    };
  }
}
