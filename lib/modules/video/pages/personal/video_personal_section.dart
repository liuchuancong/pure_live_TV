import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/video/pages/personal/video_fav_pane.dart';
import 'package:pure_live/modules/video/pages/personal/video_follow_pane.dart';
import 'package:pure_live/modules/video/pages/personal/video_toview_pane.dart';
import 'package:pure_live/modules/video/pages/personal/video_bangumi_pane.dart';
import 'package:pure_live/modules/video/pages/personal/video_history_pane.dart';

/// here writes music's Hive keys — the module boundary holds.
class VideoPersonalSection extends ConsumerStatefulWidget {
  const VideoPersonalSection({super.key});

  @override
  ConsumerState<VideoPersonalSection> createState() => _VideoPersonalSectionState();
}

class _VideoPersonalSectionState extends ConsumerState<VideoPersonalSection> {
  // 个人页置顶 Tab (newBV's setting); 关注 stays the landing pane while unset.
  int _tab = SettingsService.to.isInitialized ? SettingsService.to.videoState.personalTabIndex.clamp(0, 4) : 0;

  static const _tabs = [
    ('video_personal_follow', Icons.person_outline_rounded),
    ('video_personal_fav', Icons.favorite_border),
    ('video_personal_history', Icons.history_rounded),
    ('video_personal_toview', Icons.watch_later_outlined),
    ('video_personal_bangumi', Icons.movie_filter_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // newBV's personal top bar: centred pills, one per pane.
        Padding(
          padding: EdgeInsets.only(top: 16.sp, bottom: 8.sp),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (final (index, (label, _)) in _tabs.indexed) ...[
                TvFocusable(
                  key: ValueKey('personal_tab_$index'),
                  onTap: () => setState(() => _tab = index),
                  builder: (context, focused, _) => AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(horizontal: 34.sp, vertical: 12.sp),
                    decoration: BoxDecoration(
                      // The active pill is the tinted one, like the reference.
                      color: _tab == index
                          ? tvTheme.focusColor.withValues(alpha: 0.18)
                          : focused
                          ? tvTheme.focusedCardColor
                          : tvTheme.cardColor,
                      borderRadius: BorderRadius.circular(34.sp),
                      border: Border.all(color: focused ? tvTheme.focusColor : Colors.transparent, width: 2.sp),
                    ),
                    child: Text(
                      i18n(label),
                      style: AppTextStyles.t18.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _tab == index ? tvTheme.focusColor : tvTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 14.sp),
              ],
            ],
          ),
        ),
        Expanded(
          child: switch (_tab) {
            0 => const VideoFollowPane(),
            1 => const VideoFavPane(),
            2 => const VideoHistoryPane(),
            3 => const VideoToViewPane(),
            _ => const VideoBangumiPane(),
          },
        ),
      ],
    );
  }
}

/// The follow list, newBV's 关注列表: the account's followed uploaders as a
/// grid of avatar + name + signature. Tapping opens the UP's space; long-press
/// unfollows (with a confirm) and drops the row.
