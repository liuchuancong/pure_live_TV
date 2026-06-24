import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/theme/styles/styles.dart';
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
        list.add(
          DpadScaleEffect(
            scale: 1.06,
            pressedScale: 0.98,
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeOutCubic,
          ),
        );
        list.add(
          DpadGlowEffect(
            color: activeTheme.focusColor.withValues(alpha: 0.35),
            blurRadius: 2.w,
            spreadRadius: 2.0.w,
            borderRadius: borderRadius,
          ),
        );
      }
      list.add(
        DpadCustomEffect((ctx, state, child) {
          final isFocused = state.focused;
          final bgColor = excludeFocus
              ? activeTheme.cardColor
              : isFocused
              ? activeTheme.focusColor
              : isSecondary
              ? activeTheme.cardColor.withValues(alpha: 0.5)
              : activeTheme.cardColor;

          final foregroundColor = excludeFocus
              ? activeTheme.focusedCardColor
              : isFocused
              ? activeTheme.focusedCardColor
              : isSecondary
              ? activeTheme.secondaryTextColor
              : activeTheme.primaryTextColor;

          return AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            curve: Curves.easeInOut,
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
      TvButtonSize.medium => (64.0.w, EdgeInsets.symmetric(horizontal: 32.w), AppTextStyles.t26W500, 24.0.w, 10.0.w),
      TvButtonSize.small => (50.0.w, EdgeInsets.symmetric(horizontal: 24.w), AppTextStyles.t20W500, 20.0.w, 8.0.w),
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: switch (iconPosition) {
        TvIconPosition.left => [icon!, SizedBox(width: space), textWidget],
        TvIconPosition.right => [textWidget, SizedBox(width: space), icon!],
        TvIconPosition.top => [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              icon!,
              SizedBox(height: space),
              textWidget,
            ],
          ),
        ],
        TvIconPosition.bottom => [
          Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              textWidget,
              SizedBox(height: space),
              icon!,
            ],
          ),
        ],
      },
    );
  }
}
