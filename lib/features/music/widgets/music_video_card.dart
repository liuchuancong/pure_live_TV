import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/platforms/bilibili_music/bilibili_music_models.dart';

/// A music archive tile for the ranking / search grids.
///
/// Not [TvRoomCard]: that widget speaks LiveRoom (followed marks, platform
/// badges, live status). An archive card is a cover, a title and who made it —
/// a slimmer widget keeps the grid honest about what it is showing.
class MusicVideoCard extends StatelessWidget {
  const MusicVideoCard({super.key, required this.archive, this.onTap});

  final MusicArchive archive;
  final VoidCallback? onTap;

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) {
        return AnimatedScale(
          scale: focused ? 1.03 : 1.0,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: tvTheme.cardColor,
              borderRadius: BorderRadius.circular(16.sp),
              border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
              boxShadow: [
                BoxShadow(color: accent.withValues(alpha: focused ? 0.45 : 0), blurRadius: focused ? 16.sp : 0),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: archive.cover,
                        fit: BoxFit.cover,
                        memCacheWidth: 640,
                        errorWidget: (_, _, _) => Icon(Icons.music_note_rounded, size: 40.sp, color: tvTheme.secondaryTextColor),
                        placeholder: (_, _) => Container(color: tvTheme.secondaryTextColor.withValues(alpha: 0.15)),
                      ),
                      if (archive.duration > 0)
                        Positioned(
                          right: 8.sp,
                          bottom: 8.sp,
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 2.sp),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(8.sp),
                            ),
                            child: Text(
                              formatDuration(archive.duration),
                              style: AppTextStyles.t14W500.copyWith(color: Colors.white, height: 1.2),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(10.sp),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        archive.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t16W700.copyWith(color: tvTheme.primaryTextColor, height: 1.3),
                      ),
                      SizedBox(height: 6.sp),
                      Row(
                        children: [
                          Icon(Icons.person_outline_rounded, size: 16.sp, color: tvTheme.secondaryTextColor),
                          SizedBox(width: 4.sp),
                          Expanded(
                            child: Text(
                              archive.upName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
                            ),
                          ),
                          SizedBox(width: 8.sp),
                          Icon(Icons.play_circle_outline_rounded, size: 16.sp, color: tvTheme.secondaryTextColor),
                          SizedBox(width: 4.sp),
                          Text(
                            readableCount(archive.playCount.toString()),
                            style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
