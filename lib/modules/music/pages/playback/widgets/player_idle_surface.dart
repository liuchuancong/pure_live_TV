import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';

/// What fills the screen while no stream is open: cover art dimmed behind a
/// spinner (resolving) or the plain dark plate.
class PlayerIdleSurface extends StatelessWidget {
  const PlayerIdleSurface({super.key,required this.track, required this.resolving});

  final MusicTrack? track;
  final bool resolving;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final track = this.track;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (track != null && track.archive.cover.isNotEmpty)
          CachedNetworkImage(
            imageUrl: track.archive.cover,
            fit: BoxFit.cover,
            memCacheWidth: 1280,
            errorWidget: (_, _, _) => const SizedBox.shrink(),
          ),
        Container(color: Colors.black.withValues(alpha: track != null ? 0.72 : 1)),
        Center(
          child: resolving
              ? SizedBox(
                  width: 64.sp,
                  height: 64.sp,
                  child: CircularProgressIndicator(strokeWidth: 4.sp, color: tvTheme.focusColor),
                )
              : (track == null
                    ? Icon(Icons.library_music_rounded, size: 96.sp, color: Colors.white24)
                    : const SizedBox.shrink()),
        ),
      ],
    );
  }
}

