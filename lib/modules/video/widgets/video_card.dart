import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';

import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/modules/video/controllers/playback/video_progress_controller.dart';




/// The video-mode card, newBV's SmallVideoCard: a 1.6:1 cover with the
/// play/danmaku counts and the duration on a bottom gradient, the title, and
/// the UP · publish-time line under it. The watched-progress line rides the
/// cover's bottom edge. Long-press swaps the cover for the action row
/// (稍后再看 / UP 主页), closing when the card loses focus.
class VideoCard extends ConsumerStatefulWidget {
  const VideoCard({super.key, required this.archive, required this.onTap, this.badge = ''});

  final MusicArchive archive;
  final VoidCallback onTap;

  /// An override label (ranking position, region name); empty falls back to
  /// the archive's region name.
  final String badge;

  @override
  ConsumerState<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends ConsumerState<VideoCard> {
  bool _actionsOpen = false;

  /// "3.2万" style, the same 万-abbreviation the reference uses.
  String _wan(int count) {
    if (count <= 0) return '0';
    if (count >= 100000000) {
      final v = count / 100000000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}亿';
    }
    if (count >= 10000) {
      final v = count / 10000;
      return '${v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 1)}万';
    }
    return '$count';
  }

  String get _durationLabel {
    final total = widget.archive.duration;
    if (total <= 0) return '';
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    String two(int v) => v.toString().padLeft(2, '0');
    return h > 0 ? '$h:${two(m)}:${two(s)}' : '${two(m)}:${two(s)}';
  }

  String get _pubLabel {
    final raw = widget.archive.publishDate.trim();
    return raw.length >= 10 ? raw.substring(0, 10) : raw;
  }

  Future<void> _watchLater() async {
    try {
      await BilibiliUgcApi.instance.addToView(widget.archive.aid);
      ToastUtil.show(i18n('video_action_toviewed'));
    } catch (_) {
      ToastUtil.show(i18n('video_action_need_login'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final archive = widget.archive;
    final progress = ref.watch(
      videoProgressControllerProvider.select((s) => s.entries[archive.bvid]?.percent ?? 0.0),
    );

    final badge = widget.badge.isNotEmpty ? widget.badge : archive.tname;

    return TvFocusable(
      onTap: widget.onTap,
      onLongPress: archive.aid > 0 ? () => setState(() => _actionsOpen = true) : null,
      builder: (context, focused, _) {
        final card = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ----------------------------------------------------- the cover
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1.6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14.sp),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: archive.cover,
                          fit: BoxFit.cover,
                          placeholder: (_, _) => ColoredBox(color: tvTheme.cardColor),
                          errorWidget: (_, _, _) => ColoredBox(color: tvTheme.cardColor),
                        ),
                        // Bottom gradient + stats, newBV's CardCover.
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 64.sp,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.72)],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 10.sp,
                          right: 10.sp,
                          bottom: 6.sp,
                          child: Row(
                            children: [
                              Icon(Icons.play_arrow_rounded, size: 18.sp, color: Colors.white.withValues(alpha: 0.9)),
                              SizedBox(width: 2.sp),
                              Text(
                                _wan(archive.playCount),
                                style: AppTextStyles.t14W500.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                              ),
                              SizedBox(width: 10.sp),
                              Icon(Icons.comment_outlined, size: 16.sp, color: Colors.white.withValues(alpha: 0.9)),
                              SizedBox(width: 2.sp),
                              Text(
                                _wan(archive.barrageCount),
                                style: AppTextStyles.t14W500.copyWith(color: Colors.white.withValues(alpha: 0.9)),
                              ),
                              const Spacer(),
                              if (_durationLabel.isNotEmpty)
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 1.sp),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(6.sp),
                                  ),
                                  child: Text(
                                    _durationLabel,
                                    style: AppTextStyles.t14W600.copyWith(color: Colors.white),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        if (badge.isNotEmpty)
                          Positioned(
                            left: 10.sp,
                            top: 10.sp,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 2.sp),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.55),
                                borderRadius: BorderRadius.circular(8.sp),
                              ),
                              child: Text(
                                badge,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.t14W500.copyWith(color: Colors.white70),
                              ),
                            ),
                          ),
                        // Watched progress along the cover's bottom edge.
                        if (progress > 0)
                          Align(
                            alignment: Alignment.bottomCenter,
                            child: SizedBox(
                              height: 4.sp,
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  ColoredBox(color: Colors.white.withValues(alpha: 0.25)),
                                  FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: progress.clamp(0.0, 1.0),
                                    child: ColoredBox(color: accent),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // Long-press action row, replacing the cover (newBV's
                        // long-press actions: 稍后再看 / UP 主页).
                        if (_actionsOpen)
                          ColoredBox(
                            color: Colors.black.withValues(alpha: 0.82),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                IconButton(
                                  tooltip: i18n('video_action_toview'),
                                  onPressed: _watchLater,
                                  icon: Icon(Icons.watch_later_outlined, size: 30.sp, color: Colors.white),
                                ),
                                IconButton(
                                  tooltip: i18n('video_action_up_page'),
                                  onPressed: archive.upMid > 0
                                      ? () => UgcUserSpaceRoute(archive.upMid, archive.upName).push(context)
                                      : null,
                                  icon: Icon(Icons.person_outline_rounded, size: 30.sp, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (focused)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14.sp),
                          border: Border.all(color: accent, width: 3.sp),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 8.sp),
            // -------------------------------------------------- the info block
            Text(
              archive.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.t14W600.copyWith(
                color: focused ? accent : tvTheme.primaryTextColor,
                height: 1.3,
              ),
            ),
            SizedBox(height: 4.sp),
            Text(
              archive.upName + (_pubLabel.isEmpty ? '' : ' · $_pubLabel'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.t14W300.copyWith(color: tvTheme.secondaryTextColor),
            ),
          ],
        );
        // Losing focus closes the action overlay, like newBV's onFocusChanged.
        if (_actionsOpen && !focused) {
          scheduleMicrotask(() {
            if (mounted && _actionsOpen) setState(() => _actionsOpen = false);
          });
        }
        return card;
      },
    );
  }
}
