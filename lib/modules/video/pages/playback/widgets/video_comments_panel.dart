import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_core/media_core.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/api/bilibili_ugc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class VideoCommentsPanel extends StatefulWidget {
  const VideoCommentsPanel({
    super.key,
    required this.oid,
    required this.comments,
    required this.scroll,
    required this.loading,
    required this.hasMore,
    required this.onLoadMore,
    required this.onClose,
  });

  final int oid;
  final List<CommentItem> comments;
  final ScrollController scroll;
  final bool loading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final VoidCallback onClose;

  @override
  State<VideoCommentsPanel> createState() => VideoCommentsPanelState();
}

/// newBV's comment surface: every row can be liked, and a comment with
/// carries first, the full set fetched from the reply endpoint on expand.
class VideoCommentsPanelState extends State<VideoCommentsPanel> {
  final Map<int, ({int like, bool liked})> _likeOverrides = {};
  final Map<int, List<CommentItem>> _replies = {};
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

  Future<void> _toggleReplies(CommentItem comment) async {
    if (!_expanded.remove(comment.rpid)) {
      _expanded.add(comment.rpid);
      if (!_replies.containsKey(comment.rpid) && comment.rcount > comment.replies.length) {
        _replyLoading.add(comment.rpid);
        setState(() {});
        try {
          final replies = await BilibiliUgcApi.instance.getCommentReplies(oid: widget.oid, rpid: comment.rpid);
          if (mounted) setState(() => _replies[comment.rpid] = replies);
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

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24.sp),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.sp),
            child: Row(
              children: [
                Icon(Icons.comment_outlined, size: 28.sp, color: accent),
                SizedBox(width: 10.sp),
                Expanded(
                  child: Text(
                    i18n('video_comments_title'),
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
            child: widget.comments.isEmpty && widget.loading
                ? Center(
                    child: SizedBox(
                      width: 40.sp,
                      height: 40.sp,
                      child: CircularProgressIndicator(strokeWidth: 3.sp, color: accent),
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
                          padding: EdgeInsets.all(14.sp),
                          child: Center(
                            child: widget.loading
                                ? SizedBox(
                                    width: 26.sp,
                                    height: 26.sp,
                                    child: CircularProgressIndicator(strokeWidth: 3.sp, color: accent),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }
                      return _CommentTile(
                        comment: widget.comments[index],
                        oid: widget.oid,
                        autofocus: index == 0,
                        like: _likeOf,
                        liked: _likedOf,
                        onLike: () => unawaited(_like(widget.comments[index])),
                        expanded: _expanded.contains(widget.comments[index].rpid),
                        replies: _repliesOf(widget.comments[index]),
                        repliesLoading: _replyLoading.contains(widget.comments[index].rpid),
                        onToggleReplies: () => unawaited(_toggleReplies(widget.comments[index])),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// One comment: body OK opens the thread, the like pill is its own focusable.
class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.autofocus,
    required this.comment,
    required this.oid,
    required this.like,
    required this.liked,
    required this.onLike,
    required this.expanded,
    required this.replies,
    required this.repliesLoading,
    required this.onToggleReplies,
  });

  /// The panel opens with the keyboard on the first comment's like pill.
  final bool autofocus;
  final CommentItem comment;
  final int oid;
  final int Function(CommentItem) like;
  final bool Function(CommentItem) liked;
  final VoidCallback onLike;
  final bool expanded;
  final List<CommentItem> replies;
  final bool repliesLoading;
  final VoidCallback onToggleReplies;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final hasThread = comment.rcount > 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8.sp),
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.uname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w600, color: accent),
                ),
              ),
              TvFocusable(
                autofocus: autofocus,
                onTap: onLike,
                builder: (context, focused, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
                  decoration: BoxDecoration(
                    color: liked(comment)
                        ? accent.withValues(alpha: 0.18)
                        : focused
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.sp),
                    border: Border.all(color: focused ? accent : Colors.transparent, width: 1.5.sp),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        liked(comment) ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                        size: 16.sp,
                        color: liked(comment) ? accent : Colors.white54,
                      ),
                      SizedBox(width: 4.sp),
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
          SizedBox(height: 6.sp),
          Text(
            comment.content,
            style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: Colors.white, height: 1.4),
          ),
          if (hasThread) ...[
            SizedBox(height: 6.sp),
            TvFocusable(
              onTap: onToggleReplies,
              builder: (context, focused, _) => Text(
                repliesLoading
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
                      padding: EdgeInsets.only(bottom: 4.sp),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${reply.uname}: ',
                              style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w600, color: accent),
                            ),
                            TextSpan(
                              text: reply.content,
                              style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w300, color: Colors.white70),
                            ),
                          ],
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
