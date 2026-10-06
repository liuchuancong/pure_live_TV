import 'dart:async';
import 'package:media_core/media_core.dart';
import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/vod/pages/widgets/comment_pictures.dart';
import 'package:cached_network_image/cached_network_image.dart';

class VideoCommentsPanel extends StatefulWidget {
  const VideoCommentsPanel({
    super.key,
    required this.oid,
    required this.comments,
    required this.scroll,
    required this.loading,
    required this.hasMore,
    required this.hot,
    required this.onSortChange,
    required this.onLoadMore,
    required this.onClose,
  });

  final int oid;
  final List<CommentItem> comments;
  final ScrollController scroll;
  final bool loading;
  final bool hasMore;

  /// Which sort is on screen — hot (mode 3) or newest (mode 2).
  final bool hot;
  final ValueChanged<bool> onSortChange;
  final VoidCallback onLoadMore;
  final VoidCallback onClose;

  @override
  State<VideoCommentsPanel> createState() => VideoCommentsPanelState();
}

/// newBV's comment surface: every row can be liked, an author carries level and
/// UP badges with any image attachments, and a threaded comment previews three
/// sub-replies first with the full set paged in from the reply endpoint.
class VideoCommentsPanelState extends State<VideoCommentsPanel> {
  final Map<int, ({int like, bool liked})> _likeOverrides = {};
  final Map<int, List<CommentItem>> _replies = {};
  final Map<int, int> _replyPage = {};
  final Set<int> _expanded = {};
  final Set<int> _replyLoading = {};

  int _likeOf(CommentItem c) => _likeOverrides[c.rpid]?.like ?? c.like;
  bool _likedOf(CommentItem c) => _likeOverrides[c.rpid]?.liked ?? c.liked;

  Future<void> _like(CommentItem comment) async {
    final next = !_likedOf(comment);
    setState(() => _likeOverrides[comment.rpid] = (like: _likeOf(comment) + (next ? 1 : -1), liked: next));
    try {
      await BilibiliUgcApi.instance.likeComment(oid: widget.oid, rpid: comment.rpid, like: next);
    } catch (_) {
      if (mounted) setState(() => _likeOverrides.remove(comment.rpid));
    }
  }

  List<CommentItem> _repliesOf(CommentItem comment) => _replies[comment.rpid] ?? comment.replies;

  int _loadedCount(CommentItem comment) => _replies[comment.rpid]?.length ?? comment.replies.length;

  bool _canLoadMore(CommentItem comment) =>
      _expanded.contains(comment.rpid) &&
      !_replyLoading.contains(comment.rpid) &&
      _loadedCount(comment) < comment.rcount;

  Future<void> _toggleReplies(CommentItem comment) async {
    if (!_expanded.remove(comment.rpid)) {
      _expanded.add(comment.rpid);
      if (!_replies.containsKey(comment.rpid) && comment.rcount > comment.replies.length) {
        _replyLoading.add(comment.rpid);
        setState(() {});
        try {
          final replies = await BilibiliUgcApi.instance.getCommentReplies(oid: widget.oid, rpid: comment.rpid);
          if (mounted) {
            setState(() {
              _replies[comment.rpid] = replies;
              _replyPage[comment.rpid] = 1;
            });
          }
        } catch (_) {
          // The preview replies stay on screen when the fetch fails.
        } finally {
          _replyLoading.remove(comment.rpid);
          if (mounted) setState(() {});
        }
        return;
      }
    }
    setState(() {});
  }

