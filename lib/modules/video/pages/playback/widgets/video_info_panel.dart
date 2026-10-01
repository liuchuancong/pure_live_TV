import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/video/widgets/video_action_chip.dart';
import 'package:pure_live/modules/video/pages/archive/video_detail_dialogs.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// The player's 视频信息 panel — newBV's ControllerVideoInfo action row: the
/// archive header (cover, title, UP and stats), the triple-action controls
/// (点赞/投币/收藏/一键三连) and the jumps to the detail page and the UP's
/// space, all without leaving the playing surface.
class VideoInfoPanel extends StatefulWidget {
  const VideoInfoPanel({super.key, required this.archive, required this.onClose});

  final MusicArchive archive;
  final VoidCallback onClose;

  @override
  State<VideoInfoPanel> createState() => _VideoInfoPanelState();
}

class _VideoInfoPanelState extends State<VideoInfoPanel> {
  bool _liked = false;
  bool _favoured = false;
  bool _busy = false;

  int get _aid => widget.archive.aid;

  @override
  void initState() {
    super.initState();
    _loadStates();
  }

  Future<void> _loadStates() async {
    if (_aid <= 0 || !BilibiliUgcApi.instance.isLoggedIn) return;
    try {
      final liked = await BilibiliUgcApi.instance.hasLiked(_aid);
      final favoured = await BilibiliUgcApi.instance.isFavoured(_aid);
      if (mounted) setState(() => _liked = liked);
      if (mounted) setState(() => _favoured = favoured);
    } catch (_) {
      // The default (untouched) state stays; the actions still run on demand.
    }
  }

