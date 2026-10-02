import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/video/widgets/video_card.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:pure_live/modules/music/widgets/music_video_card.dart';
import 'package:pure_live/modules/video/widgets/video_action_chip.dart';
import 'package:pure_live/modules/vod/domain/providers/vod_providers.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';
import 'package:pure_live/modules/video/controllers/playback/video_progress_controller.dart';
import 'package:pure_live/modules/video/pages/archive/video_detail_dialogs.dart';

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
  List<String> _tags = [];
  bool _isFollowing = false;
  bool _descExpanded = false;

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
      _loadExtras(detail);
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

  /// The detail page's second wave — tags and the follow state — nothing here
  /// gates the page, each read stands on its own.
  Future<void> _loadExtras(MusicArchive detail) async {
    final repo = ref.read(ugcRepositoryProvider);
    final tags = await repo.getArchiveTags(detail.bvid);
    if (!mounted || _detail?.bvid != detail.bvid) return;
    setState(() => _tags = tags);
    if (!BilibiliUgcApi.instance.isLoggedIn || detail.upMid <= 0) return;
    final following = await repo.isFollowing(detail.upMid);
    if (!mounted || _detail?.bvid != detail.bvid) return;
    setState(() => _isFollowing = following);
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

  /// newBV's favourite split: a fresh favourite goes to the default folder in
  /// one press, editing the folder set opens the multi-select picker.
  Future<void> _onFavTap() async {
    if (!_favoured) {
      await _runAction(_toggleFavoured, 'video_action_faved');
      return;
    }
    await _openFavPicker();
  }

  Future<void> _openFavPicker() async {
    if (_actionBusy) return;
    final aid = (_detail ?? widget.archive).aid;
    if (aid <= 0 || !BilibiliUgcApi.instance.isLoggedIn) {
      ToastUtil.show(i18n('video_action_need_login'));
      return;
    }
    final repo = ref.read(ugcRepositoryProvider);
    final folders = await repo.getFavFoldersForVideo(aid);
    if (!mounted || folders.isEmpty) return;
    final selected = await showFavFolderPicker(context, folders);
    if (selected == null || !mounted) return;
    final current = {for (final folder in folders) if (folder.contained) folder.id};
    final add = selected.difference(current).toList();
    final del = current.difference(selected).toList();
    if (add.isEmpty && del.isEmpty) return;
    await _runAction(() => repo.favDeal(aid: aid, addFolderIds: add, delFolderIds: del), 'video_action_faved');
  }

  Future<void> _toggleFollow() async {
    if (_actionBusy) return;
    final mid = (_detail ?? widget.archive).upMid;
    if (mid <= 0) return;
    if (!BilibiliUgcApi.instance.isLoggedIn) {
      ToastUtil.show(i18n('video_action_need_login'));
      return;
    }
    final next = !_isFollowing;
    setState(() => _actionBusy = true);
    try {
      await ref.read(ugcRepositoryProvider).setFollowing(mid, follow: next);
      if (mounted) setState(() => _isFollowing = next);
    } catch (_) {
      if (mounted) ToastUtil.show(i18n('video_action_failed'));
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  /// The part the local watch progress names, when it still belongs to this
  /// archive's list — the "上次看到" jump target.
  ({int index, int position})? get _resumeTarget {
    final archive = _detail ?? widget.archive;
    final entry = ref.read(videoProgressControllerProvider.notifier).entryFor(archive.bvid);
    if (entry == null || entry.cid <= 0) return null;
    for (final (index, track) in archive.tracks.indexed) {
      if (track.part.cid == entry.cid) return (index: index, position: entry.position);
    }
    return null;
  }

  /// Past this many parts the row hands off to the grid dialog, like the
  /// reference app's part-list popup.
  static const int _inlinePartLimit = 5;

  static String _clock(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    final mmss = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return h > 0 ? '$h:$mmss' : mmss;
  }

  Future<void> _playPartsDialog(List<MusicTrack> tracks) async {
    final index = await showPartsGridDialog(context, tracks: tracks, initialIndex: _resumeTarget?.index ?? 0);
    if (index != null) _play(tracks, index);
  }

  void _play(List<MusicTrack> tracks, int startIndex) {
    // Video mode keeps the picture on.
    ref
        .read(musicPlayerControllerProvider.notifier)
        .playQueue(tracks, startIndex: startIndex, audioOnly: false, owner: VodSessionOwner.video);
    const VideoPlayerRoute().push(context);
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final archive = _detail ?? widget.archive;
    final tracks = archive.tracks;
    final resume = _resumeTarget;
    final season = archive.season;
    // Vertical rhythm follows the app font setting: fixed .sp heights clipped
    // their labels the moment the user enlarged the font.

    return TvPageScaffold(
      title: i18n('video_detail_title'),
      child: _error != null && _detail == null
          ? Center(
              child: AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.ts(context)),
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
                        width: 400.ts(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24.ts(context)),
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
                      SizedBox(width: 32.ts(context)),
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
                            SizedBox(height: 10.ts(context)),
                            Text(
                              '${i18n('video_action_played')} ${readableCount(archive.playCount.toString())}'
                              ' · ${i18n('video_danmaku_stat', args: {'count': readableCount(archive.barrageCount.toString())})}'
                              ' · ${archive.publishDate}',
                              style: AppTextStyles.t14.copyWith(
                                fontWeight: FontWeight.w500,
                                color: tvTheme.secondaryTextColor,
                              ),
                            ),
                            if (archive.likeCount > 0 || archive.favCount > 0) ...[
                              SizedBox(height: 6.ts(context)),
                              // newBV's stat row: the interaction counts the
                              // chip labels only hint at.
                              Text(
                                '${i18n('video_action_like')} ${readableCount(archive.likeCount.toString())}'
                                ' · ${i18n('video_action_coin')} ${readableCount(archive.coinCount.toString())}'
                                ' · ${i18n('video_action_fav')} ${readableCount(archive.favCount.toString())}'
                                ' · ${i18n('video_comments_title')} ${readableCount(archive.replyCount.toString())}',
                                style: AppTextStyles.t14.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: tvTheme.secondaryTextColor,
                                ),
                              ),
                            ],
                            SizedBox(height: 16.ts(context)),
                            // The UP row: avatar-led, opens the user space.
                            TvFocusable(
                              onTap: archive.upMid > 0
                                  ? () => UgcUserSpaceRoute(archive.upMid, archive.upName).push(context)
                                  : null,
                              builder: (context, focused, child) => AnimatedContainer(
                                duration: const Duration(milliseconds: 120),
                                padding: EdgeInsets.all(12.ts(context)),
                                decoration: BoxDecoration(
                                  color: focused ? tvTheme.focusedCardColor : tvTheme.cardColor,
                                  borderRadius: BorderRadius.circular(20.ts(context)),
                                  border: Border.all(
                                    color: focused ? accent : Colors.transparent,
                                    width: 2.ts(context),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TvCommonAvatar(avatarUrl: archive.upFace, fallbackName: archive.upName),
                                    SizedBox(width: 12.ts(context)),
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
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      size: 24.ts(context),
                                      color: tvTheme.secondaryTextColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16.ts(context)),
                            // Interaction chips.
                            Wrap(
                              spacing: 10.ts(context),
                              runSpacing: 10.ts(context),
                              children: [
                                if (archive.upMid > 0)
                                  VideoActionChip(
                                    icon: _isFollowing
                                        ? Icons.person_remove_alt_1_rounded
                                        : Icons.person_add_alt_1_rounded,
                                    label: i18n(_isFollowing ? 'video_follow_done' : 'video_follow'),
                                    active: _isFollowing,
                                    onTap: () => _toggleFollow(),
                                  ),
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
                                  // Un-favouriting means editing the folder set,
                                  // so it opens the picker; a fresh favourite
                                  // still takes the default folder in one press.
                                  onTap: () => _onFavTap(),
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
                            if (_tags.isNotEmpty) ...[
                              SizedBox(height: 14.ts(context)),
                              // Tag chips: the reference app sends every tag
                              // to the search endpoint under its name.
                              Wrap(
                                spacing: 10.ts(context),
                                runSpacing: 10.ts(context),
                                children: [
                                  for (final tag in _tags)
                                    TvFocusable(
                                      onTap: () => VideoTagSearchRoute(tag).push(context),
                                      builder: (context, focused, child) => AnimatedContainer(
                                        duration: const Duration(milliseconds: 120),
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 14.ts(context),
                                          vertical: 6.ts(context),
                                        ),
                                        decoration: BoxDecoration(
                                          color: focused ? accent : tvTheme.cardColor,
                                          borderRadius: BorderRadius.circular(999.ts(context)),
                                          border: Border.all(color: focused ? accent : Colors.transparent, width: 1.5.ts(context)),
                                        ),
                                        child: Text(
                                          '#$tag',
                                          style: AppTextStyles.t14.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: focused ? tvTheme.onFocusedCard : tvTheme.secondaryTextColor,
                                          ),
                                        ),
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
                  if (archive.description.isNotEmpty) ...[
                    SizedBox(height: 20.ts(context)),
                    // The description in its own card, like the reference's
                    // grey block under the header.
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18.ts(context)),
                      decoration: BoxDecoration(
                        color: tvTheme.cardColor,
                        borderRadius: BorderRadius.circular(16.ts(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            archive.description,
                            maxLines: _descExpanded ? null : 4,
                            overflow: _descExpanded ? null : TextOverflow.ellipsis,
                            style: AppTextStyles.t14.copyWith(
                              fontWeight: FontWeight.w500,
                              color: tvTheme.secondaryTextColor,
                              height: 1.55,
                            ),
                          ),
                          if (archive.description.length > 120 || archive.description.contains('\n')) ...[
                            SizedBox(height: 8.ts(context)),
                            TvFocusable(
                              onTap: () => setState(() => _descExpanded = !_descExpanded),
                              builder: (context, focused, child) => Text(
                                i18n(_descExpanded ? 'video_desc_collapse' : 'video_desc_expand'),
                                style: AppTextStyles.t14.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: focused ? accent : tvTheme.secondaryTextColor,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  SizedBox(height: 24.ts(context)),
                  // ==================================================== parts
                  Padding(
                    padding: EdgeInsets.only(left: 8.sp, bottom: 12.sp),
                    child: Row(
                      children: [
                        Text(
                          '${i18n('music_tracks_title')}（${tracks.length}）',
                          style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
                        ),
                        SizedBox(width: 16.ts(context)),
                        // Next to the title, not parked at the row's far end:
                        // pressing Down from the button then lands on the
                        // first part instead of hunting across a full-width
                        // row.
                        TvButton(
                          title: i18n('music_play_all'),
                          icon: Icon(Icons.play_circle_fill_rounded, size: 28.ts(context)),
                          size: TvButtonSize.mini,
                          onTap: () => _play(tracks, 0),
                        ),
                        if (resume != null) ...[
                          SizedBox(width: 12.ts(context)),
                          TvButton(
                            title: i18n(
                              'video_last_seen',
                              args: {'page': '${resume.index + 1}', 'time': _clock(resume.position)},
                            ),
                            icon: Icon(Icons.history_rounded, size: 26.ts(context)),
                            size: TvButtonSize.mini,
                            isSecondary: true,
                            onTap: () => _play(tracks, resume.index),
                          ),
                        ],
                        if (tracks.length > _inlinePartLimit) ...[
                          SizedBox(width: 12.ts(context)),
                          TvButton(
                            title: i18n('video_parts_more', args: {'count': '${tracks.length}'}),
                            icon: Icon(Icons.grid_view_rounded, size: 26.ts(context)),
                            size: TvButtonSize.mini,
                            isSecondary: true,
                            onTap: () => _playPartsDialog(tracks),
                          ),
                        ],
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
                      for (final (index, track) in tracks.take(_inlinePartLimit).indexed)
                        Padding(
                          padding: EdgeInsets.only(bottom: 8.sp),
                          child: _PartTile(track: track, index: index, onTap: () => _play(tracks, index)),
                        ),
                    ],
                  ),
                  // ================================================ 合集
                  // ugc_season: the UP's own collection — every section is a
                  // horizontal strip of the other archives it groups.
                  if (season != null)
                    for (final section in season.sections)
                      if (section.episodes.isNotEmpty) ...[
                        SizedBox(height: 24.ts(context)),
                        Padding(
                          padding: EdgeInsets.only(left: 8.sp, bottom: 10.sp),
                          child: Text(
                            season.sections.length == 1 ? season.title : section.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: accent),
                          ),
                        ),
                        SizedBox(
                          height: 260.ts(context) * 9 / 16 + 96.ts(context),
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            padding: EdgeInsets.only(bottom: 16.sp),
                            itemCount: section.episodes.length,
                            separatorBuilder: (_, _) => SizedBox(width: 12.ts(context)),
                            itemBuilder: (context, index) => _SeasonEpisodeCard(
                              episode: section.episodes[index],
                              onTap: () => VideoDetailRoute(section.episodes[index]).push(context),
                            ),
                          ),
                        ),
                      ],
                  if (_related.isNotEmpty) ...[
                    SizedBox(height: 16.ts(context)),
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
                      height: 300.ts(context) * 9 / 16 + 108.ts(context),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: EdgeInsets.only(bottom: 16.sp),
                        itemCount: _related.length,
                        separatorBuilder: (_, _) => SizedBox(width: 12.ts(context)),
                        itemBuilder: (context, index) {
                          final related = _related[index];
                          return SizedBox(
                            width: 300.ts(context),
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

class _SeasonEpisodeCard extends StatelessWidget {
  const _SeasonEpisodeCard({required this.episode, required this.onTap});

  final MusicArchive episode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return SizedBox(
      width: 260.ts(context),
      child: TvFocusable(
        onTap: onTap,
        builder: (context, focused, child) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          decoration: BoxDecoration(
            color: tvTheme.cardColor,
            borderRadius: BorderRadius.circular(14.ts(context)),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Stack(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(12.ts(context))),
                        child: CachedNetworkImage(
                          imageUrl: episode.cover,
                          fit: BoxFit.cover,
                          memCacheWidth: 480,
                          errorWidget: (_, _, _) => Container(color: Colors.black26),
                        ),
                      ),
                    ),
                    if (episode.duration > 0)
                      Positioned(
                        right: 8.sp,
                        bottom: 8.sp,
                        child: TvButton(
                          excludeFocus: true,
                          title: MusicVideoCard.formatDuration(episode.duration),
                          size: TvButtonSize.mini,
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10.ts(context)),
                child: Text(
                  episode.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t14.copyWith(
                    fontWeight: FontWeight.w500,
                    color: focused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor,
                  ),
                ),
              ),
            ],
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
            borderRadius: BorderRadius.circular(18.ts(context)),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40.ts(context),
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
              SizedBox(width: 12.ts(context)),
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
