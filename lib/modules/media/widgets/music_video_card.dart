import 'package:dpad/dpad.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';

/// A bilibili archive card in the shared [TvRoomCard] visual language: the
/// same dpad focus effects, the same focused-card palette, a cover with
/// corner badges and an avatar-led info row. The live card speaks LiveRoom;
/// this one speaks [MusicArchive] — cover, title, who made it.
///
/// Optional [badge] (region / rank label), [progress] (watched fraction,
/// drawn as the cover's bottom bar) and [onLongPress] let the video module's
/// grids reuse the same shell.
class MusicVideoCard extends StatelessWidget {
  const MusicVideoCard({
    super.key,
    required this.archive,
    this.onTap,
    this.onLongPress,
    this.badge = '',
    this.progress = 0,
    this.showDuration = true,
  });

  final MusicArchive archive;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// Static label on the cover's top-left (region name, rank number, percent).
  final String badge;

  /// 0..1 watched fraction; > 0 draws the progress bar on the cover edge.
  final double progress;

  final bool showDuration;

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final borderRadius = BorderRadius.circular(24.sp);

    final List<DpadEffect> effects = [
      DpadScaleEffect(
        scale: 1.01,
        pressedScale: 0.97,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
      ),
      tvTheme.isLight
          ? DpadGlowEffect(color: tvTheme.focusColor, opacity: 1, spreadRadius: 2.sp, blurRadius: 0)
          : DpadGlowEffect(color: tvTheme.focusColor, opacity: 0.75, blurRadius: 18.sp, spreadRadius: 1.5.sp),
      DpadCustomEffect((ctx, state, _) {
        final isFocused = state.focused;
        final bgColor = isFocused ? tvTheme.focusedCardColor : tvTheme.cardColor;
        final titleColor = isFocused ? tvTheme.onFocusedCard : tvTheme.primaryTextColor;
        final subtitleColor = isFocused ? tvTheme.onFocusedCardSecondary : tvTheme.secondaryTextColor;
        final label = badge.isNotEmpty ? badge : archive.tname;

        return AnimatedContainer(
          duration: TvFocusStyle.focusDuration(isFocused),
          curve: TvFocusStyle.curve,
          decoration: BoxDecoration(
            color: bgColor,
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
                    if (label.isNotEmpty)
                      Positioned(
                        left: 12.sp,
                        top: 12.sp,
                        child: TvButton(excludeFocus: true, title: label, size: TvButtonSize.mini),
                      ),
                    if (showDuration && archive.duration > 0)
                      Positioned(
                        right: 12.sp,
                        bottom: 12.sp,
                        child: TvButton(
                          excludeFocus: true,
                          title: formatDuration(archive.duration),
                          size: TvButtonSize.mini,
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
              Padding(
                padding: EdgeInsets.only(left: 10.sp, top: 12.sp, right: 14.sp, bottom: 8.sp),
                child: Row(
                  children: [
                    TvCommonAvatar(avatarUrl: archive.upFace, fallbackName: archive.upName),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TvMarqueeText(
                            text: archive.title,
                            isFocused: isFocused,
                            style: AppTextStyles.t16W700.copyWith(color: titleColor),
                          ),
                          SizedBox(height: 2.sp),
                          Text(
                            archive.upName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t14W500.copyWith(color: subtitleColor),
                          ),
                        ],
                      ),
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