  Future<void> _run(Future<void> Function() action, String successKey) async {
    if (_aid <= 0) return;
    if (!BilibiliUgcApi.instance.isLoggedIn) {
      ToastUtil.show(i18n('video_action_need_login'));
      return;
    }
    setState(() => _busy = true);
    try {
      await action();
      if (mounted) ToastUtil.show(i18n(successKey));
    } catch (_) {
      if (mounted) ToastUtil.show(i18n('video_action_failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Un-favouriting means editing the folder set, so it opens the picker; a
  /// fresh favourite still takes the default folder in one press.
  Future<void> _onFavTap() async {
    if (_busy) return;
    if (_aid <= 0 || !BilibiliUgcApi.instance.isLoggedIn) {
      ToastUtil.show(i18n('video_action_need_login'));
      return;
    }
    if (!_favoured) {
      await _run(() async {
        final folders = await BilibiliUgcApi.instance.getMyFavFolders();
        if (folders.isEmpty) throw Exception('no fav folder');
        await BilibiliUgcApi.instance.favDeal(aid: _aid, addFolderIds: [folders.first.id]);
        if (mounted) setState(() => _favoured = true);
      }, 'video_action_faved');
      return;
    }
    final folders = await BilibiliUgcApi.instance.getFavFoldersForVideo(_aid);
    if (!mounted || folders.isEmpty) return;
    final selected = await showFavFolderPicker(context, folders);
    if (selected == null || !mounted) return;
    final current = {for (final folder in folders) if (folder.contained) folder.id};
    final add = selected.difference(current).toList();
    final del = current.difference(selected).toList();
    if (add.isEmpty && del.isEmpty) return;
    await _run(
      () => BilibiliUgcApi.instance.favDeal(aid: _aid, addFolderIds: add, delFolderIds: del),
      'video_action_faved',
    );
    if (mounted) setState(() => _favoured = selected.isNotEmpty);
  }

  String _count(int value) => readableCount(value.toString());

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final archive = widget.archive;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24.ts(context)),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.ts(context)),
            child: Row(
              children: [
                Icon(Icons.info_outline_rounded, size: 28.ts(context), color: accent),
                SizedBox(width: 10.ts(context)),
                Expanded(
                  child: Text(
                    i18n('video_info'),
                    style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                TvIconButton(
                  icon: const Icon(Icons.close_rounded),
                  size: TvIconButtonSize.small,
                  isSecondary: true,
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(left: 20.ts(context), right: 20.ts(context), bottom: 20.ts(context)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Cover + title + stats.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 200.ts(context),
                        height: 120.ts(context),
                        clipBehavior: Clip.antiAlias,
                        decoration: BoxDecoration(
                          color: tvTheme.cardColor,
                          borderRadius: BorderRadius.circular(12.ts(context)),
                        ),
                        child: CachedNetworkImage(
                          imageUrl: archive.cover,
                          fit: BoxFit.cover,
                          memCacheWidth: 480,
                          errorWidget: (context, url, error) =>
                              Icon(Icons.broken_image_outlined, color: tvTheme.secondaryTextColor),
                        ),
                      ),
                      SizedBox(width: 14.ts(context)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              archive.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            SizedBox(height: 8.ts(context)),
                            Wrap(
                              spacing: 14.ts(context),
                              runSpacing: 4.ts(context),
                              children: [
                                _Stat(icon: Icons.play_arrow_rounded, value: _count(archive.playCount)),
                                _Stat(icon: Icons.comment_outlined, value: _count(archive.barrageCount)),
                                _Stat(icon: Icons.thumb_up_alt_outlined, value: _count(archive.likeCount)),
                                _Stat(icon: Icons.toll_rounded, value: _count(archive.coinCount)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16.ts(context)),

                  // UP row — tap jumps to the space.
                  TvFocusable(
                    onTap: archive.upMid > 0
                        ? () => UgcUserSpaceRoute(archive.upMid, archive.upName).push(context)
                        : null,
                    builder: (context, focused, _) => Container(
                      padding: EdgeInsets.all(10.ts(context)),
                      decoration: BoxDecoration(
                        color: focused ? tvTheme.focusedCardColor : Colors.white.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12.ts(context)),
                        border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                            child: CachedNetworkImage(
                              imageUrl: archive.upFace,
                              width: 40.ts(context),
                              height: 40.ts(context),
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) =>
                                  Icon(Icons.person_rounded, size: 40.ts(context), color: Colors.white54),
                            ),
                          ),
                          SizedBox(width: 10.ts(context)),
                          Expanded(
                            child: Text(
                              archive.upName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded, color: focused ? accent : Colors.white54),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 16.ts(context)),

                  // Triple-action + jump row.
                  Wrap(
                    spacing: 10.ts(context),
                    runSpacing: 10.ts(context),
                    children: [
                      VideoActionChip(
                        autofocus: true,
                        icon: _liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                        label: i18n('video_action_like'),
                        active: _liked,
                        onTap: _busy
                            ? null
                            : () => _run(() async {
                                  await BilibiliUgcApi.instance.setLike(_aid, like: !_liked);
                                  if (mounted) setState(() => _liked = !_liked);
                                }, 'video_action_liked'),
                      ),
                      VideoActionChip(
                        icon: Icons.toll_rounded,
                        label: i18n('video_action_coin'),
                        onTap: _busy ? null : () => _run(() => BilibiliUgcApi.instance.addCoin(_aid), 'video_action_coined'),
                      ),
                      VideoActionChip(
                        icon: _favoured ? Icons.star_rounded : Icons.star_outline_rounded,
                        label: i18n('video_action_fav'),
                        active: _favoured,
                        onTap: _busy ? null : _onFavTap,
                      ),
                      VideoActionChip(
                        icon: Icons.recommend_rounded,
                        label: i18n('video_action_triple'),
                        onTap: _busy
                            ? null
                            : () => _run(
                                  () => BilibiliUgcApi.instance.tripleAction(_aid),
                                  'video_action_trpled',
                                ),
                      ),
                      VideoActionChip(
                        icon: Icons.menu_book_rounded,
                        label: i18n('video_detail_title'),
                        onTap: () => VideoDetailRoute(archive).push(context),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// One display-only stat: a glyph and its readable count.
class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16.ts(context), color: Colors.white54),
        SizedBox(width: 4.ts(context)),
        Text(value, style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: Colors.white70)),
      ],
    );
  }
}
