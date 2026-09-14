import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/theme/index.dart';

/// Playback failure overlay with two D-pad focusable actions: retry and refresh room.
class PlaybackFailureOverlay extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onRefreshRoom;

  const PlaybackFailureOverlay({
    super.key,
    required this.message,
    required this.onRetry,
    required this.onRefreshRoom,
  });

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Container(
      color: Colors.black.withValues(alpha: 0.72),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48.sp, color: tvTheme.secondaryTextColor),
          SizedBox(height: 12.sp),
          SizedBox(
            width: 560.sp,
            child: Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.t18W500.copyWith(color: tvTheme.primaryTextColor),
            ),
          ),
          SizedBox(height: 20.sp),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              DpadFocusable(
                autofocus: true,
                effects: [
                  DpadScaleEffect(scale: 1.05),
                  DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.5)),
                ],
                onSelect: onRetry,
                child: _pill(tvTheme.focusColor, '重试播放', Icons.refresh),
              ),
              SizedBox(width: 16.sp),
              DpadFocusable(
                effects: [
                  DpadScaleEffect(scale: 1.05),
                  DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.5)),
                ],
                onSelect: onRefreshRoom,
                child: _pill(Colors.white.withValues(alpha: 0.12), '刷新房间', Icons.travel_explore),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _pill(Color background, String label, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 22.sp, vertical: 12.sp),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(12.sp)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20.sp, color: Colors.white),
          SizedBox(width: 8.sp),
          Text(label, style: AppTextStyles.t16W600.copyWith(color: Colors.white)),
        ],
      ),
    );
  }
}
