import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/widgets/tv_focus_style.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

enum TvIconButtonSize { large, medium, small, mini }

/// Icon-only [TvButton].
///
/// Shares the button's surface/focus rules exactly — idle translucent
/// [TvThemeData.buttonSurface], focus/selected solid accent with
/// contrast-picked foreground — so an icon button next to a text button reads
/// as the same control. The old version hard-coded white foregrounds, which
/// sank into the light palettes' pale accents.
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

    return UnconstrainedBox(
      child: DpadFocusable(
        autofocus: autofocus,
        onSelect: onTap,
        effects: [
          ...TvFocusStyle.effects(activeTheme, borderRadius, scale: 1.08),
          DpadCustomEffect((context, state, child) {
            final isFocused = state.focused;

            late Color bgColor;
            late Color foregroundColor;

            // House style: icon buttons are white in every state and every
            // theme mode, matching TvButton.
            if (selected) {
              bgColor = activeTheme.focusColor;
              foregroundColor = Colors.white;
            } else if (isFocused && useFadedFocus) {
              bgColor = activeTheme.focusColor.withValues(alpha: 0.5);
              foregroundColor = Colors.white;
            } else if (isFocused) {
              bgColor = activeTheme.focusColor;
              foregroundColor = Colors.white;
            } else {
              bgColor = isSecondary
                  ? activeTheme.buttonSurface.withValues(alpha: 0.45)
                  : activeTheme.buttonSurface.withValues(alpha: activeTheme.isLight ? 0.85 : 0.75);
              foregroundColor = Colors.white;
            }

            return AnimatedContainer(
              duration: TvFocusStyle.duration,
              curve: TvFocusStyle.curve,
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
        child: Center(child: icon),
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
