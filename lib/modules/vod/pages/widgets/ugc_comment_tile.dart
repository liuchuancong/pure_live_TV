import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/vod/models/models.dart';

/// The WHOLE row is the focusable — the tile-to-tile walk is what drives the
/// list down the screen; the like count is display-only and OK toggles the
/// like, the one action a comment has. (The old shape had focus only on the
/// like pill, so Down could not leave a row and the list never scrolled.)
class UgcCommentTile extends StatelessWidget {
  const UgcCommentTile({super.key, required this.comment, required this.onLike});

  final CommentItem comment;
  final void Function(CommentItem) onLike;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return TvFocusable(
      onTap: () => onLike(comment),
      builder: (context, focused, child) => Container(
        margin: EdgeInsets.symmetric(
          horizontal: 24.ts(context),
          vertical: 8.ts(context),
        ),
        padding: EdgeInsets.all(18.ts(context)),
        decoration: BoxDecoration(
          color: focused ? tvTheme.focusedCardColor : tvTheme.cardColor,
          borderRadius: BorderRadius.circular(16.sp),
          border: Border.all(
            color: focused
                ? accent
                : (comment.isTop
                      ? accent.withValues(alpha: 0.5)
                      : Colors.transparent),
            width: focused ? 2.ts(context) : 1.5.ts(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: comment.face,
                    width: 52.ts(context),
                    height: 52.ts(context),
                    fit: BoxFit.cover,
                    errorWidget: (_, _, _) => Icon(
                      Icons.person_rounded,
                      size: 52.ts(context),
                      color: tvTheme.secondaryTextColor,
                    ),
                  ),
                ),
                SizedBox(width: 14.ts(context)),
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
                              style: AppTextStyles.t18.copyWith(
                                fontWeight: FontWeight.w600,
                                color: tvTheme.primaryTextColor,
                              ),
                            ),
                          ),
                          if (comment.isTop) ...[
                            SizedBox(width: 8.ts(context)),
                            Text(
                              i18n('video_comments_top'),
                              style: AppTextStyles.t15.copyWith(
                                fontWeight: FontWeight.w600,
                                color: accent,
                              ),
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: 2.ts(context)),
                      Text(
                        _timeLabel(comment.ctime),
                        style: AppTextStyles.t15.copyWith(
                          color: tvTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 12.ts(context)),
                // Display-only: OK on the row performs the like.
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      comment.liked
                          ? Icons.thumb_up_alt_rounded
                          : Icons.thumb_up_alt_outlined,
                      size: 24.ts(context),
                      color: comment.liked
                          ? accent
                          : tvTheme.secondaryTextColor,
                    ),
                    if (comment.like > 0) ...[
                      SizedBox(width: 6.ts(context)),
                      Text(
                        readableCount(comment.like.toString()),
                        style: AppTextStyles.t16.copyWith(
                          fontWeight: FontWeight.w500,
                          color: tvTheme.secondaryTextColor,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
            SizedBox(height: 10.ts(context)),
            Text(
              comment.content,
              style: AppTextStyles.t19.copyWith(
                fontWeight: FontWeight.w500,
                color: tvTheme.primaryTextColor,
                height: 1.5,
              ),
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
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: tvTheme.secondaryTextColor,
                            ),
                            children: [
                              TextSpan(
                                text: '${reply.uname}: ',
                                style: AppTextStyles.t16.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: accent,
                                ),
                              ),
                              TextSpan(text: reply.content),
                            ],
                          ),
                        ),
                      ),
                    if (comment.rcount > comment.replies.length)
                      Text(
                        '${i18n('video_comments_more_replies')} ${comment.rcount}',
                        style: AppTextStyles.t16.copyWith(
                          fontWeight: FontWeight.w500,
                          color: accent,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _timeLabel(int seconds) {
    if (seconds <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}
