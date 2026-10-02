import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/music/widgets/music_video_card.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';
import 'package:pure_live/modules/music/pages/playback/widgets/player_now_playing_view.dart' show stripTrackOrdinal;

/// One song row in the bmsc TrackTile shape, shared by every music list:
/// index-or-now-playing glyph, wide cover, title, album/UP metadata and
/// the duration. Long press runs the caller's removal/menu action.
/// One song row in the bmsc TrackTile shape, at TV size: a wide cover, the
/// title, then icon-led metadata lines — album over author, and for multi-P
/// archives the part count and the duration. Long press removes it from the list.
class MusicSongRow extends ConsumerWidget {
  const MusicSongRow({
    super.key,
    required this.track,
    required this.index,
    required this.onPlay,
    required this.onRemove,
    this.onMenuRequest,
    this.focusNode,
  });

  final MusicTrack track;
  final int index;
  final VoidCallback onPlay;
  final VoidCallback onRemove;

  /// Right key while focused: the row's context menu. Null keeps plain
  /// traversal (Right then moves the focus sideways).
  final VoidCallback? onMenuRequest;

  /// External node for callers that steer focus programmatically (the playing
  /// row on return from the player). Null keeps DpadFocusable's own.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final state = ref.watch(musicPlayerControllerProvider);
    final isCurrent =
        state.currentMusic?.archive.bvid == track.archive.bvid &&
        state.currentMusic?.part.page == track.part.page;
    final isMulti = track.archive.parts.length > 1;

    return TvFocusable(
      onTap: onPlay,
      onLongPress: onRemove,
      onDirection: onMenuRequest == null
          ? null
          : (direction) {
              if (direction != TraversalDirection.right) return false;
              onMenuRequest!();
              return true;
            },
      focusNode: focusNode,
      builder: (context, focused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          // Content-sized, like the reference's tile: a fixed height overflowed
          // by a pixel once the three text lines scaled past it.
          padding: EdgeInsets.symmetric(horizontal: 14.ts(context), vertical: 10.ts(context)),
          decoration: BoxDecoration(
            color: isCurrent
                ? accent.withValues(alpha: 0.14)
                : focused
                ? tvTheme.cardColor
                : tvTheme.cardColor.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14.ts(context)),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44.ts(context),
                child: isCurrent
                    ? Icon(Icons.graphic_eq_rounded, size: 30.ts(context), color: accent)
                    : Text(
                        '${index + 1}',
                        style: AppTextStyles.t16.copyWith(
                          fontWeight: FontWeight.w500,
                          color: tvTheme.secondaryTextColor,
                        ),
                      ),
              ),
              SizedBox(width: 8.ts(context)),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.ts(context)),
                child: CachedNetworkImage(
                  imageUrl: track.archive.cover,
                  width: 132.ts(context),
                  height: 120.ts(context),
                  fit: BoxFit.cover,
                  memCacheWidth: 320,
                  errorWidget: (_, _, _) => Container(
                    color: accent.withValues(alpha: 0.12),
                    child: Icon(Icons.music_note_rounded, size: 30.ts(context), color: accent),
                  ),
                ),
              ),
              SizedBox(width: 16.ts(context)),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stripTrackOrdinal(track.title),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t18.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isCurrent ? accent : tvTheme.primaryTextColor,
                      ),
                    ),
                    SizedBox(height: 4.ts(context)),
                    Row(
                      children: [
                        Icon(Icons.album_rounded, size: 18.ts(context), color: tvTheme.secondaryTextColor),
                        SizedBox(width: 4.ts(context)),
                        Flexible(
                          child: Text(
                            track.archive.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: tvTheme.secondaryTextColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.ts(context)),
                        Icon(Icons.person_outline_rounded, size: 18.ts(context), color: tvTheme.secondaryTextColor),
                        SizedBox(width: 4.ts(context)),
                        Flexible(
                          child: Text(
                            track.archive.upName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: tvTheme.secondaryTextColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (isMulti) ...[
                      SizedBox(height: 2.ts(context)),
                      Row(
                        children: [
                          Icon(Icons.playlist_play_rounded, size: 18.ts(context), color: tvTheme.secondaryTextColor),
                          SizedBox(width: 4.ts(context)),
                          Text(
                            'P${track.part.page}/${track.archive.parts.length}',
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: tvTheme.secondaryTextColor,
                            ),
                          ),
                          SizedBox(width: 10.ts(context)),
                          Icon(Icons.schedule_rounded, size: 18.ts(context), color: tvTheme.secondaryTextColor),
                          SizedBox(width: 4.ts(context)),
                          Text(
                            MusicVideoCard.formatDuration(
                              track.part.duration > 0 ? track.part.duration : track.archive.duration,
                            ),
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: tvTheme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      SizedBox(height: 2.ts(context)),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 18.ts(context), color: tvTheme.secondaryTextColor),
                          SizedBox(width: 4.ts(context)),
                          Text(
                            MusicVideoCard.formatDuration(track.archive.duration),
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: tvTheme.secondaryTextColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
