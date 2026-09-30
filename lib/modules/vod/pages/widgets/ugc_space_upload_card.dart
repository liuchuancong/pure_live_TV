import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/video/video_section.dart';
import 'package:cached_network_image/cached_network_image.dart';
class UgcSpaceUploadCard extends StatelessWidget {
  const UgcSpaceUploadCard({super.key,required this.archive, required this.mid});

  final MusicArchive archive;
  final int mid;

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) => TvFocusable(
      onTap: () => openVideoArchive(context, ref, archive),
      builder: (context, focused, child) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        decoration: BoxDecoration(
          color: context.tvTheme.cardColor,
          borderRadius: BorderRadius.circular(14.ts(context)),
          border: Border.all(
            color: focused ? context.tvTheme.focusColor : Colors.transparent,
            width: 2.ts(context),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.vertical(top: Radius.circular(14.ts(context))),
                child: CachedNetworkImage(
                  imageUrl: archive.cover,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  memCacheWidth: 480,
                  errorWidget: (_, _, _) => Container(color: Colors.black26),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(10.ts(context)),
              child: Text(
                archive.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: context.tvTheme.primaryTextColor),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}
