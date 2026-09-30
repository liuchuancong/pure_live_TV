import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_core/media_core.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';

/// Bottom controls, live_play's index-driven model: the bar holds ONE focus
/// node and owns every key while visible — left/right walk the buttons (with
/// wrap), OK activates the highlighted one, down drops into the seek strip
/// where left/right seek and up returns. The buttons themselves never take
/// focus; they only draw the highlight, so nothing fights the bar.
enum VideoBarZone { bar, seek }

class VideoPlayerControlBar extends ConsumerStatefulWidget {
  const VideoPlayerControlBar({
    super.key,
    required this.playNode,
    required this.onInteraction,
    required this.onPrevPart,
    required this.onNextPart,
    required this.onOpenParts,
    required this.onOpenQuality,
    required this.onOpenDanmakuSettings,
    required this.commentsEnabled,
    required this.onOpenComments,
    required this.danmakuOn,
    required this.subtitleOn,
    required this.aspectFill,
    required this.onToggleDanmaku,
    required this.onToggleSubtitle,
    required this.onToggleAspect,
  });

  /// The bar's single key owner. The page requests it when the controls rise,
  /// so focus lands inside the bar instead of fighting it.
  final FocusNode playNode;

  /// Every handled key lands here: the page re-arms the 5s auto-hide clock —
  /// the live bar's `keepControlsAlive`.
  final VoidCallback onInteraction;

  /// Part stepping owned by the page: sequential with a toast at each end —
  /// these are video parts, not songs in a queue that wraps.
  final VoidCallback onPrevPart;
  final VoidCallback onNextPart;
  final VoidCallback onOpenParts;
  final VoidCallback onOpenQuality;
  final VoidCallback onOpenDanmakuSettings;
  final bool commentsEnabled;
  final VoidCallback onOpenComments;
  final bool danmakuOn;
  final bool subtitleOn;
  final bool aspectFill;
  final VoidCallback onToggleDanmaku;
  final VoidCallback? onToggleSubtitle;
  final VoidCallback onToggleAspect;

  @override
  ConsumerState<VideoPlayerControlBar> createState() => VideoPlayerControlBarState();
}

class VideoPlayerControlBarState extends ConsumerState<VideoPlayerControlBar> {
  VideoBarZone _zone = VideoBarZone.bar;
  int _index = 1; // the play button: the first thing a viewer reaches for.

  // The live bar's reveal: walking the index with the arrows must drag the
  // selected pill into view once the row overflows.
  final Map<int, GlobalKey> _barKeys = <int, GlobalKey>{};
  GlobalKey _barKey(int index) => _barKeys.putIfAbsent(index, () => GlobalKey());

