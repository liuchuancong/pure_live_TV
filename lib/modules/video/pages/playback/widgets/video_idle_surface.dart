import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// The dark plate behind a stream that has not opened yet.
class VideoIdleSurface extends StatelessWidget {
  const VideoIdleSurface({super.key, required this.track, required this.resolving});

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
                  width: 64.ts(context),
                  height: 64.ts(context),
                  child: CircularProgressIndicator(strokeWidth: 4.ts(context), color: tvTheme.focusColor),
                )
              : (track == null
                    ? Icon(Icons.movie_outlined, size: 96.ts(context), color: Colors.white24)
                    : const SizedBox.shrink()),
        ),
      ],
    );
  }
}
