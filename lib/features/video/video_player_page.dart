import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:media_core/media_core.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/features/music/music_player_controller.dart';
import 'package:pure_live/features/music/widgets/music_video_card.dart';
import 'package:pure_live/platforms/bilibili_music/bilibili_music_api.dart';
import 'package:pure_live/platforms/bilibili_music/bilibili_music_models.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// The video-mode player, modelled on newBV's layer scheme:
///
/// - the picture is always on; controls start visible with the focus on play;
/// - OK toggles the controls, left/right seek ±10s with newBV's acceleration
///   (consecutive presses within 200ms grow the step by 5s, up to 60s);
/// - Up opens the part list, Down closes it;
/// - Back peels one layer: quality menu → part list → controls → exit page.
///
/// Playback lives in the shared VOD controller, so leaving the page does not
/// stop it — and opening a live room pauses it, same as music.
class VideoPlayerPage extends ConsumerStatefulWidget {
  const VideoPlayerPage({super.key});

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  final FocusNode _rootNode = FocusNode();
  final FocusNode _playNode = FocusNode();
  bool _controlsVisible = true;
  bool _partsOpen = false;
  bool _qualityOpen = false;
  bool _danmakuOn = true;

  /// newBV's seek acceleration: repeated presses inside the window grow the
  /// step, so a long skip needs no dozen presses.
  DateTime _lastSeekAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _seekStep = 10;

