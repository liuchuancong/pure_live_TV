import 'package:flutter/material.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/media/widgets/music_video_card.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';

/// One archive's track list (its parts), with Play all starting the queue.
///
/// The route may arrive from a grid card that only knows the archive summary;
/// the parts are fetched here, before anything can play, so every queue entry
/// carries a real cid.
class MusicArchivePage extends ConsumerStatefulWidget {
  const MusicArchivePage({super.key, required this.archive});

  final MusicArchive archive;

  @override
  ConsumerState<MusicArchivePage> createState() => _MusicArchivePageState();
}

class _MusicArchivePageState extends ConsumerState<MusicArchivePage> {
  MusicArchive? _detail;
  String? _error;
  bool _liked = false;
  bool _favoured = false;
  bool _actionBusy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await BilibiliMusicApi.instance.getArchiveDetail(widget.archive.bvid);
      if (!mounted) return;
      setState(() => _detail = detail);
      _loadStates(detail.aid);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadStates(int aid) async {
    if (aid <= 0) return;
    final api = BilibiliUgcApi.instance;
    if (!api.isLoggedIn) return;
    final liked = await api.hasLiked(aid);
    final favoured = await api.isFavoured(aid);
    if (!mounted) return;
    setState(() {
      _liked = liked;
      _favoured = favoured;
    });
  }

  Future<void> _runAction(Future<void> Function() action, String successKey) async {
    if (_actionBusy) return;
    final api = BilibiliUgcApi.instance;
    if (!api.isLoggedIn) {
      ToastUtil.show(i18n('video_action_need_login'));
      return;
    }
    setState(() => _actionBusy = true);
    try {
      await action();
      if (mounted) ToastUtil.show(i18n(successKey));
    } catch (_) {
      if (mounted) ToastUtil.show(i18n('video_action_failed'));
    } finally {
      _actionBusy = false;
    }
  }

