import 'package:dpad/dpad.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';

/// A bilibili archive card in the newBV visual: the cover carries a bottom
/// scrim with the play / danmaku counts and the duration, the title sits below
/// (two lines), then the UP row — the UP chip, the name and the publish date.
/// The live card speaks LiveRoom; this one speaks [MusicArchive].
///
/// Optional [badge] (region / rank label), [progress] (watched fraction, drawn
/// as the cover's bottom bar), [pubTime] (overrides the archive's own publish
/// date in the caption) and [onLongPress] let the video module's grids reuse
/// the same shell.
class MusicVideoCard extends StatelessWidget {
  const MusicVideoCard({
    super.key,
    required this.archive,
    this.onTap,
    this.onLongPress,
    this.badge = '',
    this.progress = 0,
    this.showDuration = true,
    this.pubTime,
  });

  final MusicArchive archive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Static label on the cover's top-left (region name, rank number, percent).
  final String badge;

  /// 0..1 watched fraction; > 0 draws the progress bar on the cover edge.
  final double progress;

  final bool showDuration;

  /// Caption date; null falls back to the archive's own publish date.
  final String? pubTime;

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final borderRadius = BorderRadius.circular(18.sp);

    final List<DpadEffect> effects = [
      DpadScaleEffect(
        scale: 1.02,
        pressedScale: 0.97,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
      ),
      tvTheme.isLight
          ? DpadGlowEffect(color: tvTheme.focusColor, opacity: 1, spreadRadius: 2.sp, blurRadius: 0)
          : DpadGlowEffect(color: tvTheme.focusColor, opacity: 0.75, blurRadius: 18.sp, spreadRadius: 1.5.sp),
      DpadCustomEffect((ctx, state, _) {
        final isFocused = state.focused;
        final titleColor = isFocused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor;
        final secondaryColor = isFocused ? tvTheme.onFocusedCardSecondary : tvTheme.secondaryTextColor;
        final label = badge.isNotEmpty ? badge : archive.tname;
        final date = pubTime ?? archive.publishDate;

        return AnimatedContainer(
          duration: TvFocusStyle.focusDuration(isFocused),
          curve: TvFocusStyle.curve,
          decoration: BoxDecoration(
            color: isFocused ? tvTheme.focusedCardColor : tvTheme.backgroundColor,
            borderRadius: borderRadius,
            border: Border.all(color: isFocused ? tvTheme.focusColor : Colors.transparent, width: 2.sp),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(borderRadius: borderRadius, color: tvTheme.cardColor),
                      child: CachedNetworkImage(
                        imageUrl: archive.cover,
                        fit: BoxFit.cover,
                        memCacheWidth: 640,
                        placeholder: (context, url) => Container(
                          color: tvTheme.cardColor,
                          child: AppStatusView(type: AppStatusType.loading, title: "", subtitle: "", isMini: true),
                        ),
                        errorWidget: (context, url, error) =>
                            AppStatusView(type: AppStatusType.error, title: "", subtitle: "", isMini: true),
                      ),
                    ),
                    // Bottom scrim: the stats stay readable over any artwork.
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        height: 56.sp,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                          ),
                        ),
                      ),
                    ),
                    if (label.isNotEmpty)
                      Positioned(
                        left: 12.sp,
                        top: 12.sp,
                        // Cover chrome, not reading content: the pill keeps its
                        // design size (only the small-panel legibility lift
                        // applies) — at the largest font setting it used to
                        // swallow a third of the artwork.
                        child: MediaQuery(
                          data: MediaQuery.of(context).copyWith(
                            textScaler: TextScaler.linear(TvTextScale.legibilityLift(context)),
                          ),
                          child: TvButton(excludeFocus: true, title: label, size: TvButtonSize.mini),
                        ),
                      ),
                    // The stats row: play and danmaku counts left, duration right.
                    Positioned(
                      left: 10.sp,
                      right: 10.sp,
                      bottom: 8.sp,
                      // Same chrome clamp as the badge: counts and duration
                      // stay at design size over the artwork.
                      child: MediaQuery(
                        data: MediaQuery.of(context).copyWith(
                          textScaler: TextScaler.linear(TvTextScale.legibilityLift(context)),
                        ),
                        child: Row(
                        children: [
                          Icon(Icons.play_circle_outline_rounded, size: 20.sp, color: Colors.white),
                          SizedBox(width: 4.sp),
                          Flexible(
                            child: Text(
                              readableCount(archive.playCount.toString()),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.t14W500.copyWith(color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 10.sp),
                          Icon(Icons.speaker_notes_outlined, size: 18.sp, color: Colors.white),
                          SizedBox(width: 4.sp),
                          Flexible(
                            child: Text(
                              readableCount(archive.barrageCount.toString()),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.t14W500.copyWith(color: Colors.white),
                            ),
                          ),
                          const Spacer(),
                          if (showDuration && archive.duration > 0)
                            Text(
                              formatDuration(archive.duration),
                              style: AppTextStyles.t14W500.copyWith(color: Colors.white),
                            ),
                        ],
                        ),
                      ),
                    ),
                    if (progress > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(
                          value: progress.clamp(0.0, 1.0),
                          minHeight: 4.sp,
                          backgroundColor: Colors.white24,
                          valueColor: AlwaysStoppedAnimation(tvTheme.focusColor),
                        ),
                      ),
                  ],
                ),
              ),
              // Caption: the title over two lines, then the UP row.
              Padding(
                padding: EdgeInsets.fromLTRB(10.sp, 10.sp, 12.sp, 10.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      archive.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t16W600.copyWith(color: titleColor, height: 1.3),
                    ),
                    SizedBox(height: 6.sp),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 5.sp, vertical: 1.sp),
                          decoration: BoxDecoration(
                            color: secondaryColor.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(4.sp),
                          ),
                          child: Text(
                            'UP',
                            style: AppTextStyles.t14W700.copyWith(color: secondaryColor, height: 1.1),
                          ),
                        ),
                        SizedBox(width: 6.sp),
                        Expanded(
                          child: Text(
                            archive.upName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t14W500.copyWith(color: secondaryColor),
                          ),
                        ),
                        if (date.isNotEmpty) ...[
                          SizedBox(width: 8.sp),
                          Text(date, style: AppTextStyles.t14W500.copyWith(color: secondaryColor)),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    ];

    return DpadFocusable(
      autofocus: false,
      effects: effects,
      onSelect: onTap,
      onLongSelect: onLongPress,
      child: const SizedBox(),
    );
  }
}
