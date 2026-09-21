import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/tv_focus_style.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

enum TvButtonSize { large, medium, small, mini }

enum TvIconPosition { left, right, top, bottom }

class TvButton extends StatelessWidget {
  final String title;
  final Widget? icon;
  final TvIconPosition iconPosition;
  final TvButtonSize size;
  final VoidCallback? onTap;
  final bool autofocus;
  final bool isSecondary;
  final bool excludeFocus;
  final bool selected;
  final bool useFadedFocus;
  final FocusNode? focusNode;

  /// Reports focus entering/leaving the button — for callers that react to the
  /// highlight itself (a tab bar that switches as focus walks it).
  final ValueChanged<bool>? onFocusChange;

  const TvButton({
    super.key,
    required this.title,
    this.icon,
    this.iconPosition = TvIconPosition.left,
    this.size = TvButtonSize.medium,
    this.onTap,
    this.autofocus = false,
    this.isSecondary = false,
    this.excludeFocus = false,
    this.selected = false,
    this.useFadedFocus = false,
    this.focusNode,
    this.onFocusChange,
  });

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.tvTheme;
    final (height, padding, baseTextStyle, iconSize, space) = _getSizeConfig();

    final borderRadius = iconPosition == TvIconPosition.top || iconPosition == TvIconPosition.bottom
        ? BorderRadius.circular(16.w)
        : BorderRadius.circular(height / 2);

    List<DpadEffect> buildEffects() {
      final list = <DpadEffect>[];
      if (!excludeFocus) {
        // The shared focus language: scale + accent ring + (dark-only) halo.
        // See [TvFocusStyle] for why these numbers, and only these, are used.
        list.addAll(TvFocusStyle.effects(activeTheme, borderRadius, scale: 1.06));
      }
      list.add(
        DpadCustomEffect((ctx, state, child) {
          final isFocused = state.focused;

          late Color bgColor;
          late Color foregroundColor;

          // House style: button icons and text are white in every state and
          // every theme mode — the accent fills (and the dark resting
          // surfaces) are strong enough to carry white everywhere.
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
            // buttonSurface, not cardColor: on light palettes the card is a
            // near-white tint, so a card-colored button read as a plain white
            // block no matter which preset was active.
            //
            // Translucent when idle: an opaque pill sat like a slab over a
            // picture background. Focus/selected keep the solid accent fill —
            // the highlight must stay unmistakable — only the resting state
            // lets the background through.
            bgColor = isSecondary
                ? activeTheme.buttonSurface.withValues(alpha: 0.45)
                : activeTheme.buttonSurface.withValues(alpha: activeTheme.isLight ? 0.85 : 0.75);
            foregroundColor = Colors.white;
          }

          if (excludeFocus) {
            // Non-focusable buttons are labels and badges (followed marker,
            // replay marker, viewer count, platform name). They never show a
            // focus state, but they still need readable foreground colours:
            // this used to force `focusedCardColor` — the foreground meant for
            // content sitting on an accent-filled *focused* background — onto a
            // plain card background, which made the badge text nearly invisible.
            // Selection is still honoured so a selected label stays selected.
            bgColor = selected ? activeTheme.focusColor : activeTheme.buttonSurface;
            foregroundColor = selected
                ? activeTheme.onFocusColor
                : (isSecondary ? activeTheme.secondaryTextColor : activeTheme.primaryTextColor);
          }

          return AnimatedContainer(
            duration: TvFocusStyle.focusDuration(state.focused),
            curve: TvFocusStyle.curve,
            height: height,
            padding: padding,
            decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
            child: IconTheme(
              data: IconThemeData(size: iconSize, color: foregroundColor),
              child: DefaultTextStyle(
                style: baseTextStyle.copyWith(color: foregroundColor),
                child: child,
              ),
            ),
          );
        }),
      );
      return list;
    }

    Widget btn = DpadFocusable(
      autofocus: autofocus && !excludeFocus,
      onSelect: excludeFocus ? null : onTap,
      focusNode: focusNode,
      onFocusChange: onFocusChange,
      effects: buildEffects(),
      child: _buildLayout(baseTextStyle, space),
    );

    if (excludeFocus) {
      return ExcludeFocus(child: btn);
    }
    return btn;
  }

  (double, EdgeInsets, TextStyle, double, double) _getSizeConfig() {
    return switch (size) {
      TvButtonSize.large => (80.0.w, EdgeInsets.symmetric(horizontal: 40.w), AppTextStyles.t32W500, 32.0.w, 14.0.w),
      TvButtonSize.medium => (64.0.w, EdgeInsets.symmetric(horizontal: 28.w), AppTextStyles.t26W500, 24.0.w, 10.0.w),
      TvButtonSize.small => (54.0.w, EdgeInsets.symmetric(horizontal: 24.w), AppTextStyles.t20W500, 20.0.w, 8.0.w),
      TvButtonSize.mini => (44.0.w, EdgeInsets.symmetric(horizontal: 20.w), AppTextStyles.t18W500, 18.0.w, 7.0.w),
    };
  }

  Widget _buildLayout(TextStyle textStyle, double space) {
    final textWidget = Center(widthFactor: 1.0, child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis));

    if (icon == null) {
      return Center(child: textWidget);
    }
    if (title.isEmpty && icon != null) {
      return Center(child: icon!);
    }
    // The text is the flexible part: a button squeezed by its parent (a tight
    // cell, a narrow bar) ellipsizes its label instead of overflowing the
    // fixed icon + gap.
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: switch (iconPosition) {
        TvIconPosition.left => [icon!, SizedBox(width: space), Flexible(child: textWidget)],
        TvIconPosition.right => [Flexible(child: textWidget), SizedBox(width: space), icon!],
        TvIconPosition.top => [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon!,
              SizedBox(height: space),
              Flexible(child: textWidget),
            ],
          ),
        ],
        TvIconPosition.bottom => [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(child: textWidget),
              SizedBox(height: space),
              icon!,
            ],
          ),
        ],
      },
    );
  }
}
