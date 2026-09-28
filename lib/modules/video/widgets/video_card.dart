import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:pure_live/modules/video/controllers/playback/video_progress_controller.dart';

/// The video-mode card, newBV's SmallVideoCard for a 1080p TV grid: cover,
/// title, UP, stats, the region badge and — the newBV touch — the watched
/// progress bar every browsing surface shows.
class VideoCard extends ConsumerWidget {
  const VideoCard({super.key, required this.archive, required this.onTap, this.badge = ''});

  final MusicArchive archive;
  final VoidCallback onTap;

  /// An override label (ranking position, region name); empty = no badge.
  final String badge;

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final progress = ref.watch(videoProgressControllerProvider.select((s) => s.entries[archive.bvid]?.percent ?? 0.0));

    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(16.sp),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.5.sp),
          boxShadow: [
            BoxShadow(color: accent.withValues(alpha: focused ? 0.3 : 0), blurRadius: focused ? 20.sp : 0),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16.sp)),
                    child: CachedNetworkImage(
                      imageUrl: archive.cover,
                      fit: BoxFit.cover,
                      memCacheWidth: 640,
                      errorWidget: (_, _, _) => Container(
                        color: accent.withValues(alpha: 0.12),
                        child: Icon(Icons.movie_outlined, size: 48.sp, color: tvTheme.secondaryTextColor),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8.sp,
                    top: 8.sp,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 3.sp),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(8.sp),
                      ),
                      child: Text(
                        badge.isNotEmpty ? badge : archive.tname,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t14W500.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  Positioned(
                    right: 8.sp,
                    bottom: 8.sp,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 3.sp),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.62),
                        borderRadius: BorderRadius.circular(8.sp),
                      ),
                      child: Text(
                        formatDuration(archive.duration),
                        style: AppTextStyles.t14W500.copyWith(color: Colors.white),
                      ),
                    ),
                  ),
                  if (progress > 0)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 4.sp,
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation(accent),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Padding(
                padding: EdgeInsets.all(10.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        archive.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t16W600.copyWith(color: tvTheme.primaryTextColor, height: 1.3),
                      ),
                    ),
                    SizedBox(height: 4.sp),
                    Row(
                      children: [
                        Icon(Icons.play_circle_outline_rounded, size: 16.sp, color: tvTheme.secondaryTextColor),
                        SizedBox(width: 4.sp),
                        Text(
                          readableCount(archive.playCount.toString()),
                          style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                        ),
                        SizedBox(width: 10.sp),
                        Icon(Icons.format_quote_rounded, size: 16.sp, color: tvTheme.secondaryTextColor),
                        SizedBox(width: 4.sp),
                        Text(
                          readableCount(archive.barrageCount.toString()),
                          style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            archive.upName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
