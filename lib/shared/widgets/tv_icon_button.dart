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

  /// Stretches to the width the parent gives instead of sizing to the square
  /// tile — the collapsed sidebar rail's full-width menu look. The content
  /// stays centred, the focus fill covers the whole row, and the scale lift is
  /// dropped (a full-width row lifting 1.08 paints over its neighbours; the
  /// ring + glow + fill carry the state on their own).
  final bool expand;

  /// A short caption painted under the icon, for callers whose icons alone are
  /// ambiguous (the collapsed home sidebar names each destination with two
  /// characters).
  ///
  /// The caption fits inside the same square tile, which stays the size of the
  /// icon-only button; without a label the button is the plain circle it always
  /// was.
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
    this.expand = false,
    this.label,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.tvTheme;
    final double textScale = TvTextScale.factorOf(context);
    final (boxSize, iconSize) = _getSizeConfig(textScale);
    final bool captioned = label != null && label!.trim().isNotEmpty;
    // Square either way: the caption shares the tile with the glyph instead of
    // growing it, so the collapsed rail stays a grid of equal squares. A caption
    // needs a flat edge to sit on, hence the rounded square rather than the
    // full-radius circle of the icon-only button.
    final borderRadius = BorderRadius.circular(captioned ? boxSize * 0.28 : boxSize / 2);

    final Widget button = DpadFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      onSelect: onTap,
      effects: [
        ...TvFocusStyle.effects(activeTheme, borderRadius, scale: expand ? 1.0 : 1.08),
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
            width: expand ? double.infinity : boxSize,
            height: boxSize,
            decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
            child: IconTheme(
              // The caption shares the tile with the glyph, so the glyph gives
              // up a little of its own to keep both balanced.
              data: IconThemeData(size: captioned ? iconSize * 0.8 : iconSize, color: foregroundColor),
              child: captioned
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        child,
                        SizedBox(height: 2.sp * textScale),
                        Text(
                          label!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.t14.copyWith(
                            fontWeight: FontWeight.w500,
                            // The glyph stays the brightest thing in the tile;
                            // the caption is a step quieter when idle so the
                            // focused/selected state still reads as "on".
                            color: selected || isFocused ? foregroundColor : foregroundColor.withValues(alpha: 0.78),
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
    );

    // The self-sized square floats free of the parent's constraints; an
    // expanded row is sized by the parent and must not wrap one.
    if (expand) return button;
    return UnconstrainedBox(child: button);
  }

  /// Tile and glyph, in design pixels multiplied by the app font scale.
  ///
  /// The caption under the glyph is a `.sp` label, so the square that holds it
  /// has to grow with it: a fixed tile cut the caption and left the rail's icons
  /// untouched next to text the user had enlarged.
  (double, double) _getSizeConfig(double textScale) {
    return switch (size) {
      TvIconButtonSize.large => (80.0.w * textScale, 40.0.w * textScale),
      TvIconButtonSize.medium => (64.0.w * textScale, 32.0.w * textScale),
      TvIconButtonSize.small => (50.0.w * textScale, 24.0.w * textScale),
      TvIconButtonSize.mini => (38.0.w * textScale, 18.0.w * textScale),
    };
  }
}
