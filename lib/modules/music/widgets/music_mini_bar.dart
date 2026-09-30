import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/music/widgets/music_video_card.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';
import 'package:pure_live/modules/music/pages/playlist/music_playlist_dialogs.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';

class MusicMiniBar extends ConsumerWidget {
  const MusicMiniBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(musicPlayerControllerProvider);
    if (!state.hasQueue) return const SizedBox.shrink();
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final library = ref.watch(musicLibraryControllerProvider);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final track = state.current;
    final isLiked = track != null && library.isSongLiked(track.id);
    final double textScale = TvTextScale.factorOf(context);
    return DpadRegion(
      child: Container(
        margin: EdgeInsets.all(12.ts(context) * textScale),
        padding: EdgeInsets.symmetric(horizontal: 16.ts(context) * textScale, vertical: 10.ts(context) * textScale),
        decoration: BoxDecoration(
          color: tvTheme.cardColor,
          borderRadius: BorderRadius.circular(20.ts(context)),
          border: Border.all(color: accent.withValues(alpha: 0.35)),
        ),
        child: StreamBuilder<PlaybackState>(
          stream: controller.playbackStream,
          builder: (context, snapshot) {
            final playback = snapshot.data;
            final position = playback?.position ?? Duration.zero;
            final duration = playback?.duration ?? Duration.zero;
            final isPlaying = playback?.isPlaying ?? false;
            final progress = duration > Duration.zero ? (position.inMilliseconds / duration.inMilliseconds) : 0.0;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TvFocusable(
                        onTap: () => const MusicPlayerRoute().push(context),
                        builder: (context, focused, child) {
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 120),
                            padding: EdgeInsets.symmetric(
                              horizontal: 10.ts(context) * textScale,
                              vertical: 6.ts(context) * textScale,
                            ),
                            decoration: BoxDecoration(
                              color: focused ? accent.withValues(alpha: 0.18) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12.ts(context)),
                              border: Border.all(
                                color: focused ? accent : Colors.transparent,
                                width: 2.ts(context) * textScale,
                              ),
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(30.ts(context)),
                                  child: CachedNetworkImage(
                                    imageUrl: track?.archive.upFace ?? '',
                                    width: 40.ts(context) * textScale,
                                    height: 40.ts(context) * textScale,
                                    fit: BoxFit.cover,
                                    memCacheWidth: 320,
                                    errorWidget: (_, _, _) =>
                                        Icon(Icons.music_note_rounded, size: 28.ts(context), color: accent),
                                  ),
                                ),
                                SizedBox(width: 14.ts(context) * textScale),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        track?.title ?? i18n('music_player_title'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.t18.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: tvTheme.primaryTextColor,
                                        ),
                                      ),
                                      SizedBox(height: 2.ts(context)),
                                      Row(
                                        children: [
                                          SizedBox(width: 10.ts(context)),
                                          Text(
                                            track?.archive.upName ?? '',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: AppTextStyles.t14.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: tvTheme.secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 12.ts(context) * textScale),
                                Text(
                                  '${MusicVideoCard.formatDuration(position.inSeconds)} / ${MusicVideoCard.formatDuration(duration.inSeconds)}',
                                  style: AppTextStyles.t14.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: tvTheme.secondaryTextColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 8.ts(context) * textScale),
                    TvIconButton(
                      icon: Icon(isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                      size: TvIconButtonSize.small,
                      onTap: () {
                        if (track != null) {
                          ref.read(musicLibraryControllerProvider.notifier).toggleLikeSong(track);
                        }
                      },
                    ),
                    SizedBox(width: 6.ts(context) * textScale),
                    TvIconButton(
                      icon: const Icon(Icons.playlist_add_rounded),
                      size: TvIconButtonSize.small,
                      isSecondary: true,
                      onTap: () {
                        final current = state.current;
                        if (current != null) showAddToPlaylistDialog(context, ref, current);
                      },
                    ),
                    SizedBox(width: 6.ts(context) * textScale),
                    TvIconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      size: TvIconButtonSize.small,
                      isSecondary: true,
                      onTap: () => controller.previous(),
                    ),
                    SizedBox(width: 6.ts(context) * textScale),
                    TvIconButton(
                      icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                      size: TvIconButtonSize.medium,
                      onTap: () => controller.togglePlayPause(),
                    ),
                    SizedBox(width: 6.ts(context) * textScale),
                    TvIconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      size: TvIconButtonSize.small,
                      isSecondary: true,
                      onTap: () => controller.next(),
                    ),
                    SizedBox(width: 6.ts(context) * textScale),
                  ],
                ),
                SizedBox(height: 6.ts(context) * textScale),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3.ts(context)),
                  child: LinearProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    minHeight: 6.ts(context),
                    backgroundColor: tvTheme.secondaryTextColor.withValues(alpha: 0.25),
                    color: accent,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
