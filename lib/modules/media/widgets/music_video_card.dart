import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/utils/dpad_long_press_gate.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/media/models/models.dart';

/// A bilibili archive card in the newBV visual: the cover carries a bottom
/// scrim with the play / danmaku counts and the duration, the title sits below
/// (two lines), then the UP row — the UP chip, the name and the publish date.
/// The live card speaks LiveRoom; this one speaks [MusicArchive].
///
/// Optional [badge] (region / rank label), [progress] (watched fraction, drawn
/// as the cover's bottom bar), [pubTime] (overrides the archive's own publish
/// date in the caption) and [onLongPress] let the video module's grids reuse
/// the same shell.
class MusicVideoCard extends StatefulWidget {
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

  @override
  State<MusicVideoCard> createState() => _MusicVideoCardState();

  static String formatDuration(int seconds) {
    if (seconds <= 0) return '';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }
}

class _MusicVideoCardState extends State<MusicVideoCard> {
  /// TvRoomCard's long-press gate: a hold opens this card's long-press action,
  /// and the hold's release must never also fire the tap on its way out.
  final DpadLongPressGate _longPressGate = DpadLongPressGate();

  @override
  Widget build(BuildContext context) {
    final MusicArchive archive = widget.archive;
    final String badge = widget.badge;
    final String? pubTime = widget.pubTime;
    final bool showDuration = widget.showDuration;
    final double progress = widget.progress;
    final tvTheme = context.tvTheme;
    final borderRadius = BorderRadius.circular(18.sp);

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
                    // The corner badges speak TvRoomCard's compact chip
                    // language: the type anchors the top-left, the counts sit
                    // bottom-left and the duration bottom-right. The chips are
                    // near-opaque, so no scrim under them — the old gradient
                    // just greyed the artwork. Fixed-size text like the room
                    // card's: cover meta is an overlay, exempt from the
                    // font-scale resolver.
                    if (label.isNotEmpty)
                      Positioned(
                        left: 12.sp,
                        top: 12.sp,
                        child: TvCoverChip(label: label),
                      ),
                    Positioned(
                      left: 12.sp,
                      bottom: 12.sp,
                      child: Wrap(
                        spacing: 8.sp,
                        runSpacing: 6.sp,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          TvCoverChip(
                            icon: Icons.play_circle_outline_rounded,
                            label: readableCount(archive.playCount.toString()),
                          ),
                          TvCoverChip(
                            icon: Icons.speaker_notes_outlined,
                            label: readableCount(archive.barrageCount.toString()),
                          ),
                        ],
                      ),
                    ),
                    if (showDuration && archive.duration > 0)
                      Positioned(
                        right: 12.sp,
                        bottom: 12.sp,
                        child: TvCoverChip(label: MusicVideoCard.formatDuration(archive.duration)),
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
                      style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: titleColor, height: 1.3),
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
                            style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w700, color: secondaryColor, height: 1.1),
                          ),
                        ),
                        SizedBox(width: 6.sp),
                        Expanded(
                          child: Text(
                            archive.upName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: secondaryColor),
                          ),
                        ),
                        if (date.isNotEmpty) ...[
                          SizedBox(width: 8.sp),
                          Text(date, style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: secondaryColor)),
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
      onSelect: () {
        if (_longPressGate.swallowSelect()) return;
        widget.onTap?.call();
      },
      onLongSelect: widget.onLongPress == null
          ? null
          : () {
              _longPressGate.markLongPress();
              widget.onLongPress!.call();
            },
      child: const SizedBox(),
    );
  }
}

