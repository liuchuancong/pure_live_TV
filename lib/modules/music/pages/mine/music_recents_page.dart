import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/music/music_section.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/music/widgets/music_song_menu.dart';
import 'package:pure_live/modules/media/widgets/music_video_card.dart';
import 'package:pure_live/modules/music/pages/playback/widgets/player_now_playing_view.dart'
    show stripTrackOrdinal;
import 'package:pure_live/modules/music/services/music_list_reveal.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';

/// 最近播放: the QQ music song-table — index, cover, title+singer, duration —
/// with a Now-playing / Play all / Clear header and long-press removal (the
/// song menu). The liked songs live on the follow page's albums tab.
class MusicRecentsPage extends ConsumerStatefulWidget {
  const MusicRecentsPage({super.key});

  @override
  ConsumerState<MusicRecentsPage> createState() => MusicRecentsPageState();
}

class MusicRecentsPageState extends ConsumerState<MusicRecentsPage> {
  final MusicListReveal _reveal = MusicListReveal();

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const section = MusicSection.recents;
    final library = ref.watch(musicLibraryControllerProvider);
    final libraryController = ref.read(musicLibraryControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final archives = section == MusicSection.favorites ? library.favorites : library.recents;
    final isFavorites = section == MusicSection.favorites;

    final tracks = [for (final archive in archives) ...archive.tracks];

    if (archives.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFavorites ? Icons.favorite_border_rounded : Icons.history_rounded,
              size: 72.sp,
              color: accent.withValues(alpha: 0.5),
            ),
            SizedBox(height: 14.sp),
            Text(
              i18n(isFavorites ? 'music_empty_favorites' : 'music_empty_recents'),
              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.sp, 16.sp, 20.sp, 10.sp),
          child: Row(
            children: [
              Text(
                // The list shows every track of every archive flattened, so the
                // count must be the row count, not the archive count.
                '${i18n(isFavorites ? 'music_favorites' : 'music_recents')}（${tracks.length}）',
                style: AppTextStyles.t24.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor),
              ),
              const Spacer(),
              // One press from anywhere above the long list: the mini bar's
              // destination is the full player anyway.
              TvButton(
                title: i18n('music_now_playing'),
                icon: Icon(Icons.music_note_rounded, size: 24.sp),
                size: TvButtonSize.mini,
                isSecondary: true,
                onTap: () => const MusicPlayerRoute().push(context),
              ),
              SizedBox(width: 12.sp),
              TvButton(
                title: i18n('music_play_all'),
                icon: Icon(Icons.play_circle_fill_rounded, size: 28.sp),
                size: TvButtonSize.mini,
                onTap: () => _play(context, ref, tracks, 0),
              ),
              if (!isFavorites) ...[
                SizedBox(width: 12.sp),
                TvButton(
                  title: i18n('music_clear_recents'),
                  icon: Icon(Icons.delete_outline_rounded, size: 24.sp),
                  size: TvButtonSize.mini,
                  isSecondary: true,
                  onTap: () => libraryController.clearRecents(),
                ),
              ],
            ],
          ),
        ),
        Expanded(
          child: DpadRegion(
            verticalEdge: DpadEdgeBehavior.leave,
            horizontalEdge: DpadEdgeBehavior.leave,
            child: ListView.separated(
              padding: EdgeInsets.only(left: 20.sp, right: 20.sp, bottom: 16.sp, top: 16.sp),
              itemCount: tracks.length,
              separatorBuilder: (_, _) => SizedBox(height: 4.sp),
              itemBuilder: (context, index) {
                final track = tracks[index];
                _reveal.bindRow(track, context);
                return MusicSongRow(
                  track: track,
                  index: index,
                  focusNode: _reveal.nodeFor(track),
                  onPlay: () => _play(context, ref, tracks, index),
                  onRemove: () => showMusicSongMenu(
                    context,
                    ref,
                    track: track,
                    remove: isFavorites ? MusicSongMenuRemove.none : MusicSongMenuRemove.recent,
                    removeLabelKey: 'music_remove_from_recent',
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _play(BuildContext context, WidgetRef ref, List<MusicTrack> tracks, int startIndex) async {
    ref.read(musicPlayerControllerProvider.notifier).playQueue(tracks, startIndex: startIndex);
    await const MusicPlayerRoute().push(context);
    // Back from the player: the list meets the viewer at the playing row.
    if (!mounted) return;
    _reveal.reveal(this.context, tracks, ref.read(musicPlayerControllerProvider).current);
  }
}

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
    final isCurrent = state.current?.archive.bvid == track.archive.bvid && state.current?.part.page == track.part.page;
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
          padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 10.sp),
          decoration: BoxDecoration(
            color: isCurrent
                ? accent.withValues(alpha: 0.14)
                : focused
                ? tvTheme.cardColor
                : tvTheme.cardColor.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14.sp),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44.sp,
                child: isCurrent
                    ? Icon(Icons.graphic_eq_rounded, size: 30.sp, color: accent)
                    : Text(
                        '${index + 1}',
                        style: AppTextStyles.t16.copyWith(
                          fontWeight: FontWeight.w500,
                          color: tvTheme.secondaryTextColor,
                        ),
                      ),
              ),
              SizedBox(width: 8.sp),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.sp),
                child: CachedNetworkImage(
                  imageUrl: track.archive.cover,
                  width: 132.sp,
                  height: 120.sp,
                  fit: BoxFit.cover,
                  memCacheWidth: 320,
                  errorWidget: (_, _, _) => Container(
                    color: accent.withValues(alpha: 0.12),
                    child: Icon(Icons.music_note_rounded, size: 30.sp, color: accent),
                  ),
                ),
              ),
              SizedBox(width: 16.sp),
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
                    SizedBox(height: 4.sp),
                    Row(
                      children: [
                        Icon(Icons.album_rounded, size: 18.sp, color: tvTheme.secondaryTextColor),
                        SizedBox(width: 4.sp),
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
                        SizedBox(width: 10.sp),
                        Icon(Icons.person_outline_rounded, size: 18.sp, color: tvTheme.secondaryTextColor),
                        SizedBox(width: 4.sp),
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
                      SizedBox(height: 2.sp),
                      Row(
                        children: [
                          Icon(Icons.playlist_play_rounded, size: 18.sp, color: tvTheme.secondaryTextColor),
                          SizedBox(width: 4.sp),
                          Text(
                            'P${track.part.page}/${track.archive.parts.length}',
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: tvTheme.secondaryTextColor,
                            ),
                          ),
                          SizedBox(width: 10.sp),
                          Icon(Icons.schedule_rounded, size: 18.sp, color: tvTheme.secondaryTextColor),
                          SizedBox(width: 4.sp),
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
                      SizedBox(height: 2.sp),
                      Row(
                        children: [
                          Icon(Icons.schedule_rounded, size: 18.sp, color: tvTheme.secondaryTextColor),
                          SizedBox(width: 4.sp),
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
