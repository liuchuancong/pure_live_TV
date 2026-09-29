import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/tv_text_scale.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/media/widgets/music_video_card.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/music/services/music_lyric_service.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';


/// One playlist's track table — the default 喜欢 playlist and every locally
/// created one. OK plays the row, long press opens the song menu (删除 / 置顶 /
/// 清除默认歌词), and the track that is playing right now takes the opening
/// focus while the list scrolls to it.
class MusicUserPlaylistDetailPage extends ConsumerStatefulWidget {
  const MusicUserPlaylistDetailPage({super.key, required this.playlistId});

  final String playlistId;

  @override
  ConsumerState<MusicUserPlaylistDetailPage> createState() => _MusicUserPlaylistDetailPageState();
}

class _MusicUserPlaylistDetailPageState extends ConsumerState<MusicUserPlaylistDetailPage> {
  final ScrollController _scroll = ScrollController();
  final Map<int, FocusNode> _rowNodes = {};
  bool _steeredFocus = false;

  bool get _isLiked => widget.playlistId == MusicLibraryController.likedPlaylistId;

  FocusNode _nodeAt(int index) => _rowNodes.putIfAbsent(index, FocusNode.new);

  @override
  void dispose() {
    _scroll.dispose();
    for (final node in _rowNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Puts the opening highlight on the playing row: jump near it by the fixed
  /// row extent, then focus it — DpadFocusable reveals the focused row, so the
  /// list settles on it even when the estimate was off by a little.
  void _steerToPlaying(List<MusicTrack> tracks, String playingId) {
    _steeredFocus = true;
    final at = tracks.indexWhere((t) => t.id == playingId);
    if (at < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_scroll.hasClients && at > 6) {
        _scroll.jumpTo((at * 88.0).sp);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _nodeAt(at).requestFocus();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final library = ref.watch(musicLibraryControllerProvider);
    final playerState = ref.watch(musicPlayerControllerProvider);
    final tvTheme = context.tvTheme;

    final MusicUserPlaylist? playlist = _isLiked
        ? null
        : library.playlists.where((p) => p.id == widget.playlistId).firstOrNull;
    if (!_isLiked && playlist == null) {
      return TvPageScaffold(
        title: i18n('music_local_playlists'),
        child: Center(child: AppStatusView(type: AppStatusType.empty, title: i18n('music_playlist_deleted'))),
      );
    }

    final String name = _isLiked ? i18n('music_liked_playlist') : playlist!.name;
    final List<MusicTrack> tracks = _isLiked ? library.likedSongs : playlist!.tracks;
    final playingId = playerState.current?.id ?? '';
    if (!_steeredFocus && playingId.isNotEmpty && tracks.any((t) => t.id == playingId)) {
      _steerToPlaying(tracks, playingId);
    }

    return TvPageScaffold(
      title: name,
      child: tracks.isEmpty
          ? Center(child: AppStatusView(type: AppStatusType.empty, title: i18n('music_empty_playlist')))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(20.ts(context), 16.ts(context), 20.ts(context), 10.ts(context)),
                  child: Row(
                    children: [
                      Text('（${tracks.length}）', style: AppTextStyles.t22.copyWith(fontWeight: FontWeight.w700, color: tvTheme.secondaryTextColor)),
                      const Spacer(),
                      TvButton(
                        title: i18n('music_now_playing'),
                        icon: Icon(Icons.music_note_rounded, size: 24.ts(context)),
                        size: TvButtonSize.mini,
                        isSecondary: true,
                        onTap: () => const MusicPlayerRoute().push(context),
                      ),
                      SizedBox(width: 12.ts(context)),
                      TvButton(
                        title: i18n('music_play_all'),
                        icon: Icon(Icons.play_circle_fill_rounded, size: 28.ts(context)),
                        size: TvButtonSize.mini,
                        onTap: tracks.isEmpty ? null : () => _play(context, ref, tracks, 0),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: DpadRegion(
                    verticalEdge: DpadEdgeBehavior.leave,
                    horizontalEdge: DpadEdgeBehavior.leave,
                    child: ListView.separated(
                      controller: _scroll,
                      padding: EdgeInsets.only(left: 20.ts(context), right: 20.ts(context), bottom: 16.ts(context), top: 16.ts(context)),
                      itemCount: tracks.length,
                      separatorBuilder: (_, _) => SizedBox(height: 4.ts(context)),
                      itemBuilder: (context, index) {
                        final track = tracks[index];
                        final isCurrent = playingId == track.id;
                        return _PlaylistTrackRow(
                          track: track,
                          index: index,
                          isCurrent: isCurrent,
                          focusNode: _nodeAt(index),
                          onPlay: () => _play(context, ref, tracks, index),
                          onLongPress: () => _showSongMenu(context, ref, track, index),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _play(BuildContext context, WidgetRef ref, List<MusicTrack> tracks, int startIndex) {
    ref.read(musicPlayerControllerProvider.notifier).playQueue(tracks, startIndex: startIndex);
    const MusicPlayerRoute().push(context);
  }

  /// Long press on a song: 删除 (unlike / remove from this playlist), 置顶,
  /// and — when the viewer once picked a default lyric for it — clearing that
  /// choice back to the automatic chain.
  Future<void> _showSongMenu(BuildContext context, WidgetRef ref, MusicTrack track, int index) async {
    final libraryController = ref.read(musicLibraryControllerProvider.notifier);
    final hasDefaultLyric = MusicLyricService.instance.manualLyric(track.title) != null;

    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: track.title,
        cancelText: i18n('cancel'),
        width: 560.ts(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TvDialogOptionTile(
              title: i18n(_isLiked ? 'music_song_unliked' : 'music_remove_from_playlist'),
              icon: Icon(Icons.delete_outline_rounded, size: 26.ts(context)),
              showCheck: false,
              autofocus: true,
              onTap: () {
                Navigator.of(context).pop();
                if (_isLiked) {
                  libraryController.removeLikedSong(track.id);
                  ToastUtil.show(i18n('music_song_unliked'));
                } else {
                  libraryController.removeTrackFromPlaylist(widget.playlistId, track.id);
                  ToastUtil.show(i18n('music_removed_from_playlist'));
                }
              },
            ),
            TvDialogOptionTile(
              title: i18n('music_pin'),
              icon: Icon(Icons.vertical_align_top_rounded, size: 26.ts(context)),
              showCheck: false,
              onTap: () {
                Navigator.of(context).pop();
                if (_isLiked) {
                  libraryController.pinLikedSong(track.id);
                } else {
                  libraryController.moveTrackInPlaylist(widget.playlistId, index, -index);
                }
                ToastUtil.show(i18n('music_pinned'));
              },
            ),
            if (hasDefaultLyric)
              TvDialogOptionTile(
                title: i18n('music_clear_default_lyric'),
                icon: Icon(Icons.lyrics_outlined, size: 26.ts(context)),
                showCheck: false,
                onTap: () {
                  Navigator.of(context).pop();
                  MusicLyricService.instance.clearManualLyric(track.title);
                  ToastUtil.show(i18n('music_lyric_cleared'));
                },
              ),
          ],
        ),
      ),
    );
  }
}

/// One playlist entry in the bmsc TrackTile shape: wide cover, title with the
/// duration, the album-over-author metadata line, and the playing track
/// accented. Long press opens the song menu.
class _PlaylistTrackRow extends StatelessWidget {
  const _PlaylistTrackRow({
    required this.track,
    required this.index,
    required this.isCurrent,
    required this.focusNode,
    required this.onPlay,
    required this.onLongPress,
  });

  final MusicTrack track;
  final int index;
  final bool isCurrent;
  final FocusNode focusNode;
  final VoidCallback onPlay;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvFocusable(
      onTap: onPlay,
      onLongPress: onLongPress,
      focusNode: focusNode,
      builder: (context, focused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          padding: EdgeInsets.symmetric(horizontal: 14.ts(context), vertical: 10.ts(context)),
          decoration: BoxDecoration(
            color: isCurrent
                ? accent.withValues(alpha: 0.14)
                : focused
                ? tvTheme.cardColor
                : tvTheme.cardColor.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(14.sp),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 44.ts(context),
                child: isCurrent
                    ? Icon(Icons.graphic_eq_rounded, size: 30.ts(context), color: accent)
                    : Text('${index + 1}', style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor)),
              ),
              SizedBox(width: 8.ts(context)),
              ClipRRect(
                borderRadius: BorderRadius.circular(10.sp),
                child: CachedNetworkImage(
                  imageUrl: track.archive.cover,
                  width: 132.ts(context),
                  height: 84.ts(context),
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
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            track.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, 
                              color: isCurrent ? accent : tvTheme.primaryTextColor,
                            ),
                          ),
                        ),
                        SizedBox(width: 10.ts(context)),
                        Icon(Icons.schedule_rounded, size: 18.ts(context), color: tvTheme.secondaryTextColor),
                        SizedBox(width: 4.ts(context)),
                        Text(
                          MusicVideoCard.formatDuration(
                            track.part.duration > 0 ? track.part.duration : track.archive.duration,
                          ),
                          style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                        ),
                      ],
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
                            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
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
                            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                          ),
                        ),
                      ],
                    ),
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