  int _seekDelta(int direction) {
    final now = DateTime.now();
    _seekStep = now.difference(_lastSeekAt) < const Duration(milliseconds: 200)
        ? (_seekStep + 5).clamp(10, 60)
        : 10;
    _lastSeekAt = now;
    return direction * _seekStep;
  }

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((Object _) {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _playNode.requestFocus();
    });
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((Object _) {});
    _rootNode.dispose();
    _playNode.dispose();
    super.dispose();
  }

  void _showControls() {
    setState(() => _controlsVisible = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controlsVisible) _playNode.requestFocus();
    });
  }

  void _hideControls() {
    setState(() => _controlsVisible = false);
    _rootNode.requestFocus();
  }

  KeyEventResult _onRootKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;

    final controller = ref.read(musicPlayerControllerProvider.notifier);

    // Media keys work in every layer, like newBV's remote handling.
    if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause ||
        event.logicalKey == LogicalKeyboardKey.mediaPlay ||
        event.logicalKey == LogicalKeyboardKey.mediaPause) {
      controller.togglePlayPause();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.mediaTrackNext) {
      controller.next();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.mediaTrackPrevious) {
      controller.previous();
      return KeyEventResult.handled;
    }

    // Back peels one layer: quality menu, then parts, then the controls, then
    // the page pops. (Popping never stops the video — the shared controller
    // keeps playing.)
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.browserBack) {
      if (_qualityOpen) {
        setState(() => _qualityOpen = false);
        return KeyEventResult.handled;
      }
      if (_partsOpen) {
        _closeParts();
        return KeyEventResult.handled;
      }
      if (_controlsVisible) {
        _hideControls();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (_qualityOpen) return KeyEventResult.ignored;
    if (_partsOpen) return KeyEventResult.ignored;

    if (_controlsVisible) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        setState(() => _partsOpen = true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Controls hidden: the root owns the keyboard.
    if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
      _showControls();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      controller.seekBy(-_seekDelta(-1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      controller.seekBy(_seekDelta(1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _showControls();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _closeParts() {
    setState(() => _partsOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controlsVisible) _playNode.requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final track = state.current;

    return PopScope(
      canPop: !_qualityOpen && !_partsOpen && !_controlsVisible,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_qualityOpen) {
          setState(() => _qualityOpen = false);
        } else if (_partsOpen) {
          _closeParts();
        } else if (_controlsVisible) {
          _hideControls();
        }
      },
      child: TvScaffold(
        openingFocus: _rootNode,
        child: ColoredBox(
          color: Colors.black,
          child: DpadRegion(
            memoryKey: 'video_player',
            child: Focus(
              focusNode: _rootNode,
              onKeyEvent: _onRootKey,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // ------------------------------------------------ the picture
                  if (controller.handle != null)
                    MediaPlayerView(handle: controller.handle!, fit: BoxFit.contain)
                  else
                    _IdleSurface(track: track, resolving: state.resolving),

                  // ---------------------------------------------------- danmaku
                  if (_danmakuOn && controller.handle != null && track != null && track.part.cid > 0)
                    _DanmakuOverlay(handle: controller.handle!, cid: track.part.cid),

                  // ------------------------------------------------- top info bar
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    top: _controlsVisible ? 24.sp : -120.sp,
                    left: 48.sp,
                    right: 48.sp,
                    child: IgnorePointer(
                      ignoring: !_controlsVisible,
                      child: Row(
                        children: [
                          Icon(Icons.movie_outlined, size: 28.sp, color: tvTheme.focusColor),
                          SizedBox(width: 10.sp),
                          Expanded(
                            child: Text(
                              track?.title ?? i18n('video_player_title'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.t22W700.copyWith(color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 12.sp),
                          if (track != null && track.archive.parts.length > 1)
                            Text(
                              'P${track.part.page}/${track.archive.parts.length}',
                              style: AppTextStyles.t18W500.copyWith(color: Colors.white70),
                            ),
                          SizedBox(width: 12.sp),
                          if (BilibiliMusicApi.qualityLabel(state.quality).isNotEmpty)
                            Text(
                              BilibiliMusicApi.qualityLabel(state.quality),
                              style: AppTextStyles.t18W500.copyWith(color: Colors.white70),
                            ),
                          SizedBox(width: 12.sp),
                          if (track != null)
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 220.sp),
                              child: Text(
                                track.archive.upName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.t18W500.copyWith(color: Colors.white70),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // --------------------------------------------- bottom control bar
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    bottom: _controlsVisible ? 32.sp : -160.sp,
                    left: 48.sp,
                    right: 48.sp,
                    child: IgnorePointer(
                      ignoring: !_controlsVisible || _partsOpen || _qualityOpen,
                      child: ExcludeFocus(
                        excluding: !_controlsVisible || _partsOpen || _qualityOpen,
                        child: _ControlBar(
                          playNode: _playNode,
                          onOpenParts: () => setState(() => _partsOpen = true),
                          onOpenQuality: () => setState(() => _qualityOpen = true),
                          danmakuOn: _danmakuOn,
                          onToggleDanmaku: () => setState(() => _danmakuOn = !_danmakuOn),
                        ),
                      ),
                    ),
                  ),

                  // -------------------------------------------------- parts panel
                  if (_partsOpen)
                    Positioned(
                      top: 100.sp,
                      bottom: 100.sp,
                      right: 48.sp,
                      width: 520.sp,
                      child: _PartListPanel(onClose: _closeParts),
                    ),

                  // ------------------------------------------------- quality menu
                  if (_qualityOpen)
                    Positioned(
                      top: 100.sp,
                      right: 48.sp,
                      width: 320.sp,
                      child: _QualityMenu(onClose: () => setState(() => _qualityOpen = false)),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark plate behind a stream that has not opened yet.
class _IdleSurface extends StatelessWidget {
  const _IdleSurface({required this.track, required this.resolving});

  final MusicTrack? track;
  final bool resolving;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final track = this.track;
    return Stack(
      fit: StackFit.expand,
      children: [
        if (track != null && track.archive.cover.isNotEmpty)
          CachedNetworkImage(
            imageUrl: track.archive.cover,
            fit: BoxFit.cover,
            memCacheWidth: 1280,
            errorWidget: (_, _, _) => const SizedBox.shrink(),
          ),
        Container(color: Colors.black.withValues(alpha: track != null ? 0.72 : 1)),
        Center(
          child: resolving
              ? SizedBox(
                  width: 64.sp,
                  height: 64.sp,
                  child: CircularProgressIndicator(strokeWidth: 4.sp, color: tvTheme.focusColor),
                )
              : (track == null
                    ? Icon(Icons.movie_outlined, size: 96.sp, color: Colors.white24)
                    : const SizedBox.shrink()),
        ),
      ],
    );
  }
}

/// Bottom controls: progress row plus the transport row. The whole bar is
/// driven by the playback stream so the glyphs never go stale.
class _ControlBar extends ConsumerWidget {
  const _ControlBar({
    required this.playNode,
    required this.onOpenParts,
    required this.onOpenQuality,
    required this.danmakuOn,
    required this.onToggleDanmaku,
  });

  final FocusNode playNode;
  final VoidCallback onOpenParts;
  final VoidCallback onOpenQuality;
  final bool danmakuOn;
  final VoidCallback onToggleDanmaku;

  static String _timeLabel(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final state = ref.watch(musicPlayerControllerProvider);
    final tvTheme = context.tvTheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 18.sp),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(24.sp),
        border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.35)),
      ),
      child: StreamBuilder<PlaybackState>(
        stream: controller.playbackStream,
        builder: (context, snapshot) {
          final playback = snapshot.data;
          final position = playback?.position ?? Duration.zero;
          final duration = playback?.duration ?? Duration.zero;
          final isPlaying = playback?.isPlaying ?? (controller.handle?.isPlaying ?? false);
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 120.sp),
                    child: Text(_timeLabel(position), style: AppTextStyles.t18W500.copyWith(color: Colors.white70)),
                  ),
                  SizedBox(width: 16.sp),
                  Expanded(child: _ProgressBar(position: position, duration: duration)),
                  SizedBox(width: 16.sp),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 120.sp),
                    child: Text(_timeLabel(duration), style: AppTextStyles.t18W500.copyWith(color: Colors.white70)),
                  ),
                ],
              ),
              SizedBox(height: 16.sp),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TvIconButton(
                    icon: const Icon(Icons.skip_previous_rounded),
                    label: i18n('music_prev'),
                    size: TvIconButtonSize.large,
                    isSecondary: true,
                    onTap: () => controller.previous(),
                  ),
                  SizedBox(width: 20.sp),
                  TvIconButton(
                    icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    label: i18n('music_play'),
                    size: TvIconButtonSize.large,
                    focusNode: playNode,
                    onTap: () => controller.togglePlayPause(),
                  ),
                  SizedBox(width: 20.sp),
                  TvIconButton(
                    icon: const Icon(Icons.skip_next_rounded),
                    label: i18n('music_next'),
                    size: TvIconButtonSize.large,
                    isSecondary: true,
                    onTap: () => controller.next(),
                  ),
                  SizedBox(width: 40.sp),
                  TvButton(
                    title: '${state.speed}x',
                    icon: Icon(Icons.speed_rounded, size: 22.sp),
                    size: TvButtonSize.mini,
                    isSecondary: true,
                    onTap: () => controller.cycleSpeed(),
                  ),
                  SizedBox(width: 12.sp),
                  TvButton(
                    title: BilibiliMusicApi.qualityLabel(state.quality).isEmpty
                        ? i18n('video_quality')
                        : BilibiliMusicApi.qualityLabel(state.quality),
                    icon: Icon(Icons.high_quality_outlined, size: 22.sp),
                    size: TvButtonSize.mini,
                    isSecondary: true,
                    onTap: onOpenQuality,
                  ),
                  SizedBox(width: 12.sp),
                  TvButton(
                    title: i18n('music_tracks_title'),
                    icon: Icon(Icons.playlist_play_rounded, size: 22.sp),
                    size: TvButtonSize.mini,
                    isSecondary: true,
                    onTap: onOpenParts,
                  ),
                  SizedBox(width: 12.sp),
                  TvButton(
                    title: i18n(danmakuOn ? 'video_danmaku_on' : 'video_danmaku_off'),
                    icon: Icon(Icons.subtitles_outlined, size: 22.sp),
                    size: TvButtonSize.mini,
                    isSecondary: true,
                    onTap: onToggleDanmaku,
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The seek bar with newBV's acceleration on left/right while focused.
class _ProgressBar extends ConsumerStatefulWidget {
  const _ProgressBar({required this.position, required this.duration});

  final Duration position;
  final Duration duration;

  @override
  ConsumerState<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends ConsumerState<_ProgressBar> {
  final FocusNode _node = FocusNode();
  DateTime _lastSeekAt = DateTime.fromMillisecondsSinceEpoch(0);
  int _seekStep = 10;

  int _seekDelta(int direction) {
    final now = DateTime.now();
    _seekStep = now.difference(_lastSeekAt) < const Duration(milliseconds: 200) ? (_seekStep + 5).clamp(10, 60) : 10;
    _lastSeekAt = now;
    return direction * _seekStep;
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final double progress = widget.duration > Duration.zero
        ? (widget.position.inMilliseconds / widget.duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return Focus(
      focusNode: _node,
      onKeyEvent: (node, event) {
        if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
        final controller = ref.read(musicPlayerControllerProvider.notifier);
        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
          controller.seekBy(-_seekDelta(-1));
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          controller.seekBy(_seekDelta(1));
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: Builder(
        builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: focused ? 22.sp : 16.sp,
            margin: EdgeInsets.symmetric(vertical: focused ? 6.sp : 10.sp),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(11.sp),
              border: Border.all(color: focused ? accent : Colors.white24, width: focused ? 2.sp : 1.sp),
            ),
            child: Stack(
              children: [
                FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress,
                  child: Container(
                    margin: EdgeInsets.all(3.sp),
                    decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(8.sp)),
                  ),
                ),
                if (focused)
                  Align(
                    alignment: Alignment.lerp(Alignment.centerLeft, Alignment.centerRight, progress) ??
                        Alignment.centerLeft,
                    child: Container(width: 4.sp, color: Colors.white),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The part list over the player. OK jumps; Up closed it via the page root.
class _PartListPanel extends ConsumerWidget {
  const _PartListPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(24.sp),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.sp),
            child: Row(
              children: [
                Icon(Icons.playlist_play_rounded, size: 28.sp, color: accent),
                SizedBox(width: 10.sp),
                Expanded(
                  child: Text(
                    '${i18n('music_tracks_title')}（${state.queue.length}）',
                    style: AppTextStyles.t20W600.copyWith(color: Colors.white),
                  ),
                ),
                TvIconButton(
                  icon: const Icon(Icons.close_rounded),
                  size: TvIconButtonSize.small,
                  isSecondary: true,
                  onTap: onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.only(left: 16.sp, right: 16.sp, bottom: 16.sp),
              itemCount: state.queue.length,
              itemBuilder: (context, index) {
                final track = state.queue[index];
                final isCurrent = index == state.index;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.sp),
                  child: TvFocusable(
                    onTap: () => controller.jumpTo(index),
                    builder: (context, focused, child) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        height: 64.sp,
                        padding: EdgeInsets.symmetric(horizontal: 14.sp),
                        decoration: BoxDecoration(
                          color: isCurrent ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12.sp),
                          border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 32.sp,
                              child: isCurrent
                                  ? Icon(Icons.play_arrow_rounded, size: 26.sp, color: accent)
                                  : Text('${index + 1}', style: AppTextStyles.t16W500.copyWith(color: Colors.white54)),
                            ),
                            SizedBox(width: 10.sp),
                            Expanded(
                              child: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.t16W500.copyWith(color: isCurrent ? accent : Colors.white),
                              ),
                            ),
                            Text(
                              MusicVideoCard.formatDuration(
                                track.part.duration > 0 ? track.part.duration : track.archive.duration,
                              ),
                              style: AppTextStyles.t14W500.copyWith(color: Colors.white54),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// The quality menu, one entry per rendition the current stream answer ships.
class _QualityMenu extends ConsumerWidget {
  const _QualityMenu({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20.sp),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16.sp),
            child: Row(
              children: [
                Icon(Icons.high_quality_outlined, size: 26.sp, color: accent),
                SizedBox(width: 10.sp),
                Expanded(child: Text(i18n('video_quality'), style: AppTextStyles.t18W600.copyWith(color: Colors.white))),
                TvIconButton(
                  icon: const Icon(Icons.close_rounded),
                  size: TvIconButtonSize.small,
                  isSecondary: true,
                  onTap: onClose,
                ),
              ],
            ),
          ),
          for (final option in state.qualityOptions)
            Padding(
              padding: EdgeInsets.only(left: 12.sp, right: 12.sp, bottom: 8.sp),
              child: TvFocusable(
                onTap: () {
                  controller.switchQuality(option.quality);
                  onClose();
                },
                builder: (context, focused, child) {
                  final isCurrent = option.quality == state.quality;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 56.sp,
                    padding: EdgeInsets.symmetric(horizontal: 14.sp),
                    decoration: BoxDecoration(
                      color: isCurrent ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12.sp),
                      border: Border.all(color: focused ? accent : Colors.transparent, width: 2.sp),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            BilibiliMusicApi.qualityLabel(option.quality).isEmpty
                                ? '${option.quality}'
                                : BilibiliMusicApi.qualityLabel(option.quality),
                            style: AppTextStyles.t16W500.copyWith(color: isCurrent ? accent : Colors.white),
                          ),
                        ),
                        if (isCurrent) Icon(Icons.check_rounded, size: 22.sp, color: accent),
                      ],
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: 8.sp),
        ],
      ),
    );
  }
}

/// Minimal scroll danmaku for VOD, synced to the player position.
///
/// The full XML segment list (`/x/v1/dm/list.so`) is fetched once per part and
/// parsed with a line matcher; the overlay then walks the items against the
/// handle position on a timer and flies the active ones across lanes. Not
/// newBV's segmented protobuf engine — a TV-readable stand-in with the same
/// look, none of the memory footprint.
class _DanmakuOverlay extends ConsumerStatefulWidget {
  const _DanmakuOverlay({required this.handle, required this.cid});

  final PlayerHandle handle;
  final int cid;

  @override
  ConsumerState<_DanmakuOverlay> createState() => _DanmakuOverlayState();
}

class _DanmakuOverlayState extends ConsumerState<_DanmakuOverlay> {
  static const double _laneHeight = 34;
  static const double _travelSeconds = 9;

  List<({double time, String text, int lane})> _items = [];
  int _scanIndex = 0;
  final List<({String text, double startedAt, int lane})> _flying = [];
  Timer? _timer;

  static final RegExp _line = RegExp(r'<d p="([^"]+)"[^>]*>([^<]+)</d>');
  static const Map<String, String> _entities = {
    '&lt;': '<',
    '&gt;': '>',
    '&quot;': '"',
    '&#39;': "'",
    '&apos;': "'",
    '&amp;': '&',
  };

  String _unescape(String raw) {
    var text = raw;
    for (final entry in _entities.entries) {
      text = text.replaceAll(entry.key, entry.value);
    }
    return text;
  }

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(milliseconds: 120), (_) => _tick());
  }

  @override
  void didUpdateWidget(_DanmakuOverlay old) {
    super.didUpdateWidget(old);
    if (old.cid != widget.cid) _load();
  }

  Future<void> _load() async {
    _items = const [];
    _scanIndex = 0;
    _flying.clear();
    try {
      final xml = await HttpClient.instance.getText(
        'https://api.bilibili.com/x/v1/dm/list.so?oid=${widget.cid}',
        header: {'user-agent': 'Mozilla/5.0', 'referer': 'https://www.bilibili.com/'},
      );
      final parsed = <({double time, String text, int lane})>[];
      for (final match in _line.allMatches(xml)) {
        final fields = match.group(1)?.split(',') ?? const [];
        final time = double.tryParse(fields.elementAtOrNull(0) ?? '') ?? -1;
        final mode = int.tryParse(fields.elementAtOrNull(1) ?? '') ?? 1;
        if (time < 0 || mode > 3) continue;
        final text = _unescape(match.group(2) ?? '').trim();
        if (text.isEmpty) continue;
        parsed.add((time: time, text: text, lane: text.hashCode.abs() % 6));
      }
      parsed.sort((a, b) => a.time.compareTo(b.time));
      if (!mounted) return;
      setState(() => _items = parsed);
    } catch (_) {
      // No danmaku is a silent degradation — the video itself is the content.
    }
  }

  void _tick() {
    if (_items.isEmpty && _flying.isEmpty) return;
    final now = widget.handle.position.inMilliseconds / 1000.0;
    // Expired first: the build below only renders what is still on screen.
    _flying.removeWhere((item) => now - item.startedAt > _travelSeconds);
    // Advance the scan pointer past everything already off screen.
    while (_scanIndex < _items.length && _items[_scanIndex].time < now - _travelSeconds) {
      _scanIndex++;
    }
    // Launch everything that just came due.
    while (_scanIndex < _items.length && _items[_scanIndex].time <= now) {
      final item = _items[_scanIndex];
      // A seek backwards rewinds time; items due in the future stay pending.
      if (now - item.time < 0.5) {
        _flying.add((text: item.text, startedAt: item.time, lane: item.lane));
        if (_flying.length > 60) _flying.removeAt(0);
      }
      _scanIndex++;
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final now = widget.handle.position.inMilliseconds / 1000.0;
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          // The bullet starts one text-length off the right edge and exits
          // past the left edge, the classic scroll travel.
          const enter = 300.0;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              for (final item in _flying)
                if (now >= item.startedAt && now - item.startedAt <= _travelSeconds)
                  Positioned(
                    right: (now - item.startedAt) / _travelSeconds * (w + enter) - enter,
                    top: 16.sp + item.lane * _laneHeight.sp,
                    child: Text(
                      item.text,
                      style: AppTextStyles.t18W700.copyWith(
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black.withValues(alpha: 0.8), blurRadius: 3)],
                      ),
                    ),
                  ),
            ],
          );
        },
      ),
    );
  }
}
