import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/media/models/models.dart';


/// A shared TV comments page for one archive (`x/v2/reply/wbi/main`), used by
/// both music and video modes: hot/newest switch, root list with up to three
/// inline sub-replies, paging on scroll end, comment like when logged in.
class UgcCommentsPage extends ConsumerStatefulWidget {
  const UgcCommentsPage({super.key, required this.oid, this.type = 1, required this.title});

  final int oid;

  /// 1 = video archive comment section.
  final int type;
  final String title;

  @override
  ConsumerState<UgcCommentsPage> createState() => _UgcCommentsPageState();
}

class _UgcCommentsPageState extends ConsumerState<UgcCommentsPage> {
  final ScrollController _scroll = ScrollController();
  final List<CommentItem> _comments = [];
  bool _hot = true;
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load(reset: true);
    _scroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scroll.position.extentAfter < 400 && !_loading && _hasMore) _load();
  }

  Future<void> _load({bool reset = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      if (reset) {
        _page = 1;
        _hasMore = true;
        _error = null;
      }
    });
    try {
      final page = reset ? 1 : _page + 1;
      final (comments, _, hasMore) = await BilibiliUgcApi.instance.getComments(
        oid: widget.oid,
        type: widget.type,
        page: page,
        hot: _hot,
      );
      if (!mounted) return;
      setState(() {
        if (reset) _comments.clear();
        _comments.addAll(comments);
        _page = page;
        _hasMore = hasMore;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _toggleLike(CommentItem comment) async {
    try {
      await BilibiliUgcApi.instance.likeComment(oid: comment.oid, rpid: comment.rpid, like: !comment.liked);
      if (!mounted) return;
      setState(() {
        final at = _comments.indexWhere((c) => c.rpid == comment.rpid);
        if (at >= 0) {
          _comments[at] = CommentItem(
            rpid: comment.rpid,
            oid: comment.oid,
            type: comment.type,
            mid: comment.mid,
            uname: comment.uname,
            face: comment.face,
            content: comment.content,
            ctime: comment.ctime,
            like: comment.like + (comment.liked ? -1 : 1),
            rcount: comment.rcount,
            liked: !comment.liked,
            isTop: comment.isTop,
            isUp: comment.isUp,
            replies: comment.replies,
          );
        }
      });
    } catch (_) {
      ToastUtil.show(i18n('video_action_need_login'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvPageScaffold(
      title: '${i18n('video_comments_title')}（${widget.title}）',
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.ts(context), vertical: 12.ts(context)),
            child: Row(
              children: [
                for (final (index, (label, isHot)) in [
                  (i18n('video_comments_hot'), true),
                  (i18n('video_comments_new'), false),
                ].indexed) ...[
                  TvFocusable(
                    key: ValueKey('comment_sort_$index'),
                    onTap: () {
                      if (_hot == isHot) return;
                      setState(() => _hot = isHot);
                      _load(reset: true);
                    },
                    builder: (context, focused, child) => AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      padding: EdgeInsets.symmetric(horizontal: 24.ts(context), vertical: 10.ts(context)),
                      decoration: BoxDecoration(
                        color: _hot == isHot ? accent.withValues(alpha: 0.22) : tvTheme.cardColor,
                        borderRadius: BorderRadius.circular(24.sp),
                        border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
                      ),
                      child: Text(
                        label,
                        style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, 
                          color: _hot == isHot ? accent : tvTheme.secondaryTextColor,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 14.ts(context)),
                ],
              ],
            ),
          ),
          Expanded(
            child: _error != null && _comments.isEmpty
                ? AppStatusView(type: AppStatusType.error, title: i18n('load_failed'), subtitle: _error)
                : _comments.isEmpty && _loading
                    ? AppStatusView(type: AppStatusType.loading, title: '', subtitle: '')
                    : _comments.isEmpty
                        ? AppStatusView(type: AppStatusType.empty, title: i18n('video_comments_empty'), subtitle: '')
                        : DpadRegion(
                            child: ListView.builder(
                              controller: _scroll,
                              padding: EdgeInsets.only(bottom: 24.ts(context)),
                              itemCount: _comments.length + (_hasMore || _loading ? 1 : 0),
                              itemBuilder: (context, index) {
                                if (index >= _comments.length) {
                                  return Padding(
                                    padding: EdgeInsets.all(20.ts(context)),
                                    child: Center(
                                      child: _loading
                                          ? SizedBox(
                                              width: 32.ts(context),
                                              height: 32.ts(context),
                                              child: CircularProgressIndicator(strokeWidth: 3.sp, color: accent),
                                            )
                                          : Text(
                                              i18n('all_results_loaded'),
                                              style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                                            ),
                                    ),
                                  );
                                }
                                return _CommentTile(comment: _comments[index], onLike: _toggleLike);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

/// One comment row: avatar, name, time, content, like, and the inline
/// sub-reply preview rows.
class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment, required this.onLike});

  final CommentItem comment;
  final void Function(CommentItem) onLike;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.ts(context), vertical: 8.ts(context)),
      padding: EdgeInsets.all(18.ts(context)),
      decoration: BoxDecoration(
        color: tvTheme.cardColor,
        borderRadius: BorderRadius.circular(16.sp),
        border: Border.all(color: comment.isTop ? accent.withValues(alpha: 0.5) : Colors.transparent, width: 1.5.ts(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: CachedNetworkImage(
                  imageUrl: comment.face,
                  width: 44.ts(context),
                  height: 44.ts(context),
                  fit: BoxFit.cover,
                  errorWidget: (_, _, _) => Icon(Icons.person_rounded, size: 44.ts(context), color: tvTheme.secondaryTextColor),
                ),
              ),
              SizedBox(width: 12.ts(context)),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.uname,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: tvTheme.primaryTextColor),
                          ),
                        ),
                        if (comment.isTop) ...[
                          SizedBox(width: 8.ts(context)),
                          Text(i18n('video_comments_top'), style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w600, color: accent)),
                        ],
                      ],
                    ),
                    Text(
                      _timeLabel(comment.ctime),
                      style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12.ts(context)),
              TvFocusable(
                onTap: () => onLike(comment),
                builder: (context, focused, child) => Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.ts(context), vertical: 8.ts(context)),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18.sp),
                    color: comment.liked ? accent.withValues(alpha: 0.2) : Colors.transparent,
                    border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        comment.liked ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                        size: 20.ts(context),
                        color: comment.liked ? accent : tvTheme.secondaryTextColor,
                      ),
                      if (comment.like > 0) ...[
                        SizedBox(width: 6.ts(context)),
                        Text(
                          readableCount(comment.like.toString()),
                          style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.ts(context)),
          SelectableText(
            comment.content,
            style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w500, color: tvTheme.primaryTextColor, height: 1.5),
          ),
          if (comment.replies.isNotEmpty) ...[
            SizedBox(height: 10.ts(context)),
            Container(
              padding: EdgeInsets.all(12.ts(context)),
              decoration: BoxDecoration(
                color: tvTheme.backgroundColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(12.sp),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final reply in comment.replies)
                    Padding(
                      padding: EdgeInsets.only(bottom: 6.ts(context)),
                      child: RichText(
                        text: TextSpan(
                          style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                          children: [
                            TextSpan(
                              text: '${reply.uname}: ',
                              style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w600, color: accent),
                            ),
                            TextSpan(text: reply.content),
                          ],
                        ),
                      ),
                    ),
                  if (comment.rcount > comment.replies.length)
                    Text(
                      '${i18n('video_comments_more_replies')} ${comment.rcount}',
                      style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: accent),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _timeLabel(int seconds) {
    if (seconds <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
