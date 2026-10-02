part of 'music_now_playing_queue_page.dart';

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

    final queue = state.isMusicSession ? state.queue : const <MusicTrack>[];
    if (queue.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.queue_music_rounded, size: 72.ts(context), color: accent.withValues(alpha: 0.5)),
            SizedBox(height: 14.ts(context)),
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
          padding: EdgeInsets.fromLTRB(20.ts(context), 16.ts(context), 20.ts(context), 10.ts(context)),
          child: Row(
            children: [
              Text(
                '${i18n('music_now_playing')}（${queue.length}）',
                style: AppTextStyles.t24.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor),
              ),
            ],
          ),
        ),
        if (source != null)
          NowPlayingSourceHeader(source: source, track: queue[state.index.clamp(0, queue.length - 1)]),
        Expanded(
          child: DpadRegion(
            verticalEdge: DpadEdgeBehavior.leave,
            horizontalEdge: DpadEdgeBehavior.leave,
            child: ListView.separated(
              padding: EdgeInsets.only(
                left: 20.sp,
                right: 20.sp,
                bottom: 16.sp,
                top: source == null ? 16.ts(context) : 6.ts(context),
              ),
              itemCount: queue.length,
              separatorBuilder: (_, _) => SizedBox(height: 4.ts(context)),
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
                  onRemove: () =>
                      showMusicSongMenu(context, ref, track: track, onDelete: () => controller.removeAt(index)),
                  onMenuRequest: () =>
                      showMusicSongMenu(context, ref, track: track, onDelete: () => controller.removeAt(index)),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  /// The queue's shared source card, or null for a mixed queue.
  NowPlayingQueueSource? _queueSource(List<MusicTrack> queue) {
    final first = queue.first.archive;
    final sameUp = queue.every((t) => t.archive.upName == first.upName);
    if (first.upName.isEmpty || !sameUp) return null;
    // An album queue is one archive (the album title leads); a favourited-UP
    // queue is many archives under one name (the UP name leads, so the
    // subtitle row hides its duplicate).
    final isSingleArchive = queue.every((t) => t.archive.bvid == first.bvid);
    return NowPlayingQueueSource(
      upName: first.upName,
      upFace: first.upFace,
      title: isSingleArchive ? first.title : first.upName,
      showUpName: isSingleArchive,
      isFavorited: ref.read(musicLibraryControllerProvider).favorites.any((a) => a.upMid == first.upMid && a.upMid > 0),
    );
  }
}
