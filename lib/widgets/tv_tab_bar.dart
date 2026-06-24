import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvTabItemData {
  final String title;
  final Widget? icon;

  const TvTabItemData({required this.title, this.icon});
}

class TvTabBar extends StatefulWidget {
  final List<TvTabItemData> tabs;
  final int currentIndex;
  final void Function(int index) onTabChange;
  final void Function(int index)? onTabRefresh;
  final List<DpadEffect>? effects;

  const TvTabBar({
    super.key,
    required this.tabs,
    required this.currentIndex,
    required this.onTabChange,
    this.effects,
    this.onTabRefresh,
  });

  @override
  State<TvTabBar> createState() => _TvTabBarState();
}

class _TvTabBarState extends State<TvTabBar> {
  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final double height = 44.sp;
    final borderRadius = BorderRadius.circular(height / 2);

    return DpadRegion(
      horizontalEdge: DpadEdgeBehavior.leave,
      child: Container(
        width: double.infinity,
        height: 50.sp,
        alignment: Alignment.center,
        padding: EdgeInsets.symmetric(horizontal: 8.sp),
        color: Colors.transparent,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemCount: widget.tabs.length,
          itemBuilder: (context, index) {
            final tab = widget.tabs[index];
            final isSelected = widget.currentIndex == index;

            final dynamicEffects =
                widget.effects ??
                [
                  DpadScaleEffect(
                    scale: 1.05,
                    pressedScale: 0.98,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOutCubic,
                  ),
                  DpadCustomEffect((context, state, child) {
                    final isFocused = state.focused;

                    final bgColor = isSelected
                        ? currentTvTheme.focusColor
                        : isFocused
                        ? currentTvTheme.focusColor.withValues(alpha: 0.5)
                        : Colors.transparent;

                    final foregroundColor = isSelected
                        ? currentTvTheme.focusedCardColor
                        : isFocused
                        ? currentTvTheme.focusColor
                        : currentTvTheme.primaryTextColor;

                    final baseStyle = isSelected || isFocused ? AppTextStyles.t20W600 : AppTextStyles.t20;

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 100),
                      curve: Curves.easeInOut,
                      height: height,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(horizontal: 28.sp),
                      decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
                      child: IconTheme(
                        data: IconThemeData(size: 26.sp, color: foregroundColor),
                        child: DefaultTextStyle(
                          style: baseStyle.copyWith(color: foregroundColor),
                          child: child,
                        ),
                      ),
                    );
                  }),
                ];

            return Padding(
              padding: EdgeInsets.symmetric(horizontal: 6.sp),
              child: DpadFocusable(
                effects: dynamicEffects,
                onFocusChange: null,
                onSelect: () {
                  if (index == widget.currentIndex) {
                    widget.onTabRefresh?.call(index);
                  } else {
                    widget.onTabChange(index);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (tab.icon != null) ...[tab.icon!, SizedBox(width: 10.sp)],
                    Center(child: Text(tab.title)),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
