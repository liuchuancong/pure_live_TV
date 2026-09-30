import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/core/theme/index.dart';
import 'package:pure_live/core/widgets/tv_focus_style.dart';
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
  final bool disableScale;
  final FocusNode? focusNode;

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
    this.disableScale = false,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    final activeTheme = context.tvTheme;
    final (padding, baseTextStyle, iconSize, space) = _getSizeConfig(context, iconPosition);

    final borderRadius = BorderRadius.circular(999);

    List<DpadEffect> buildEffects() {
      final list = <DpadEffect>[];

      if (!excludeFocus) {
        // The shared focus language: scale + accent ring + (dark-only) halo.
        // See [TvFocusStyle] for why these numbers, and only these, are used.
        // Scale can be disabled for buttons where the lift is unwanted (e.g. playback bars).
        if (!disableScale) {
          list.addAll(TvFocusStyle.effects(activeTheme, borderRadius, scale: 1.08));
        } else {
          list.addAll(TvFocusStyle.effects(activeTheme, borderRadius, scale: 1.0));
        }
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
          } else if (isFocused) {
            bgColor = useFadedFocus
                ? activeTheme.focusColor.withValues(alpha: 0.5)
                : activeTheme.focusColor.withValues(alpha: 0.65);
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
            // content sitting on an accent-filled *focused* background — onto
            // a plain card background, which made the badge text nearly invisible.
            // Selection is still honoured so a selected label stays selected.
            bgColor = selected ? activeTheme.focusColor : activeTheme.buttonSurface;

            foregroundColor = selected
                ? activeTheme.onFocusColor
                : (isSecondary ? activeTheme.secondaryTextColor : activeTheme.primaryTextColor);
          }

          return AnimatedContainer(
            duration: TvFocusStyle.focusDuration(state.focused),
            curve: TvFocusStyle.curve,
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

    final Widget btn = DpadFocusable(
      autofocus: autofocus && !excludeFocus,
      onSelect: excludeFocus ? null : onTap,
      focusNode: focusNode,
      effects: buildEffects(),
      child: _buildLayout(baseTextStyle, space, iconSize),
    );

    if (excludeFocus) {
      return ExcludeFocus(child: btn);
    }

    return btn;
  }

  /// Button sizing is content-driven.
  ///
  /// There is intentionally no fixed width or height here.
  /// The final button size is determined by:
  ///
  ///   content size + padding
  ///
  /// This prevents buttons from becoming unnecessarily large when placed
  /// next to differently sized content.
  (EdgeInsets, TextStyle, double, double) _getSizeConfig(BuildContext context, TvIconPosition iconPosition) {
    final isVertical = iconPosition == TvIconPosition.top || iconPosition == TvIconPosition.bottom;

    return switch (size) {
      TvButtonSize.large => (
        EdgeInsets.symmetric(horizontal: 32.w, vertical: isVertical ? 22.w : 14.w),
        AppTextStyles.t20.copyWith(fontWeight: FontWeight.w500),
        AppTextStyles.t26.fontSize!,
        14.w,
      ),

      TvButtonSize.medium => (
        EdgeInsets.symmetric(horizontal: 24.w, vertical: isVertical ? 16.w : 10.w),
        AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500),
        AppTextStyles.t24.fontSize!,
        10.w,
      ),

      TvButtonSize.small => (
        EdgeInsets.symmetric(horizontal: 18.w, vertical: isVertical ? 12.w : 8.w),
        AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500),
        AppTextStyles.t22.fontSize!,
        8.w,
      ),

      TvButtonSize.mini => (
        EdgeInsets.symmetric(horizontal: 14.w, vertical: isVertical ? 9.w : 6.w),
        AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500),
        AppTextStyles.t20.fontSize!,
        6.w,
      ),
    };
  }

  Widget _buildLayout(TextStyle textStyle, double space, double iconSize) {
    final textWidget = Text(title, maxLines: 1, overflow: TextOverflow.ellipsis);

    // The slot is tight-sized to the button's own scaled icon size and the
    // icon FittedBox-fits it: callers pass `Icon(..., size: 22.ts(context))` with an
    // explicit size that overrides this button's IconTheme, so without the
    // slot every button icon stayed at its drafted pixels while the pill and
    // its label grew with the font. Any icon widget — Icon, SVG, a rotated or
    // badged one — scales to the slot the same way.
    Widget iconSlot(Widget icon) {
      return SizedBox(
        width: iconSize,
        height: iconSize,
        child: FittedBox(fit: BoxFit.contain, child: icon),
      );
    }

    if (icon == null) {
      return textWidget;
    }

    if (title.isEmpty) {
      return iconSlot(icon!);
    }

    return switch (iconPosition) {
      TvIconPosition.left => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          iconSlot(icon!),
          SizedBox(width: space),
          Flexible(child: textWidget),
        ],
      ),

      TvIconPosition.right => Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: textWidget),
          SizedBox(width: space),
          iconSlot(icon!),
        ],
      ),

      TvIconPosition.top => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          iconSlot(icon!),
          SizedBox(height: space),
          textWidget,
        ],
      ),

      TvIconPosition.bottom => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          textWidget,
          SizedBox(height: space),
          iconSlot(icon!),
        ],
      ),
    };
  }
}
