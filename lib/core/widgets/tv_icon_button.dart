import 'dart:math' as math;
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/core/theme/index.dart';
import 'package:pure_live/core/widgets/tv_focus_style.dart';
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
  /// The button remains square. Its size is calculated from the larger of the
  /// content width/height plus padding instead of using a fixed tile size.
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
    final captioned = label != null && label!.trim().isNotEmpty;

    final (padding, iconSize, spacing, labelStyle) = _getSizeConfig(context, captioned);

    // The button remains square, but its size is now content-driven.
    //
    // The final square is calculated from:
    //
    //   max(content width, content height) + padding
    //
    // This keeps the original square-button visual language without
    // hard-coding a box width/height for every size.
    final contentWidth = captioned ? iconSize + spacing + _labelWidth(labelStyle) : iconSize;

    final contentHeight = captioned ? iconSize + spacing + _labelHeight(labelStyle) : iconSize;

    final squareSize = math.max(contentWidth + padding.horizontal, contentHeight + padding.vertical);

    // Square either way: the caption shares the tile with the glyph.
    // A caption needs a rounded square rather than the full-radius circle
    // of the icon-only button.
    final borderRadius = BorderRadius.circular(captioned ? squareSize * 0.22 : squareSize / 2);

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

            // expand only controls width.
            // Height always remains the calculated square size.
            width: expand ? double.infinity : squareSize,
            height: squareSize,

            padding: padding,
            decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
            child: IconTheme(
              data: IconThemeData(size: iconSize, color: foregroundColor),
              child: DefaultTextStyle(
                style: labelStyle.copyWith(color: foregroundColor),
                child: captioned
                    ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          iconSlot(child, iconSize),
                          SizedBox(height: spacing),
                          Text(
                            label!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: labelStyle.copyWith(
                              color: selected || isFocused ? foregroundColor : foregroundColor.withValues(alpha: 0.78),
                              height: 1,
                            ),
                          ),
                        ],
                      )
                    : iconSlot(child, iconSize),
              ),
            ),
          );
        }),
      ],
      child: icon,
    );

    // The self-sized square floats free of the parent's constraints; an
    // expanded row is sized by the parent and must not wrap one.
    if (expand) {
      return button;
    }

    return UnconstrainedBox(child: button);
  }

  /// The slot is tight-sized to the button's own icon size and the icon
  /// FittedBox-fits it: callers can pass `Icon(..., size: xxx)` and it will
  /// still be visually normalized to this button's size.
  Widget iconSlot(Widget icon, double iconSize) {
    return SizedBox(
      width: iconSize,
      height: iconSize,
      child: FittedBox(fit: BoxFit.contain, child: icon),
    );
  }

  /// Estimates the single-line caption width used to calculate the square.
  ///
  /// The actual Text widget remains responsible for ellipsizing if the parent
  /// imposes tighter constraints.
  double _labelWidth(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    return painter.width;
  }

  /// Estimates the caption height used to calculate the square.
  double _labelHeight(TextStyle style) {
    final painter = TextPainter(
      text: TextSpan(text: label, style: style),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout();

    return painter.height;
  }

  /// Tile and glyph sizing is content-driven.
  ///
  /// There is intentionally no fixed width or height here.
  ///
  /// Final square size:
  ///
  ///   max(
  ///     icon / icon + caption width,
  ///     icon + caption height,
  ///   )
  ///   + padding
  ///
  /// This preserves the square TV button shape while allowing each size to
  /// scale naturally with its content.
  (EdgeInsets, double, double, TextStyle) _getSizeConfig(BuildContext context, bool captioned) {
    return switch (size) {
      TvIconButtonSize.large => (
        EdgeInsets.symmetric(horizontal: 12.w, vertical: captioned ? 12.w : 12.w),
        AppTextStyles.t26.fontSize!,
        12.w,
        AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500),
      ),

      TvIconButtonSize.medium => (
        EdgeInsets.symmetric(horizontal: 10.w, vertical: captioned ? 10.w : 10.w),
        AppTextStyles.t28.fontSize!,
        10.w,
        AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500),
      ),

      TvIconButtonSize.small => (
        EdgeInsets.symmetric(horizontal: 8.w, vertical: captioned ? 11.w : 18.w),
        AppTextStyles.t22.fontSize!,
        8.w,
        AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500),
      ),

      TvIconButtonSize.mini => (
        EdgeInsets.symmetric(horizontal: 6.w, vertical: captioned ? 8.w : 6.w),
        AppTextStyles.t20.fontSize!,
        6.w,
        AppTextStyles.t12.copyWith(fontWeight: FontWeight.w500),
      ),
    };
  }
}
