import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/tv_focus_style.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

enum TvIconButtonSize { large, medium, small, mini }

/// Icon-only [TvButton], optionally captioned.
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

  /// A short caption painted under the icon, for callers whose icons alone are
  /// ambiguous (the collapsed home sidebar names each destination with two
  /// characters).
  ///
  /// The caption sits inside the same focus surface, which grows downwards by
  /// one line; without a label the button stays the square icon-only control
  /// every other caller expects.
  final String? label;

  /// The node the button focuses by; owned by the caller when given (the home
  /// sidebar names its items' nodes so the opening highlight can pick one).
  final FocusNode? focusNode;

  const TvIconButton({
    super.key,
    required this.icon,
    this.size = TvIconButtonSize.medium,
    this.onTap,
    this.autofocus = false,
    this.isSecondary = false,
    this.selected = false,
    this.useFadedFocus = false,
    this.label,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.tvTheme;
    final (boxSize, iconSize) = _getSizeConfig();
    final bool captioned = label != null && label!.trim().isNotEmpty;
    final double boxHeight = captioned ? boxSize + _captionBlock.sp : boxSize;
    // A caption turns the circle into a rounded tile: text needs a flat edge to
    // sit on, and a full-radius pill with a caption reads as a lopsided circle.
    final borderRadius = BorderRadius.circular(captioned ? 16.sp : boxSize / 2);

    return UnconstrainedBox(
      child: DpadFocusable(
        autofocus: autofocus,
        focusNode: focusNode,
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
              duration: TvFocusStyle.focusDuration(isFocused),
              curve: TvFocusStyle.curve,
              width: boxSize,
              height: boxHeight,
              decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
              child: IconTheme(
                // The caption takes vertical space out of the same tile, so the
                // glyph gives up a little of its own to keep both balanced.
                data: IconThemeData(size: captioned ? iconSize * 0.86 : iconSize, color: foregroundColor),
                child: captioned
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          child,
                          SizedBox(height: 3.sp),
                          Text(
                            label!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: AppTextStyles.t14W500.copyWith(
                              // The glyph stays the brightest thing in the tile;
                              // the caption is a step quieter when idle so the
                              // focused/selected state still reads as "on".
                              color: selected || isFocused
                                  ? foregroundColor
                                  : foregroundColor.withValues(alpha: 0.78),
                              height: 1,
                            ),
                          ),
                        ],
                      )
                    : child,
              ),
            );
          }),
        ],
        child: Center(child: icon),
      ),
    );
  }

  /// Extra height a caption adds to the tile.
  static const double _captionBlock = 18.0;

  (double, double) _getSizeConfig() {
    return switch (size) {
      TvIconButtonSize.large => (80.0.w, 40.0.w),
      TvIconButtonSize.medium => (64.0.w, 32.0.w),
      TvIconButtonSize.small => (50.0.w, 24.0.w),
      TvIconButtonSize.mini => (38.0.w, 18.0.w),
    };
  }
}
