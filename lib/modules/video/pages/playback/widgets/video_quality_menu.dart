import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';

/// The quality menu, one entry per rendition the current stream answer ships.
class VideoQualityMenu extends ConsumerWidget {
  const VideoQualityMenu({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20.sp),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16.sp),
            child: Row(
              children: [
                Icon(Icons.high_quality_outlined, size: 26.sp, color: accent),
                SizedBox(width: 10.sp),
                Expanded(
                  child: Text(
                    i18n('video_quality'),
                    style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                TvIconButton(
                  icon: const Icon(Icons.close_rounded),
                  size: TvIconButtonSize.small,
                  isSecondary: true,
                  onTap: onClose,
                ),
              ],
            ),
          ),
          for (final option in state.qualityOptions)
            Padding(
              padding: EdgeInsets.only(left: 12.sp, right: 12.sp, bottom: 8.sp),
              child: TvFocusable(
                autofocus: option.quality == state.quality,
                onTap: () {
                  controller.switchQuality(option.quality);
                  onClose();
                },
                builder: (context, focused, child) {
                  final isCurrent = option.quality == state.quality;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 56.sp,
                    padding: EdgeInsets.symmetric(horizontal: 14.ts(context)),
                    decoration: BoxDecoration(
                      color: isCurrent ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12.sp),
                      border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            BilibiliMusicApi.qualityLabel(option.quality).isEmpty
                                ? '${option.quality}'
                                : BilibiliMusicApi.qualityLabel(option.quality),
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isCurrent ? accent : Colors.white,
                            ),
                          ),
                        ),
                        if (isCurrent) Icon(Icons.check_rounded, size: 22.sp, color: accent),
                      ],
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: 8.sp),
        ],
      ),
    );
  }
}