  Future<void> _loadMoreReplies(CommentItem comment) async {
    final rpid = comment.rpid;
    if (_replyLoading.contains(rpid)) return;
    final page = (_replyPage[rpid] ?? 1) + 1;
    _replyLoading.add(rpid);
    setState(() {});
    try {
      final more = await BilibiliUgcApi.instance.getCommentReplies(oid: widget.oid, rpid: rpid, page: page);
      if (mounted) {
        final existing = _replies[rpid] ?? const <CommentItem>[];
        final seen = existing.map((e) => e.rpid).toSet();
        setState(() {
          _replies[rpid] = [...existing, ...more.where((e) => !seen.contains(e.rpid))];
          _replyPage[rpid] = page;
        });
      }
    } catch (_) {
      // The already-loaded replies stay; the next focus on "load more" retries.
    } finally {
      _replyLoading.remove(rpid);
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24.ts(context)),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.ts(context)),
            child: Row(
              children: [
                Icon(Icons.comment_outlined, size: 28.ts(context), color: accent),
                SizedBox(width: 10.ts(context)),
                Expanded(
                  child: Text(
                    i18n('video_comments_title'),
                    style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                // newBV's sort switch: hot / newest. The first chip is always
                // mounted (unlike the async comment rows), so it is the
                // deterministic focus claim when the panel opens.
                _SortChip(
                  label: i18n('video_comments_hot'),
                  selected: widget.hot,
                  autofocus: true,
                  onTap: () => widget.onSortChange(true),
                ),
                SizedBox(width: 10.ts(context)),
                _SortChip(
                  label: i18n('video_comments_new'),
                  selected: !widget.hot,
                  autofocus: false,
                  onTap: () => widget.onSortChange(false),
                ),
                SizedBox(width: 14.ts(context)),
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
            child: widget.comments.isEmpty && widget.loading
                ? Center(
                    child: SizedBox(
                      width: 40.ts(context),
                      height: 40.ts(context),
                      child: CircularProgressIndicator(strokeWidth: 3.ts(context), color: accent),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scroll,
                    padding: EdgeInsets.only(left: 16.sp, right: 16.sp, bottom: 16.sp),
                    itemCount: widget.comments.length + (widget.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= widget.comments.length) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (widget.scroll.hasClients && widget.scroll.position.extentAfter < 300) {
                            widget.onLoadMore();
                          }
                        });
                        return Padding(
                          padding: EdgeInsets.all(14.ts(context)),
                          child: Center(
                            child: widget.loading
                                ? SizedBox(
                                    width: 26.ts(context),
                                    height: 26.ts(context),
                                    child: CircularProgressIndicator(strokeWidth: 3.ts(context), color: accent),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }
                      final comment = widget.comments[index];
                      return _CommentTile(
                        comment: comment,
                        autofocus: index == 0,
                        like: _likeOf,
                        liked: _likedOf,
                        onLike: () => unawaited(_like(comment)),
                        expanded: _expanded.contains(comment.rpid),
                        replies: _repliesOf(comment),
                        repliesLoading: _replyLoading.contains(comment.rpid),
                        canLoadMore: _canLoadMore(comment),
                        onToggleReplies: () => unawaited(_toggleReplies(comment)),
                        onLoadMoreReplies: () => unawaited(_loadMoreReplies(comment)),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// The author line, newBV's name + "  Lv.N" (level>0) + "  UP" suffixes.
String _authorLabel(String uname, int level, bool isUp) {
  final buffer = StringBuffer(uname);
  if (level > 0) buffer.write('  Lv.$level');
  if (isUp) buffer.write('  ${i18n('video_comments_up')}');
  return buffer.toString();
}

/// One sort label in the panel header — the live one wears the accent fill.
class _SortChip extends StatelessWidget {
  const _SortChip({required this.label, required this.selected, required this.autofocus, required this.onTap});

  final String label;
  final bool selected;
  final bool autofocus;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = context.tvTheme.focusColor;
    return TvFocusable(
      autofocus: autofocus,
      onTap: onTap,
      builder: (context, focused, _) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: EdgeInsets.symmetric(horizontal: 14.ts(context), vertical: 6.ts(context)),
        decoration: BoxDecoration(
          color: selected ? accent.withValues(alpha: 0.24) : Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12.ts(context)),
          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
        ),
        child: Text(
          label,
          style: AppTextStyles.t14.copyWith(
            fontWeight: FontWeight.w600,
            color: selected ? accent : Colors.white70,
          ),
        ),
      ),
    );
  }
}

/// One comment: the like pill is its own focusable, the thread toggle loads the
/// full sub-reply set, and image attachments open the full-screen viewer.
class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.autofocus,
    required this.comment,
    required this.like,
    required this.liked,
    required this.onLike,
    required this.expanded,
    required this.replies,
    required this.repliesLoading,
    required this.canLoadMore,
    required this.onToggleReplies,
    required this.onLoadMoreReplies,
  });

  /// The panel opens with the keyboard on the first comment's like pill.
  final bool autofocus;
  final CommentItem comment;
  final int Function(CommentItem) like;
  final bool Function(CommentItem) liked;
  final VoidCallback onLike;
  final bool expanded;
  final List<CommentItem> replies;
  final bool repliesLoading;
  final bool canLoadMore;
  final VoidCallback onToggleReplies;
  final VoidCallback onLoadMoreReplies;

  @override
  Widget build(BuildContext context) {
    final accent = context.tvTheme.focusColor;
    final hasThread = comment.rcount > 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8.sp),
      padding: EdgeInsets.all(12.ts(context)),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.ts(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: comment.face,
                  width: 32.ts(context),
                  height: 32.ts(context),
                  fit: BoxFit.cover,
                  errorWidget: (context, url, error) =>
                      Icon(Icons.person_rounded, size: 32.ts(context), color: Colors.white54),
                ),
              ),
              SizedBox(width: 8.ts(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _authorLabel(comment.uname, comment.level, comment.isUp),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w600, color: accent),
                    ),
                    SizedBox(height: 4.ts(context)),
                    Text(
                      comment.content,
                      style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: Colors.white, height: 1.4),
                    ),
                    CommentPicturesRow(urls: comment.pictures, thumbnail: 64),
                  ],
                ),
              ),
              SizedBox(width: 8.ts(context)),
              TvFocusable(
                autofocus: autofocus,
                onTap: onLike,
                builder: (context, focused, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: EdgeInsets.symmetric(horizontal: 10.ts(context), vertical: 4.ts(context)),
                  decoration: BoxDecoration(
                    color: liked(comment)
                        ? accent.withValues(alpha: 0.18)
                        : focused
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.ts(context)),
                    border: Border.all(color: focused ? accent : Colors.transparent, width: 1.5.ts(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        liked(comment) ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                        size: 16.ts(context),
                        color: liked(comment) ? accent : Colors.white54,
                      ),
                      SizedBox(width: 4.ts(context)),
                      Text(
                        readableCount(like(comment).toString()),
                        style: AppTextStyles.t14.copyWith(
                          fontWeight: FontWeight.w500,
                          color: liked(comment) ? accent : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (hasThread) ...[
            SizedBox(height: 6.ts(context)),
            TvFocusable(
              onTap: onToggleReplies,
              builder: (context, focused, _) => Text(
                repliesLoading && replies.isEmpty
                    ? i18n('video_replies_loading')
                    : expanded
                    ? i18n('video_replies_collapse')
                    : i18n('video_replies_expand', args: {'count': '${comment.rcount}'}),
                style: AppTextStyles.t14.copyWith(
                  fontWeight: FontWeight.w500,
                  color: focused ? accent : Colors.white54,
                ),
              ),
            ),
          ],
          if (expanded)
            Padding(
              padding: EdgeInsets.only(left: 18.sp, top: 6.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final reply in replies)
                    Padding(
                      padding: EdgeInsets.only(bottom: 8.sp),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _authorLabel(reply.uname, reply.level, reply.isUp),
                            style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w600, color: accent),
                          ),
                          SizedBox(height: 2.ts(context)),
                          Text(
                            reply.content,
                            style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w300, color: Colors.white70, height: 1.4),
                          ),
                          CommentPicturesRow(urls: reply.pictures, thumbnail: 56),
                        ],
                      ),
                    ),
                  if (repliesLoading && replies.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 6.ts(context)),
                      child: SizedBox(
                        width: 18.ts(context),
                        height: 18.ts(context),
                        child: CircularProgressIndicator(strokeWidth: 2.ts(context), color: accent),
                      ),
                    ),
                  if (canLoadMore)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.ts(context)),
                      child: TvFocusable(
                        onTap: onLoadMoreReplies,
                        builder: (context, focused, _) => Text(
                          i18n('video_replies_more'),
                          style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: focused ? accent : Colors.white54),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