  void _playAll(List<MusicTrack> tracks, int startIndex) {
    // Music mode listens: the queue starts audio-only, and the player page's
    // toggle brings the picture back on demand.
    ref.read(musicPlayerControllerProvider.notifier).playQueue(tracks, startIndex: startIndex);
    const MusicPlayerRoute().push(context);
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final archive = _detail ?? widget.archive;
    final library = ref.watch(musicLibraryControllerProvider);
    final followingUp = archive.upMid > 0 && library.isFollowingUp(archive.upMid);
    // 跳过分 P: excluded cids vanish from the queue and from this list; when
    // everything is excluded the header's play button simply has nothing to
    // start (bmsc pauses instead of cascade-skipping, and so do we).
    final tracks = library.playableParts(archive);
    final excludedCount = archive.tracks.length - tracks.length;

    return TvPageScaffold(
      title: i18n('music_archive_title'),
      child: _error != null
          ? Center(
              child: AppStatusView(
                type: AppStatusType.error,
                title: i18n('load_failed'),
                subtitle: _error,
              ),
            )
          : _detail == null
              ? Center(child: AppStatusView(type: AppStatusType.loading, title: '', subtitle: ''))
              : Padding(
                  padding: EdgeInsets.all(24.sp),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left column: the archive itself.
                      SizedBox(
                        width: 420.sp,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16.sp),
                              child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: CachedNetworkImage(
                                  imageUrl: archive.cover,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 720,
                                ),
                              ),
                            ),
                            SizedBox(height: 16.sp),
                            Text(
                              archive.title,
                              style: AppTextStyles.t22.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor, height: 1.35),
                            ),
                            SizedBox(height: 10.sp),
                            Row(
                              children: [
                                Icon(Icons.person_outline_rounded, size: 20.sp, color: tvTheme.secondaryTextColor),
                                SizedBox(width: 6.sp),
                                Expanded(
                                  child: Text(
                                    archive.upName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 6.sp),
                            Row(
                              children: [
                                Icon(Icons.play_circle_outline_rounded, size: 20.sp, color: tvTheme.secondaryTextColor),
                                SizedBox(width: 6.sp),
                                Text(
                                  readableCount(archive.playCount.toString()),
                                  style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                                ),
                                SizedBox(width: 16.sp),
                                Icon(Icons.format_quote_rounded, size: 20.sp, color: tvTheme.secondaryTextColor),
                                SizedBox(width: 6.sp),
                                Text(
                                  readableCount(archive.barrageCount.toString()),
                                  style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                                ),
                                if (archive.publishDate.isNotEmpty) ...[
                                  SizedBox(width: 16.sp),
                                  Text(
                                    archive.publishDate,
                                    style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                                  ),
                                ],
                              ],
                            ),
                            SizedBox(height: 14.sp),
                            // The interaction row, the same actions the video
                            // detail page leads with.
                            Wrap(
                              spacing: 10.sp,
                              runSpacing: 10.sp,
                              children: [
                                TvButton(
                                  title: i18n('video_action_like'),
                                  icon: Icon(
                                    _liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                                    size: 22.sp,
                                  ),
                                  size: TvButtonSize.mini,
                                  isSecondary: !_liked,
                                  onTap: () => _runAction(
                                    () async {
                                      await BilibiliUgcApi.instance.setLike(archive.aid, like: !_liked);
                                      setState(() => _liked = !_liked);
                                    },
                                    'video_action_liked',
                                  ),
                                ),
                                TvButton(
                                  title: i18n('video_action_fav'),
                                  icon: Icon(
                                    _favoured ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 22.sp,
                                  ),
                                  size: TvButtonSize.mini,
                                  isSecondary: !_favoured,
                                  onTap: () => _runAction(
                                    () async {
                                      await BilibiliUgcApi.instance.favDeal(aid: archive.aid, addFolderIds: const []);
                                      await _loadStates(archive.aid);
                                    },
                                    'video_action_faved',
                                  ),
                                ),
                                TvButton(
                                  title: i18n('video_action_triple'),
                                  icon: Icon(Icons.recommend_rounded, size: 22.sp),
                                  size: TvButtonSize.mini,
                                  isSecondary: true,
                                  onTap: () => _runAction(
                                    () => BilibiliUgcApi.instance.tripleAction(archive.aid),
                                    'video_action_trpled',
                                  ),
                                ),
                                TvButton(
                                  title: i18n('video_comments_title'),
                                  icon: Icon(Icons.comment_outlined, size: 22.sp),
                                  size: TvButtonSize.mini,
                                  isSecondary: true,
                                  onTap: archive.aid > 0
                                      ? () => UgcCommentsRoute(
                                            UgcCommentsArgs(oid: archive.aid, title: archive.title),
                                          ).push(context)
                                      : null,
                                ),
                                TvButton(
                                  title: i18n('music_skip_parts'),
                                  icon: Icon(Icons.playlist_remove_rounded, size: 22.sp),
                                  size: TvButtonSize.mini,
                                  isSecondary: true,
                                  onTap: archive.tracks.length > 1
                                      ? () => _showExcludedPartsDialog(archive)
                                      : null,
                                ),
                                TvButton(
                                  title: i18n(
                                    library.isFavorite(archive.bvid) ? 'music_unfollow_album' : 'music_follow_album',
                                  ),
                                  icon: Icon(
                                    library.isFavorite(archive.bvid)
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    size: 22.sp,
                                  ),
                                  size: TvButtonSize.mini,
                                  isSecondary: !library.isFavorite(archive.bvid),
                                  onTap: () => ref.read(musicLibraryControllerProvider.notifier).toggleFavorite(archive),
                                ),
                                if (archive.upMid > 0)
                                  TvButton(
                                    title: i18n(followingUp ? 'music_unfollow_up' : 'music_follow_up'),
                                    icon: Icon(
                                      followingUp ? Icons.person_remove_outlined : Icons.person_add_alt_outlined,
                                      size: 22.sp,
                                    ),
                                    size: TvButtonSize.mini,
                                    isSecondary: !followingUp,
                                    onTap: () => ref
                                        .read(musicLibraryControllerProvider.notifier)
                                        .toggleFollowUp(MusicUp(mid: archive.upMid, name: archive.upName, face: archive.upFace)),
                                  ),
                              ],
                            ),
                            if (archive.description.isNotEmpty) ...[
                              SizedBox(height: 12.sp),
                              Expanded(
                                child: SingleChildScrollView(
                                  child: Text(
                                    archive.description,
                                    style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, 
                                      color: tvTheme.secondaryTextColor,
                                      height: 1.5,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      SizedBox(width: 32.sp),
                      // Right column: the parts.
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(left: 8.sp, bottom: 12.sp),
                              child: Row(
                                children: [
                                  Text(
                                    '${i18n('music_tracks_title')}（${tracks.length}${excludedCount > 0 ? '，${i18n('music_parts_skipped')} $excludedCount' : ''}）',
                                    style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
                                  ),
                                  const Spacer(),
                                  TvButton(
                                    title: i18n('music_play_all'),
                                    icon: Icon(Icons.play_circle_fill_rounded, size: 28.sp),
                                    size: TvButtonSize.mini,
                                    onTap: () => _playAll(tracks, 0),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: tracks.length == 1 && tracks.first.part.cid == 0
                                  ? Center(
                                      child: Text(
                                        i18n('music_archive_no_parts'),
                                        style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                                      ),
                                    )
                                  : ListView.separated(
                                      padding: EdgeInsets.only(bottom: 16.sp),
                                      itemCount: tracks.length,
                                      separatorBuilder: (_, _) => SizedBox(height: 8.sp),
                                      itemBuilder: (context, index) {
                                        final track = tracks[index];
                                        return _PartTile(
                                          track: track,
                                          index: index,
                                          onTap: () => _playAll(tracks, index),
                                        );
                                      },
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  /// 跳过分 P: every part of the archive with a state toggle; the choice is
  /// per-archive and survives restarts (the bmsc excluded-parts dialog).
  Future<void> _showExcludedPartsDialog(MusicArchive archive) async {
    final libraryController = ref.read(musicLibraryControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    await TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: i18n('music_skip_parts'),
        cancelText: i18n('cancel'),
        width: 640.sp,
        child: SizedBox(
          height: 480.sp,
          child: StatefulBuilder(
            builder: (context, setDialogState) {
              final excluded = libraryController.excludedCids(archive.bvid).toSet();
              return ListView.builder(
                itemCount: archive.tracks.length,
                itemBuilder: (context, index) {
                  final track = archive.tracks[index];
                  final skipped = excluded.contains(track.part.cid);
                  return TvDialogOptionTile(
                    title: '${index + 1}. ${track.title}',
                    subtitle: i18n(skipped ? 'music_part_excluded' : 'music_part_included'),
                    selected: false,
                    showCheck: false,
                    trailing: Icon(
                      skipped ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                      size: 26.sp,
                      color: skipped ? tvTheme.secondaryTextColor : tvTheme.focusColor,
                    ),
                    onTap: () {
                      libraryController.toggleExcludedPart(archive.bvid, track.part.cid);
                      setDialogState(() {});
                    },
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PartTile extends StatelessWidget {
  const _PartTile({required this.track, required this.index, required this.onTap});

  final MusicTrack track;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          height: 76.sp,
          padding: EdgeInsets.symmetric(horizontal: 16.sp),
          decoration: BoxDecoration(
            color: tvTheme.cardColor,
            borderRadius: BorderRadius.circular(14.sp),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40.sp,
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                ),
              ),
              Expanded(
                child: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.primaryTextColor),
                ),
              ),
              SizedBox(width: 12.sp),
              Text(
                MusicVideoCard.formatDuration(track.part.duration > 0 ? track.part.duration : track.archive.duration),
                style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
              ),
            ],
          ),
        );
      },
    );
  }
}
