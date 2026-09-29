import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';
import 'package:pure_live/modules/music/widgets/music_song_row.dart';
import 'package:pure_live/modules/music/widgets/music_song_menu.dart';
import 'package:pure_live/modules/music/services/music_list_reveal.dart';

/// table, the player page's queue panel at page size.
///
/// When the queue is homogeneous — an album, or a favourited UP's run of
/// videos — the top carries that source's card, the video player page's top
/// bar with a face: the UP avatar, the archive (album) title, the UP name and
/// search results) renders the plain list only.
///
/// Rows are the shared [MusicSongRow]; tap jumps the queue to that track, and
/// the list meets the viewer at the playing row — on entry and whenever the
/// player advances.
class MusicNowPlayingQueuePage extends ConsumerStatefulWidget {
  const MusicNowPlayingQueuePage({super.key});

  @override
  ConsumerState<MusicNowPlayingQueuePage> createState() => _MusicNowPlayingQueuePageState();
}

class _MusicNowPlayingQueuePageState extends ConsumerState<MusicNowPlayingQueuePage> {
  final MusicListReveal _reveal = MusicListReveal();

  @override
  void initState() {
    super.initState();
    // The player advances while the page is open (it keeps playing behind the
    // section shell): meet the viewer at the new playing row.
    ref.listenManual(musicPlayerControllerProvider.select((s) => s.current), (previous, next) {
      if (previous == next) return;
      WidgetsBinding.instance.addPostFrameCallback((_) => _revealCurrent());
    });
  }

  @override
  void dispose() {
    _reveal.dispose();
    super.dispose();
  }

  void _revealCurrent() {
    if (!mounted) return;
    final tracks = ref.read(musicPlayerControllerProvider).queue;
    _reveal.reveal(context, tracks, ref.read(musicPlayerControllerProvider).current);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    final queue = state.queue;
    if (queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_music_rounded, size: 72.sp, color: accent.withValues(alpha: 0.5)),
            SizedBox(height: 14.sp),
            Text(
              i18n('music_queue_empty'),
              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
            ),
          ],
        ),
      );
    }

    final source = _queueSource(queue);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(20.sp, 16.sp, 20.sp, 10.sp),
          child: Row(
            children: [
              Text(
                '${i18n('music_now_playing')}（${queue.length}）',
                style: AppTextStyles.t24.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor),
              ),
            ],
          ),
        ),
        if (source != null) _SourceHeader(source: source, track: queue[state.index.clamp(0, queue.length - 1)]),
        Expanded(
          child: DpadRegion(
            verticalEdge: DpadEdgeBehavior.leave,
            horizontalEdge: DpadEdgeBehavior.leave,
            child: ListView.separated(
              padding: EdgeInsets.only(left: 20.sp, right: 20.sp, bottom: 16.sp, top: source == null ? 16.sp : 6.sp),
              itemCount: queue.length,
              separatorBuilder: (_, _) => SizedBox(height: 4.sp),
              itemBuilder: (context, index) {
                final track = queue[index];
                _reveal.bindRow(track, context);
                return MusicSongRow(
                  track: track,
                  index: index,
                  focusNode: _reveal.nodeFor(track),
                  onPlay: () => controller.jumpTo(index),
                  // Long press and Right both open the shared song menu —
                  // direct removal from a stray hold was too easy to lose a
                  // track to.
                  onRemove: () => showMusicSongMenu(
                    context,
                    ref,
                    track: track,
                    onDelete: () => controller.removeAt(index),
                  ),
                  onMenuRequest: () => showMusicSongMenu(
                    context,
                    ref,
                    track: track,
                    onDelete: () => controller.removeAt(index),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// The queue's shared source card, or null for a mixed queue.
  _QueueSource? _queueSource(List<MusicTrack> queue) {
    final first = queue.first.archive;
    final sameUp = queue.every((t) => t.archive.upName == first.upName);
    if (first.upName.isEmpty || !sameUp) return null;
    // An album queue is one archive (the album title leads); a favourited-UP
    // queue is many archives under one name (the UP name leads, so the
    // subtitle row hides its duplicate).
    final isSingleArchive = queue.every((t) => t.archive.bvid == first.bvid);
    return _QueueSource(
      upName: first.upName,
      upFace: first.upFace,
      title: isSingleArchive ? first.title : first.upName,
      showUpName: isSingleArchive,
      isFavorited: ref
          .read(musicLibraryControllerProvider)
          .favorites
          .any((a) => a.upMid == first.upMid && a.upMid > 0),
    );
  }
}

/// The homogeneous queue's source: one UP (and, for an album, one archive).
class _QueueSource {
  const _QueueSource({
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
class _SourceHeader extends StatelessWidget {
  const _SourceHeader({required this.source, required this.track});

  final _QueueSource source;
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
                          padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 2.sp),
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