  void _revealSelection() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final BuildContext? pill = _barKeys[_index]?.currentContext;
      if (pill != null) Scrollable.ensureVisible(pill, duration: Duration.zero);
    });
  }

  static const int _itemCount = 13;

  static String _timeLabel(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  bool _isConfirm(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (!mounted) return KeyEventResult.ignored;

    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final key = event.logicalKey;

    if (_isConfirm(key)) {
      widget.onInteraction();
      if (_zone == VideoBarZone.seek) {
        setState(() => _zone = VideoBarZone.bar);
        return KeyEventResult.handled;
      }
      _activateIndex(_index);
      return KeyEventResult.handled;
    }

    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
        widget.onInteraction();
        final int delta = key == LogicalKeyboardKey.arrowLeft ? -1 : 1;
        if (_zone == VideoBarZone.seek) {
          controller.seekAccelerated(delta);
        } else {
          setState(() => _index = (_index + delta + _itemCount) % _itemCount);
          if (_zone == VideoBarZone.bar) _revealSelection();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (_zone == VideoBarZone.bar) {
          widget.onInteraction();
          setState(() => _zone = VideoBarZone.seek);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowUp:
        if (_zone == VideoBarZone.seek) {
          widget.onInteraction();
          setState(() => _zone = VideoBarZone.bar);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      default:
        return KeyEventResult.ignored;
    }
  }

  /// Runs the action behind [index]. Taps report the button they hit, the
  /// remote reports the highlighted one, so both paths share one list.
  void _activateIndex(int index) {
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    switch (index) {
      case 0:
        widget.onPrevPart();
      case 1:
        unawaited(controller.togglePlayPause());
      case 2:
        widget.onNextPart();
      case 3:
        unawaited(controller.seekAccelerated(-1));
      case 4:
        unawaited(controller.seekAccelerated(1));
      case 5:
        unawaited(controller.cycleSpeed());
      case 6:
        widget.onOpenQuality();
      case 7:
        widget.onOpenParts();
      case 8:
        widget.onToggleDanmaku();
      case 9:
        if (widget.commentsEnabled) widget.onOpenComments();
      case 10:
        widget.onOpenDanmakuSettings();
      case 11:
        widget.onToggleSubtitle?.call();
      case 12:
        widget.onToggleAspect();
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final state = ref.watch(musicPlayerControllerProvider);
    final tvTheme = context.tvTheme;

    return Focus(
      focusNode: widget.playNode,
      onKeyEvent: _onKey,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 18.sp),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(24.sp),
          border: Border.all(
            color: tvTheme.focusColor.withValues(alpha: _zone == VideoBarZone.seek ? 0.9 : 0.35),
            width: _zone == VideoBarZone.seek ? 2.sp : 1.sp,
          ),
        ),
        child: StreamBuilder<PlaybackState>(
          // One stream drives the whole bar: the times, the seek strip and the
          // play/pause glyph never go stale.
          stream: controller.playbackStream,
          builder: (context, snapshot) {
            final playback = snapshot.data;
            final position = playback?.position ?? Duration.zero;
            final duration = playback?.duration ?? Duration.zero;
            final isPlaying = playback?.isPlaying ?? (controller.handle?.isPlaying ?? false);

            final buttons = <({String label, Widget icon, bool active, bool secondary, VoidCallback? onTap})>[
              (
                label: i18n('video_prev_part'),
                icon: const Icon(Icons.skip_previous_rounded),
                active: false,
                secondary: true,
                onTap: widget.onPrevPart,
              ),
              (
                label: i18n('music_play'),
                icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                active: true,
                secondary: false,
                onTap: () => controller.togglePlayPause(),
              ),
              (
                label: i18n('video_next_part'),
                icon: const Icon(Icons.skip_next_rounded),
                active: false,
                secondary: true,
                onTap: widget.onNextPart,
              ),
              (
                label: i18n('music_seek_back'),
                icon: const Icon(Icons.replay_10_rounded),
                active: false,
                secondary: true,
                onTap: () => controller.seekAccelerated(-1),
              ),
              (
                label: i18n('music_seek_forward'),
                icon: const Icon(Icons.forward_10_rounded),
                active: false,
                secondary: true,
                onTap: () => controller.seekAccelerated(1),
              ),
              (
                label: '${state.speed}x',
                icon: Icon(Icons.speed_rounded, size: 22.sp),
                active: false,
                secondary: true,
                onTap: () => controller.cycleSpeed(),
              ),
              (
                label: BilibiliMusicApi.qualityLabel(state.quality).isEmpty
                    ? i18n('video_quality')
                    : BilibiliMusicApi.qualityLabel(state.quality),
                icon: Icon(Icons.high_quality_outlined, size: 22.sp),
                active: false,
                secondary: true,
                onTap: widget.onOpenQuality,
              ),
              (
                label: i18n('video_parts_title'),
                icon: Icon(Icons.playlist_play_rounded, size: 22.sp),
                active: false,
                secondary: true,
                onTap: widget.onOpenParts,
              ),
              (
                label: i18n(widget.danmakuOn ? 'video_danmaku_on' : 'video_danmaku_off'),
                icon: Icon(Icons.subtitles_outlined, size: 22.sp),
                active: false,
                secondary: true,
                onTap: widget.onToggleDanmaku,
              ),
              (
                label: i18n('video_comments_title'),
                icon: Icon(Icons.comment_outlined, size: 22.sp),
                active: false,
                secondary: true,
                onTap: widget.commentsEnabled ? widget.onOpenComments : null,
              ),
              (
                label: i18n('video_danmaku_settings'),
                icon: Icon(Icons.tune_rounded, size: 22.sp),
                active: false,
                secondary: true,
                onTap: widget.onOpenDanmakuSettings,
              ),
              (
                label: i18n(widget.subtitleOn ? 'video_subtitle_on' : 'video_subtitle_off'),
                icon: Icon(Icons.closed_caption_outlined, size: 22.sp),
                active: widget.subtitleOn,
                secondary: !widget.subtitleOn,
                onTap: widget.onToggleSubtitle,
              ),
              (
                label: i18n(widget.aspectFill ? 'video_aspect_fill' : 'video_aspect_fit'),
                icon: Icon(Icons.aspect_ratio_rounded, size: 22.sp),
                active: false,
                secondary: true,
                onTap: widget.onToggleAspect,
              ),
            ];

            final double progress = duration > Duration.zero
                ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                : 0.0;
            final bool seekZone = _zone == VideoBarZone.seek;

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // The seek strip: times at the two ends, the strip between them
                // is the seek zone — down from the bar lands here, and it grows
                // its accent edge while active.
                Row(
                  children: [
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 120.sp),
                      child: Text(
                        _timeLabel(position),
                        style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white70),
                      ),
                    ),
                    SizedBox(width: 16.sp),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        height: seekZone ? 18.sp : 10.sp,
                        margin: EdgeInsets.symmetric(vertical: seekZone ? 4.sp : 8.sp),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9.sp),
                          border: Border.all(
                            color: seekZone ? tvTheme.focusColor : Colors.white24,
                            width: seekZone ? 2.sp : 1.sp,
                          ),
                        ),
                        child: Stack(
                          children: [
                            FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: progress,
                              child: Container(
                                margin: EdgeInsets.all(2.sp),
                                decoration: BoxDecoration(
                                  color: tvTheme.focusColor,
                                  borderRadius: BorderRadius.circular(7.sp),
                                ),
                              ),
                            ),
                            if (seekZone)
                              Align(
                                alignment:
                                    Alignment.lerp(Alignment.centerLeft, Alignment.centerRight, progress) ??
                                    Alignment.centerLeft,
                                child: Container(width: 4.sp, color: Colors.white),
                              ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(width: 16.sp),
                    ConstrainedBox(
                      constraints: BoxConstraints(maxWidth: 120.sp),
                      child: Text(
                        _timeLabel(duration),
                        style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16.sp),
                // One scrollable pill row, live_play's bar: a fixed row
                // overflowed (304px) and a Wrap spilled to a second line where
                // the index walked invisibly. The row follows the selection.
                SizedBox(
                  height: _BarPill.height(context),
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.zero,
                    itemCount: buttons.length,
                    separatorBuilder: (_, _) => SizedBox(width: 12.sp),
                    itemBuilder: (context, i) => KeyedSubtree(
                      key: _barKey(i),
                      child: _BarPill(
                        icon: buttons[i].icon,
                        label: buttons[i].label,
                        selected: _zone == VideoBarZone.bar && _index == i,
                        accent: tvTheme.focusColor,
                        active: buttons[i].active,
                        onTap: buttons[i].onTap,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// The live bar's pill: accent fill plus a scale lift is the whole selected
/// treatment (no ring — a border insets the fill and reads as a dark edge),
/// over a translucent base when idle. An active state tints its glyph.
class _BarPill extends StatefulWidget {
  const _BarPill({
    required this.icon,
    required this.label,
    required this.selected,
    required this.accent,
    required this.active,
    this.onTap,
  });

  // Pill geometry in one place, live_play's numbers.
  static const double _height = 52;
  static const double _hPadding = 18;
  static const double _gap = 8;

  static double height(BuildContext context) => _height.ts(context);

  final Widget icon;
  final String label;
  final bool selected;
  final bool active;
  final Color accent;
  final VoidCallback? onTap;

  @override
  State<_BarPill> createState() => _BarPillState();
}

class _BarPillState extends State<_BarPill> {
  @override
  Widget build(BuildContext context) {
    const Color foreground = Colors.white;
    final TextStyle textStyle =
        (widget.selected ? AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600) : AppTextStyles.t20).copyWith(
          color: foreground,
        );

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: widget.selected ? 1.05 : 1.0,
        duration: TvFocusStyle.focusDuration(widget.selected),
        curve: TvFocusStyle.curve,
        child: AnimatedContainer(
          duration: TvFocusStyle.focusDuration(widget.selected),
          curve: TvFocusStyle.curve,
          height: _BarPill._height.ts(context),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: _BarPill._hPadding.ts(context)),
          decoration: BoxDecoration(
            color: widget.selected ? widget.accent : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular((_BarPill._height / 3).ts(context)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme.merge(
                data: IconThemeData(
                  color: widget.selected ? foreground : (widget.active ? widget.accent : Colors.white70),
                ),
                child: widget.icon,
              ),
              SizedBox(width: _BarPill._gap.ts(context)),
              Text(widget.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}
