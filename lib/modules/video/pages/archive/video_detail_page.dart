import 'package:flutter/material.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/music/widgets/music_video_card.dart';
import 'package:pure_live/modules/video/widgets/video_action_chip.dart';
import 'package:pure_live/modules/vod/domain/providers/vod_providers.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';

/// One archive's page in video mode, newBV's detail screen restyled for the
/// TV grid: a poster with the gradient scrim and cover badges, the avatar-led
/// focused-card palette. The UP row opens the user-space page.
class VideoDetailPage extends ConsumerStatefulWidget {
  const VideoDetailPage({super.key, required this.archive});

  final MusicArchive archive;

  @override
  ConsumerState<VideoDetailPage> createState() => _VideoDetailPageState();
}

class _VideoDetailPageState extends ConsumerState<VideoDetailPage> {
  MusicArchive? _detail;
  List<MusicArchive> _related = [];
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
    try {
      final related = await BilibiliMusicApi.instance.getRelatedVideos(
        aid: widget.archive.aid,
        bvid: widget.archive.bvid,
      );
      if (!mounted) return;
      setState(() => _related = related);
    } catch (_) {
      // The related row is a bonus; its failure must not blank the page.
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

  /// Flips the favoured state against the user's own default folder: the
  /// fav-deal API only changes what the id lists name, so favouriting has to
  /// unfavouriting has to name the same one for removal.
  Future<void> _toggleFavoured() async {
    final folders = await ref.read(ugcRepositoryProvider).getMyFavFolders();
    if (folders.isEmpty) throw Exception('no fav folder');
    final int folderId = folders.first.id;
    final int aid = (_detail ?? widget.archive).aid;
    await ref
        .read(ugcRepositoryProvider)
        .favDeal(
          aid: aid,
          addFolderIds: _favoured ? const [] : [folderId],
          delFolderIds: _favoured ? [folderId] : const [],
        );
    await _loadStates(aid);
  }

  void _play(List<MusicTrack> tracks, int startIndex) {
    // Video mode keeps the picture on.
    ref.read(musicPlayerControllerProvider.notifier).playQueue(tracks, startIndex: startIndex, audioOnly: false);
    const VideoPlayerRoute().push(context);
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final archive = _detail ?? widget.archive;
    final tracks = archive.tracks;
    // Vertical rhythm follows the app font setting: fixed .sp heights clipped
    // their labels the moment the user enlarged the font.

    return TvPageScaffold(
      title: i18n('video_detail_title'),
      child: _error != null && _detail == null
          ? Center(
              child: AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================================================ header row
                  // newBV's detail header: the cover on the left, the title,
                  // the stats, the UP row and the action chips to its right.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 400.sp,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.sp),
                          child: Stack(
                            children: [
                              AspectRatio(
                                aspectRatio: 16 / 9,
                                child: CachedNetworkImage(
                                  imageUrl: archive.cover,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 900,
                                ),
                              ),

                              if (archive.tname.isNotEmpty)
                                Positioned(
                                  left: 14.sp,
                                  top: 14.sp,
                                  child: TvButton(excludeFocus: true, title: archive.tname, size: TvButtonSize.mini),
                                ),
                              if (archive.duration > 0)
                                Positioned(
                                  right: 14.sp,
                                  bottom: 12.sp,
                                  child: TvButton(
                                    excludeFocus: true,
                                    title: MusicVideoCard.formatDuration(archive.duration),
                                    size: TvButtonSize.mini,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: 32.sp),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              archive.title,
                              style: AppTextStyles.t24.copyWith(
                                fontWeight: FontWeight.w700,
                                color: tvTheme.primaryTextColor,
                                height: 1.35,
                              ),
                            ),
                            SizedBox(height: 10.sp),
                            Text(
                              '${i18n('video_action_played')} ${readableCount(archive.playCount.toString())}'
                              ' · ${i18n('video_danmaku_stat', args: {'count': readableCount(archive.barrageCount.toString())})}'
                              ' · ${archive.publishDate}',
                              style: AppTextStyles.t14.copyWith(
                                fontWeight: FontWeight.w500,
                                color: tvTheme.secondaryTextColor,
                              ),
                            ),
                            SizedBox(height: 16.sp),
                            // The UP row: avatar-led, opens the user space.
                            TvFocusable(
                              onTap: archive.upMid > 0
                                  ? () => UgcUserSpaceRoute(archive.upMid, archive.upName).push(context)
                                  : null,
                              builder: (context, focused, child) => AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                padding: EdgeInsets.all(12.sp),
                                decoration: BoxDecoration(
                                  color: focused ? tvTheme.focusedCardColor : tvTheme.cardColor,
                                  borderRadius: BorderRadius.circular(20.sp),
                                  border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TvCommonAvatar(avatarUrl: archive.upFace, fallbackName: archive.upName),
                                    SizedBox(width: 12.sp),
                                    Flexible(
                                      child: Text(
                                        archive.upName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: AppTextStyles.t16.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor,
                                        ),
                                      ),
                                    ),
                                    Icon(Icons.chevron_right_rounded, size: 24.sp, color: tvTheme.secondaryTextColor),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16.sp),
                            // Interaction chips.
                            Wrap(
                              spacing: 10.sp,
                              runSpacing: 10.sp,
                              children: [
                                VideoActionChip(
                                  icon: _liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                                  label: i18n('video_action_like'),
                                  active: _liked,
                                  onTap: () => _runAction(() async {
                                    await ref.read(ugcRepositoryProvider).setLike(archive.aid, like: !_liked);
                                    setState(() => _liked = !_liked);
                                  }, 'video_action_liked'),
                                  // No long-press shortcut here on purpose: a
                                  // focusable with a long-select loses its mouse
                                  // tap (the d-pad layer holds the tap to
                                  // disambiguate the hold), and on the emulator
                                  // has its own chip.
                                ),
                                VideoActionChip(
                                  icon: Icons.toll_rounded,
                                  label: i18n('video_action_coin'),
                                  onTap: () => _runAction(
                                    () => ref.read(ugcRepositoryProvider).addCoin(archive.aid),
                                    'video_action_coined',
                                  ),
                                ),
                                VideoActionChip(
                                  icon: _favoured ? Icons.star_rounded : Icons.star_outline_rounded,
                                  label: i18n('video_action_fav'),
                                  active: _favoured,
                                  // Favouriting needs a real target folder: an
                                  // empty add-folder list is the API's "change
                                  // nothing", so the old call succeeded and
                                  // stored nothing.
                                  onTap: () => _runAction(_toggleFavoured, 'video_action_faved'),
                                ),
                                VideoActionChip(
                                  icon: Icons.recommend_rounded,
                                  label: i18n('video_action_triple'),
                                  onTap: () => _runAction(
                                    () => ref.read(ugcRepositoryProvider).tripleAction(archive.aid),
                                    'video_action_trpled',
                                  ),
                                ),
                                VideoActionChip(
                                  icon: Icons.watch_later_outlined,
                                  label: i18n('video_action_toview'),
                                  onTap: () => _runAction(
                                    () => BilibiliUgcApi.instance.addToView(archive.aid),
                                    'video_action_toviewed',
                                  ),
                                ),
                                VideoActionChip(
                                  icon: Icons.comment_outlined,
                                  label: i18n('video_comments_title'),
                                  onTap: archive.aid > 0
                                      ? () => UgcCommentsRoute(
                                          UgcCommentsArgs(oid: archive.aid, title: archive.title),
                                        ).push(context)
                                      : null,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (archive.description.isNotEmpty) ...[
                    SizedBox(height: 20.sp),
                    // The description in its own card, like the reference's
                    // grey block under the header.
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18.sp),
                      decoration: BoxDecoration(color: tvTheme.cardColor, borderRadius: BorderRadius.circular(16.sp)),
                      child: Text(
                        archive.description,
                        style: AppTextStyles.t14.copyWith(
                          fontWeight: FontWeight.w500,
                          color: tvTheme.secondaryTextColor,
                          height: 1.55,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 24.sp),
                  // ==================================================== parts
                  Padding(
                    padding: EdgeInsets.only(left: 8.sp, bottom: 12.sp),
                    child: Row(
                      children: [
                        Text(
                          '${i18n('music_tracks_title')}（${tracks.length}）',
                          style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
                        ),
                        SizedBox(width: 16.sp),
                        // Next to the title, not parked at the row's far end:
                        // pressing Down from the button then lands on the
                        // first part instead of hunting across a full-width
                        // row.
                        TvButton(
                          title: i18n('music_play_all'),
                          icon: Icon(Icons.play_circle_fill_rounded, size: 28.sp),
                          size: TvButtonSize.mini,
                          onTap: () => _play(tracks, 0),
                        ),
                      ],
                    ),
                  ),
                  // Plain focusables, no wrapping region: the favour detail
                  // page and the player panels prove bare rows in a scroll
                  // view are reachable by the remote, while this page's region
                  // wrapper (a traversal-group boundary) was exactly what the
                  // Down key could not cross.
                  Column(
                    children: [
                      for (final (index, track) in tracks.indexed)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.sp),
                          child: _PartTile(track: track, index: index, onTap: () => _play(tracks, index)),
                        ),
                    ],
                  ),
                  if (_related.isNotEmpty) ...[
                    SizedBox(height: 16.sp),
                    Padding(
                      padding: EdgeInsets.only(left: 8.sp, bottom: 10.sp),
                      child: Text(
                        i18n('video_related_title'),
                        style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
                      ),
                    ),
                    // Bare focusables, no DpadRegion wrapper: the region is a
                    // traversal-group boundary, and the Down key from the last
                    // part row could not enter it at all (while Right sneaked
                    // in at some far card — the wrong-row complaint). The
                    // favour detail page proved bare rows in a scroll view are
                    // reachable, so the cards sit directly in the tree and
                    // Down lands on the first one.
                    SizedBox(
                      height: 300.sp * 9 / 16 + 108.ts(context),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.only(bottom: 16.sp),
                        itemCount: _related.length,
                        separatorBuilder: (_, _) => SizedBox(width: 12.sp),
                        itemBuilder: (context, index) {
                          final related = _related[index];
                          return SizedBox(
                            width: 300.sp,
                            child: VideoCard(archive: related, onTap: () => VideoDetailRoute(related).push(context)),
                          );
                        },
                      ),
                    ),
                  ],
                ],
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

  /// the moment the source skips a number. Leading digits count as an ordinal
  /// only when a separator follows — "24K Magic" keeps its digits.
  static final RegExp _leadingIndex = RegExp(r'^\d{1,4}\s*[.、，,\-–—_:：)·．]\s*');

  static String _displayTitle(String raw) {
    final String stripped = raw.replaceFirst(_leadingIndex, '');
    return stripped.trim().isEmpty ? raw : stripped;
  }

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
          height: 76.ts(context),
          padding: EdgeInsets.symmetric(horizontal: 16.ts(context)),
          decoration: BoxDecoration(
            color: focused ? tvTheme.focusedCardColor : tvTheme.cardColor,
            borderRadius: BorderRadius.circular(18.sp),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40.sp,
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.t18.copyWith(
                    fontWeight: FontWeight.w500,
                    color: focused ? tvTheme.onFocusedCardSecondary : tvTheme.secondaryTextColor,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  _displayTitle(track.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t18.copyWith(
                    fontWeight: FontWeight.w500,
                    color: focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor,
                  ),
                ),
              ),
              SizedBox(width: 12.sp),
              Text(
                MusicVideoCard.formatDuration(track.part.duration > 0 ? track.part.duration : track.archive.duration),
                style: AppTextStyles.t16.copyWith(
                  fontWeight: FontWeight.w500,
                  color: focused ? tvTheme.onFocusedCardSecondary : tvTheme.secondaryTextColor,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
