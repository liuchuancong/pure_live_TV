import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/widgets/tv_marqueer.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:pure_live/utils/cache_manager.dart';
import 'package:pure_live/widgets/app_status_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/core/models/live_area/live_area.dart';
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
      DpadGlowEffect(color: tvTheme.focusColor, opacity: 1),
      DpadCustomEffect((ctx, state, _) {
        final isFocused = state.focused;
        final bgColor = tvTheme.cardColor;
        final titleColor = tvTheme.primaryTextColor;
        final iconColor = tvTheme.primaryTextColor;

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
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
                child: TvMarqueerText(
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
      onSelect: onTap,
      onLongSelect: onLongPress,
      onFocusChange: (focused) {
        if (!focused) return;
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: 0.2,
        );
      },
      child: const SizedBox(),
    );
  }
}
