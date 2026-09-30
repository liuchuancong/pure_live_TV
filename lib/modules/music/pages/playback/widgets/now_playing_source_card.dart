import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// The homogeneous queue's source: one UP (and, for an album, one archive).
class NowPlayingQueueSource {
  const NowPlayingQueueSource({
    required this.upName,
    required this.upFace,
    required this.title,
    required this.showUpName,
    required this.isFavorited,
  });

  final String upName;
  final String upFace;
  final String title;

  /// False when the headline already is the UP name (an UP-runs queue).
  final bool showUpName;
  final bool isFavorited;
}

/// The video player page's top bar, at queue size: the UP's face, the album
/// when the source sits in the library.
class NowPlayingSourceHeader extends StatelessWidget {
  const NowPlayingSourceHeader({super.key, required this.source, required this.track});

  final NowPlayingQueueSource source;
  final MusicTrack track;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return Padding(
      padding: EdgeInsets.fromLTRB(20.sp, 0, 20.sp, 6.sp),
      child: Container(
        padding: EdgeInsets.all(16.sp),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(16.sp),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: Row(
          children: [
            TvCommonAvatar(avatarUrl: source.upFace, fallbackName: source.upName, radius: 40.sp),
            SizedBox(width: 16.sp),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    source.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor),
                  ),
                  SizedBox(height: 4.sp),
                  Row(
                    children: [
                      if (source.showUpName) ...[
                        Icon(Icons.person_outline_rounded, size: 18.sp, color: tvTheme.secondaryTextColor),
                        SizedBox(width: 4.sp),
                        Flexible(
                          child: Text(
                            source.upName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: tvTheme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                      if (source.isFavorited) ...[
                        SizedBox(width: 10.sp),
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8.ts(context), vertical: 2.ts(context)),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(6.sp),
                          ),
                          child: Text(
                            i18n('followed'),
                            style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w600, color: accent),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: 12.sp),
            ClipRRect(
              borderRadius: BorderRadius.circular(10.sp),
              child: CachedNetworkImage(
                imageUrl: track.archive.cover,
                width: 132.sp,
                height: 84.sp,
                fit: BoxFit.cover,
                memCacheWidth: 320,
                fadeInDuration: Duration.zero,
                errorWidget: (_, _, _) => Container(
                  color: accent.withValues(alpha: 0.12),
                  child: Icon(Icons.music_note_rounded, size: 30.sp, color: accent),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
