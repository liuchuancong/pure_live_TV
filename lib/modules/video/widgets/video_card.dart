import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/utils/dpad_long_press_gate.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/modules/video/controllers/playback/video_progress_controller.dart';

/// The video-mode card, newBV's SmallVideoCard: a cover with the play/danmaku
/// counts and the duration on a bottom gradient, the title, and the UP ·
/// publish-time line under it. The watched-progress line rides the cover's
/// bottom edge. Long-press swaps the cover for the action row (稍后再看 /
/// UP 主页), closing when the card loses focus.
///
/// The focus language is TvRoomCard's: one AnimatedContainer surface
/// (focusedCardColor / cardColor, 24sp radius, 2sp accent edge), cover
/// flexing inside it, on-cover pills as TvButton mini, marquee title.
class VideoCard extends ConsumerStatefulWidget {
  const VideoCard({
    super.key,
    required this.archive,
    required this.onTap,
    this.badge = '',
  });

  final MusicArchive archive;
  final VoidCallback onTap;

  /// An override label (ranking position, region name); empty falls back to
  /// the archive's region name.
  final String badge;

  @override
  ConsumerState<VideoCard> createState() => _VideoCardState();
}

class _VideoCardState extends ConsumerState<VideoCard> {
  /// TvRoomCard's long-press gate — see [DpadLongPressGate].
  final DpadLongPressGate _longPressGate = DpadLongPressGate();

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
      videoProgressControllerProvider.select(
        (s) => s.entries[archive.bvid]?.percent ?? 0.0,
      ),
    );

    final badge = widget.badge.isNotEmpty ? widget.badge : archive.tname;

    final borderRadius = BorderRadius.circular(24.sp);
    // The visuals fold into a DpadCustomEffect: DpadFocusable takes effects
    // or a builder, never both (the assertion that filled every grid cell
    // with the error view).
    final List<DpadEffect> effects = [
      DpadScaleEffect(
        scale: 1.01,
        pressedScale: 0.97,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOutCubic,
      ),
      // Light palette: the 18px glow is a grey smear on white; crisp ring.
      tvTheme.isLight
          ? DpadGlowEffect(
              color: tvTheme.focusColor,
              opacity: 1,
              spreadRadius: 2.sp,
              blurRadius: 0,
            )
          : DpadGlowEffect(
              color: tvTheme.focusColor,
              opacity: 0.75,
              blurRadius: 18.sp,
              spreadRadius: 1.5.sp,
            ),
      DpadCustomEffect((context, state, _) {
        final isFocused = state.focused;
        // Losing focus closes the action overlay, like newBV's onFocusChanged.
        if (_actionsOpen && !isFocused) {
          scheduleMicrotask(() {
            if (mounted && _actionsOpen) setState(() => _actionsOpen = false);
          });
        }
        final bgColor = isFocused
            ? tvTheme.focusedCardColor
            : tvTheme.cardColor;
        final titleColor = isFocused
            ? tvTheme.onFocusedCard
            : tvTheme.primaryTextColor;
        final subtitleColor = isFocused
            ? tvTheme.onFocusedCardSecondary
            : tvTheme.secondaryTextColor;

        return AnimatedContainer(
          duration: TvFocusStyle.focusDuration(isFocused),
          curve: TvFocusStyle.curve,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: borderRadius,
            border: Border.all(
              color: isFocused ? tvTheme.focusColor : Colors.transparent,
              width: 2.sp,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // TvRoomCard's compact rule: text boxes follow the app font
              // setting, and so does the compact threshold — a cell drawn
              // larger is effectively narrower.
              final double textScale = TvTextScale.factorOf(context);
              final bool compact = constraints.maxWidth < 190.sp * textScale;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // The cover takes the height the info block leaves (the room
                  // card's rule: the artwork yields, the content does not).
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Container(
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24.sp),
                            color: tvTheme.cardColor,
                          ),
                          child: CachedNetworkImage(
                            imageUrl: archive.cover,
                            fit: BoxFit.cover,
                            memCacheWidth: 640,
                            placeholder: (context, url) => Container(
                              color: tvTheme.cardColor,
                              child: AppStatusView(
                                type: AppStatusType.loading,
                                title: "",
                                subtitle: "",
                                isMini: true,
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              color: tvTheme.cardColor,
                              child: AppStatusView(
                                type: AppStatusType.error,
                                title: "",
                                subtitle: "",
                                isMini: true,
                              ),
                            ),
                          ),
                        ),
                        // Bottom gradient, newBV's CardCover scrim.
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Container(
                            height: 64.sp,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withValues(alpha: 0.72),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // On-cover meta stays hand-drawn and compact: the room
                        // card's TvButton pills are sized for its cell, and at a
                        // 160px video cell they swallow the cover (and overflow).
                        Positioned(
                          left: 10.sp,
                          right: 10.sp,
                          bottom: 6.sp,
                          child: Row(
                            children: [
                              TvCoverChip(
                                icon: Icons.play_arrow_rounded,
                                label: _wan(archive.playCount),
                              ),
                              SizedBox(width: 6.sp),
                              TvCoverChip(
                                icon: Icons.comment_outlined,
                                label: _wan(archive.barrageCount),
                              ),
                              const Spacer(),
                              if (_durationLabel.isNotEmpty)
                                TvCoverChip(label: _durationLabel),
                            ],
                          ),
                        ),
                        // The region/rank chip anchors the top-left corner.
                        if (badge.isNotEmpty)
                          Positioned(
                            left: 10.sp,
                            top: 10.sp,
                            child: TvCoverChip(label: badge),
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
                                  ColoredBox(
                                    color: Colors.white.withValues(alpha: 0.25),
                                  ),
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
                                  icon: Icon(
                                    Icons.watch_later_outlined,
                                    size: 30.sp,
                                    color: Colors.white,
                                  ),
                                ),
                                IconButton(
                                  tooltip: i18n('video_action_up_page'),
                                  onPressed: archive.upMid > 0
                                      ? () => UgcUserSpaceRoute(
                                          archive.upMid,
                                          archive.upName,
                                        ).push(context)
                                      : null,
                                  icon: Icon(
                                    Icons.person_outline_rounded,
                                    size: 30.sp,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  // The info row, TvRoomCard's shape and sizes: the UP avatar
                  // leads (the footprint stays fixed either way, so titles stay
                  // aligned across a grid), the title marquee runs one step
                  // smaller when compact, and the UP · date line follows the same
                  // steps as the room card's nick line.
                  Padding(
                    padding: EdgeInsets.only(
                      left: 10.sp,
                      top: (compact ? 6.sp : 16.sp) * textScale,
                      right: compact ? 10.sp : 16.sp,
                      bottom: (compact ? 6.sp : 8.sp) * textScale,
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: compact ? 20.sp : 56.sp,
                          child: Center(
                            child: TvCommonAvatar(
                              avatarUrl: archive.upFace,
                              fallbackName: archive.upName,
                              radius: compact ? 10.sp : null,
                            ),
                          ),
                        ),
                        SizedBox(width: compact ? 8.sp : 16.sp),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TvMarqueeText(
                                text: archive.title,
                                isFocused: isFocused,
                                style:
                                    (compact
                                            ? AppTextStyles.t14.copyWith(
                                                fontWeight: FontWeight.w700,
                                              )
                                            : AppTextStyles.t22.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ))
                                        .copyWith(color: titleColor),
                              ),
                              SizedBox(
                                height: (compact ? 2.sp : 4.sp) * textScale,
                              ),
                              Text(
                                archive.upName +
                                    (_pubLabel.isEmpty ? '' : ' · $_pubLabel'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    (compact
                                            ? AppTextStyles.t14.copyWith(
                                                fontWeight: FontWeight.w500,
                                              )
                                            : AppTextStyles.t18.copyWith(
                                                fontWeight: FontWeight.w500,
                                              ))
                                        .copyWith(color: subtitleColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      }),
    ];

    return DpadFocusable(
      effects: effects,
      // TvRoomCard's long-press gate: opening the actions row on a hold must
      // not also fire the hold's release as a tap.
      onSelect: () {
        if (_longPressGate.swallowSelect()) return;
        widget.onTap.call();
      },
      onLongSelect: archive.aid > 0
          ? () {
              _longPressGate.markLongPress();
              setState(() => _actionsOpen = true);
            }
          : null,
      child: const SizedBox.shrink(),
    );
  }
}
