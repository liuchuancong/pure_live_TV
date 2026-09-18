import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvAreaCard extends StatelessWidget {
  const TvAreaCard({super.key, required this.area, required this.onTap, required this.onLongPress});

  final LiveArea area;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final borderRadius = BorderRadius.circular(24.sp);
    final displayImageUrl = area.areaPic;

    final List<DpadEffect> effects = [
      DpadScaleEffect(
        scale: 1.04,
        pressedScale: 0.97,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
      ),
      // Light palette: a soft 12px halo smears on white; use a crisp ring.
      tvTheme.isLight
          ? DpadGlowEffect(color: tvTheme.focusColor, opacity: 1, spreadRadius: 2.sp, blurRadius: 0)
          : DpadGlowEffect(color: tvTheme.focusColor, opacity: 1, spreadRadius: 1.sp, blurRadius: 12.0.sp),
      DpadCustomEffect((ctx, state, _) {
        final isFocused = state.focused;
        final bgColor = tvTheme.backgroundColor;
        final titleColor = tvTheme.primaryTextColor;
        final iconColor = tvTheme.primaryTextColor;

        return AnimatedContainer(
          duration: TvFocusStyle.focusDuration(isFocused),
          curve: TvFocusStyle.curve,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: Border.all(color: isFocused ? tvTheme.focusColor : Colors.transparent, width: 2.sp),
          ),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80.sp,
                height: 80.sp,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12.sp)),
                child: displayImageUrl.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: displayImageUrl,
                        cacheManager: CustomImageCacheManager.instance,
                        // Area artwork renders inside a small card: decode at that
                        // size and keep the cached copy bounded.
                        memCacheWidth: 320,
                        maxWidthDiskCache: 640,
                        fit: BoxFit.fill,
                        placeholder: (context, url) =>
                            AppStatusView(type: AppStatusType.loading, title: "", subtitle: "", isMini: true),
                        errorWidget: (context, url, error) =>
                            AppStatusView(type: AppStatusType.error, title: "", subtitle: "", isMini: true),
                      )
                    : Center(
                        child: Icon(Icons.live_tv_rounded, size: 50.sp, color: iconColor),
                      ),
              ),
              SizedBox(height: 12.sp),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.sp),
                child: TvMarqueeText(
                  text: area.areaName,
                  isFocused: isFocused,
                  style: AppTextStyles.t20W600.copyWith(color: titleColor),
                ),
              ),
            ],
          ),
        );
      }),
    ];

    return DpadFocusable(
      autofocus: false,
      effects: effects,
      // `DpadFocusable` already reveals the focused card through
      // `DpadScroll.ensureVisible` (padded, and it walks every scrollable
      // ancestor). The extra `Scrollable.ensureVisible` here animated to a
      // second, different offset and made the grid jitter while moving.
      onSelect: onTap,
      onLongSelect: onLongPress,
      child: const SizedBox(),
    );
  }
}
