import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

typedef TvSettingsTrailingBuilder = Widget Function(BuildContext context, bool focused);

class TvSettingsRow extends StatefulWidget {
  const TvSettingsRow({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.leading,
    this.trailingBuilder,
    this.footer,
    this.onSelect,
    this.onDirection,
    this.autofocus = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? leading;
  final TvSettingsTrailingBuilder? trailingBuilder;
  final Widget? footer;
  final VoidCallback? onSelect;
  final DpadDirectionCallback? onDirection;
  final bool autofocus;

  @override
  State<TvSettingsRow> createState() => _TvSettingsRowState();
}

class _TvSettingsRowState extends State<TvSettingsRow> {
  final FocusNode _focusNode = FocusNode(debugLabel: 'tv_settings_row');

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final borderRadius = BorderRadius.circular(14.sp);

    final List<DpadEffect> effects = [
      DpadCustomEffect((ctx, state, _) {
        final bool focused = state.focused;
        final bool pressed = state.pressed;
        final Color accent = tvTheme.focusColor;
        final bool hasLeading = widget.leading != null || widget.icon != null;

        final Color titleColor = focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor;
        final Color subtitleColor = focused ? tvTheme.onFocusedCardSecondary : tvTheme.secondaryTextColor;
        final Color iconColor = focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor;

        final Duration animDuration = focused ? const Duration(milliseconds: 120) : Duration.zero;

        final double scale = pressed ? 0.98 : 1.0;

        return AnimatedScale(
          scale: scale,
          duration: animDuration,
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: animDuration,
            curve: Curves.easeOutCubic,
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 14.sp),
            decoration: BoxDecoration(
              color: focused ? tvTheme.focusedCardColor : Colors.transparent,
              borderRadius: borderRadius,
              border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
              boxShadow: [
                BoxShadow(
                  color: focused
                      ? accent.withValues(alpha: tvTheme.isLight ? 1.0 : 0.75)
                      : accent.withValues(alpha: 0.0),
                  blurRadius: focused ? (tvTheme.isLight ? 0 : 18.sp) : 0,
                  spreadRadius: focused ? (tvTheme.isLight ? 2.sp : 1.5.sp) : 0,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    final double trailingMaxWidth = constraints.maxWidth * 0.55;
                    final double minContentHeight = 30.sp + 4.sp + 22.sp;
                    return Container(
                      constraints: BoxConstraints(minHeight: minContentHeight),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          if (widget.leading != null)
                            widget.leading!
                          else if (widget.icon != null)
                            Icon(widget.icon, size: 30.sp, color: iconColor),
                          if (hasLeading) SizedBox(width: 16.sp),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.t22W600.copyWith(color: titleColor),
                                ),
                                if (widget.subtitle != null) ...[
                                  SizedBox(height: 4.sp),
                                  Text(
                                    widget.subtitle!,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.t16W500.copyWith(color: subtitleColor),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          SizedBox(width: 12.sp),
                          ConstrainedBox(
                            constraints: BoxConstraints(maxWidth: trailingMaxWidth),
                            child: widget.trailingBuilder?.call(context, focused) ?? const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                if (widget.footer != null) ...[SizedBox(height: 10.sp), widget.footer!],
              ],
            ),
          ),
        );
      }),
    ];

    return DpadFocusable(
      autofocus: widget.autofocus,
      focusNode: _focusNode,
      effects: effects,
      onSelect: widget.onSelect,
      onDirection: widget.onDirection,
      child: const SizedBox.shrink(),
    );
  }
}

Widget tvSettingsChevron(BuildContext context, bool focused) {
  final tvTheme = context.tvTheme;
  return Icon(
    Icons.chevron_right_rounded,
    size: 30.sp,
    color: focused ? tvTheme.onFocusedCard : tvTheme.secondaryTextColor,
  );
}

Widget tvSettingsValueLabel(BuildContext context, bool focused, String value) {
  final tvTheme = context.tvTheme;

  return Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Flexible(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            value,
            maxLines: 1,
            softWrap: false,
            style: AppTextStyles.t20W600.copyWith(color: focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor),
          ),
        ),
      ),
      SizedBox(width: 8.sp),
      Icon(Icons.expand_more_rounded, size: 28.sp, color: focused ? tvTheme.onFocusedCard : tvTheme.secondaryTextColor),
    ],
  );
}

class TvSettingsSwitchIndicator extends StatelessWidget {
  const TvSettingsSwitchIndicator({super.key, required this.value, required this.focused});

  final bool value;
  final bool focused;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final Color on = tvTheme.focusColor;
    final Color off = tvTheme.secondaryTextColor;

    return SizedBox(
      width: 62.sp,
      height: 34.sp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: value ? on.withValues(alpha: focused ? 0.35 : 0.22) : Colors.transparent,
          border: Border.all(color: value ? on : off.withValues(alpha: 0.6), width: 2.sp),
          borderRadius: BorderRadius.circular(6.sp),
        ),
        padding: EdgeInsets.all(3.sp),
        child: Align(
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            width: 24.sp,
            decoration: BoxDecoration(
              color: value ? on : off.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3.sp),
            ),
          ),
        ),
      ),
    );
  }
}
