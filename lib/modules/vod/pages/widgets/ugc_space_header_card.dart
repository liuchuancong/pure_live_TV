import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/vod/models/models.dart';
class UgcSpaceHeaderCard extends StatelessWidget {
  const UgcSpaceHeaderCard({super.key,required this.info, required this.onToggleFollow});

  final UserSpaceInfo info;
  final VoidCallback onToggleFollow;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.ts(context)),
      padding: EdgeInsets.all(20.ts(context)),
      decoration: BoxDecoration(
        color: tvTheme.cardColor,
        borderRadius: BorderRadius.circular(20.sp),
      ),
      child: Row(
        children: [
          ClipOval(
            child: CachedNetworkImage(
              imageUrl: info.face,
              width: 96.ts(context),
              height: 96.ts(context),
              fit: BoxFit.cover,
              errorWidget: (_, _, _) => Icon(Icons.person_rounded, size: 96.ts(context), color: tvTheme.secondaryTextColor),
            ),
          ),
          SizedBox(width: 20.ts(context)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(info.name, style: AppTextStyles.t24.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor)),
                if (info.sign.isNotEmpty) ...[
                  SizedBox(height: 6.ts(context)),
                  Text(
                    info.sign,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: tvTheme.secondaryTextColor),
                  ),
                ],
                SizedBox(height: 8.ts(context)),
                Row(
                  children: [
                    UgcSpaceStat(label: i18n('video_followers'), value: readableCount(info.followers.toString())),
                    SizedBox(width: 24.ts(context)),
                    UgcSpaceStat(label: i18n('video_following'), value: readableCount(info.following.toString())),
                    SizedBox(width: 24.ts(context)),
                    UgcSpaceStat(label: i18n('video_uploads_title'), value: readableCount(info.videoCount.toString())),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 16.ts(context)),
          TvButton(
            title: i18n(info.isFollowed ? 'video_unfollow' : 'video_follow'),
            icon: Icon(info.isFollowed ? Icons.done_rounded : Icons.add_rounded, size: 24.ts(context)),
            size: TvButtonSize.mini,
            isSecondary: info.isFollowed,
            onTap: onToggleFollow,
          ),
        ],
      ),
    );
  }
}

class UgcSpaceStat extends StatelessWidget {
  const UgcSpaceStat({super.key,required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor)),
        Text(label, style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor)),
      ],
    );
  }
}
