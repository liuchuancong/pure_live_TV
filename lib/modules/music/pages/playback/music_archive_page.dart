import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:pure_live/modules/music/widgets/music_video_card.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';
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
  bool _followingUp = false;
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
      _loadFollowState(detail.upMid);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadFollowState(int mid) async {
    if (mid <= 0) return;
    final api = BilibiliUgcApi.instance;
    if (!api.isLoggedIn) return;
    try {
      final following = await api.isFollowing(mid);
      if (!mounted) return;
      setState(() => _followingUp = following);
    } catch (_) {}
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
  /// fav-deal API only changes what the id lists name, so the old
  /// "add to nothing" call succeeded while storing nothing.
  Future<void> _toggleFavoured() async {
    final folders = await BilibiliUgcApi.instance.getMyFavFolders();
    if (folders.isEmpty) throw Exception('no fav folder');
    final int aid = (_detail ?? widget.archive).aid;
    await BilibiliUgcApi.instance.favDeal(
      aid: aid,
      addFolderIds: _favoured ? const [] : [folders.first.id],
      delFolderIds: _favoured ? [folders.first.id] : const [],
    );
    await _loadStates(aid);
  }

  /// Follow / unfollow this archive's uploader against the account's
  /// relation. No local list: the state is read back through
  /// [BilibiliUgcApi.isFollowing], so it matches the uploader tab and space.
  Future<void> _toggleFollowUp(int mid) async {
    if (mid <= 0) return;
    final unfollowing = _followingUp;
    await _runAction(() async {
      await BilibiliUgcApi.instance.setFollowing(mid, follow: !unfollowing);
      if (mounted) setState(() => _followingUp = !unfollowing);
    }, unfollowing ? 'music_up_unfollowed' : 'music_up_followed');
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
    final followingUp = archive.upMid > 0 && _followingUp;
    final tracks = archive.tracks;
    // Vertical rhythm follows the app font setting, and the whole page scrolls
    // like the video detail page: a fixed-height left column overflowed by
    // hundreds of pixels once the enlarged font met the 720p legibility lift.

    return TvPageScaffold(
      title: i18n('music_archive_title'),
      child: _error != null
          ? Center(
              child: AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error),
            )
          : _detail == null
          ? Center(
              child: AppStatusView(type: AppStatusType.loading, title: '', subtitle: ''),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(24.ts(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ================================================ header row
                  // The video detail page's arrangement: the cover on the
                  // left, the title, stats, UP and the action chips to its
                  // right.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: 400.ts(context),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16.ts(context)),
                          child: AspectRatio(
                            aspectRatio: 16 / 9,
                            child: CachedNetworkImage(imageUrl: archive.cover, fit: BoxFit.cover, memCacheWidth: 720),
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
                            Row(
                              children: [
                                Icon(
                                  Icons.play_circle_outline_rounded,
                                  size: 20.ts(context),
                                  color: tvTheme.secondaryTextColor,
                                ),
                                SizedBox(width: 6.ts(context)),
                                Text(
                                  readableCount(archive.playCount.toString()),
                                  style: AppTextStyles.t14.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: tvTheme.secondaryTextColor,
                                  ),
                                ),
                                SizedBox(width: 16.ts(context)),
                                Icon(
                                  Icons.format_quote_rounded,
                                  size: 20.ts(context),
                                  color: tvTheme.secondaryTextColor,
                                ),
                                SizedBox(width: 6.ts(context)),
                                Text(
                                  readableCount(archive.barrageCount.toString()),
                                  style: AppTextStyles.t14.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: tvTheme.secondaryTextColor,
                                  ),
                                ),
                                if (archive.publishDate.isNotEmpty) ...[
                                  SizedBox(width: 16.ts(context)),
                                  Text(
                                    archive.publishDate,
                                    style: AppTextStyles.t14.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: tvTheme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ],
                            ),
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
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16.ts(context)),
                            // The interaction row, the same actions the video
                            // detail page leads with.
                            Wrap(
                              spacing: 10.ts(context),
                              runSpacing: 10.ts(context),
                              children: [
                                TvButton(
                                  title: i18n('video_action_like'),
                                  icon: Icon(
                                    _liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                                    size: 22.ts(context),
                                  ),
                                  size: TvButtonSize.mini,
                                  isSecondary: !_liked,
                                  onTap: () => _runAction(() async {
                                    await BilibiliUgcApi.instance.setLike(archive.aid, like: !_liked);
                                    setState(() => _liked = !_liked);
                                  }, 'video_action_liked'),
                                ),
                                TvButton(
                                  title: i18n('video_action_fav'),
                                  icon: Icon(
                                    _favoured ? Icons.star_rounded : Icons.star_outline_rounded,
                                    size: 22.ts(context),
                                  ),
                                  size: TvButtonSize.mini,
                                  isSecondary: !_favoured,
                                  onTap: () => _runAction(_toggleFavoured, 'video_action_faved'),
                                ),
                                TvButton(
                                  title: i18n('video_action_triple'),
                                  icon: Icon(Icons.recommend_rounded, size: 22.ts(context)),
                                  size: TvButtonSize.mini,
                                  isSecondary: true,
                                  onTap: () => _runAction(
                                    () => BilibiliUgcApi.instance.tripleAction(archive.aid),
                                    'video_action_trpled',
                                  ),
                                ),
                                TvButton(
                                  title: i18n('video_comments_title'),
                                  icon: Icon(Icons.comment_outlined, size: 22.ts(context)),
                                  size: TvButtonSize.mini,
                                  isSecondary: true,
                                  onTap: archive.aid > 0
                                      ? () => UgcCommentsRoute(
                                          UgcCommentsArgs(oid: archive.aid, title: archive.title),
                                        ).push(context)
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
                                    size: 22.ts(context),
                                  ),
                                  size: TvButtonSize.mini,
                                  isSecondary: !library.isFavorite(archive.bvid),
                                  onTap: () =>
                                      ref.read(musicLibraryControllerProvider.notifier).toggleFavorite(archive),
                                ),
                                if (archive.upMid > 0)
                                  TvButton(
                                    title: i18n(followingUp ? 'music_unfollow_up' : 'music_follow_up'),
                                    icon: Icon(
                                      followingUp ? Icons.person_remove_outlined : Icons.person_add_alt_outlined,
                                      size: 22.ts(context),
                                    ),
                                    size: TvButtonSize.mini,
                                    isSecondary: !followingUp,
                                    onTap: () => _toggleFollowUp(archive.upMid),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (archive.description.isNotEmpty) ...[
                    SizedBox(height: 20.ts(context)),
                    // The description in its own card, like the video
                    // detail page's grey block under the header.
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(18.ts(context)),
                      decoration: BoxDecoration(
                        color: tvTheme.cardColor,
                        borderRadius: BorderRadius.circular(16.ts(context)),
                      ),
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
                        const Spacer(),
                        TvButton(
                          title: i18n('music_play_all'),
                          icon: Icon(Icons.play_circle_fill_rounded, size: 28.ts(context)),
                          size: TvButtonSize.mini,
                          onTap: () => _playAll(tracks, 0),
                        ),
                      ],
                    ),
                  ),
                  if (tracks.length == 1 && tracks.first.part.cid == 0)
                    Text(
                      i18n('music_archive_no_parts'),
                      style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                    )
                  else
                    Column(
                      children: [
                        for (final (index, track) in tracks.indexed)
                          Padding(
                            padding: EdgeInsets.only(bottom: 8.ts(context)),
                            child: _PartTile(track: track, index: index, onTap: () => _playAll(tracks, index)),
                          ),
                      ],
                    ),
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
    // The video detail page's track row: the row's height and its number slot
    // follow the font, or the enlarged label clipped inside the fixed box.
    return TvFocusable(
      onTap: onTap,
      builder: (context, focused, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          height: 76.ts(context),
          padding: EdgeInsets.symmetric(horizontal: 16.ts(context)),
          decoration: BoxDecoration(
            color: tvTheme.cardColor,
            borderRadius: BorderRadius.circular(14.ts(context)),
            border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 40.ts(context),
                child: Text(
                  '${index + 1}',
                  style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                ),
              ),
              Expanded(
                child: Text(
                  _displayTitle(track.title),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: tvTheme.primaryTextColor),
                ),
              ),
              SizedBox(width: 12.ts(context)),
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
