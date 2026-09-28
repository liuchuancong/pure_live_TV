import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:media_core/media_core.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/music/services/music_lyric_service.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// The full-screen music player.
///
/// Remote model (kept deliberately boring so the d-pad never surprises):
/// - controls start visible, focus on play/pause;
/// - Back walks one layer out at a time: queue panel → controls → exit page;
/// - with the controls hidden, OK brings them back and left/right seek ±10s;
/// - up opens the queue panel, down closes it.
///
/// Leaving the page does not stop the music — the queue keeps playing while
/// the viewer browses, which is the whole point of a music mode on a TV.
class MusicPlayerPage extends ConsumerStatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  ConsumerState<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends ConsumerState<MusicPlayerPage> {
  final FocusNode _rootNode = FocusNode();
  final FocusNode _playNode = FocusNode();
  bool _controlsVisible = true;
  bool _queueOpen = false;

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

    // Back always peels one layer: queue panel first, then the controls, then
    // the page itself.
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.browserBack) {      if (_queueOpen) {
        setState(() => _queueOpen = false);
        return KeyEventResult.handled;
      }
      if (_controlsVisible) {
        _hideControls();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (_queueOpen) return KeyEventResult.ignored;

    if (_controlsVisible) {
      // Up from the control bar offers the queue, the layer above it.
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _openQueue();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Controls hidden: the root node owns the keyboard.
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
      _showControls();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      controller.seekBy(-10);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      controller.seekBy(10);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _showControls();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _openQueue() {
    setState(() => _queueOpen = true);
  }

  void _closeQueue() {
    setState(() => _queueOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controlsVisible) _playNode.requestFocus();
    });
  }

  // --------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final track = state.current;

    // The remote's Back walks the system pop channel, not the key-event one:
    // PopScope is what peels the layers (queue panel → controls) before the
    // page itself pops. Popping the page never stops the music — the queue
    // keeps playing while the viewer browses.
    return PopScope(
      canPop: !_queueOpen && !_controlsVisible,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_queueOpen) {
          _closeQueue();
        } else if (_controlsVisible) {
          _hideControls();
        }
      },
      child: TvScaffold(
      openingFocus: _rootNode,
      child: ColoredBox(
        color: Colors.black,
        child: DpadRegion(
        memoryKey: 'music_player',
        child: Focus(
          focusNode: _rootNode,
          onKeyEvent: _onRootKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ---------------------------------------------------- the picture
              // Video keeps the picture; audio-only becomes the QQ music
              // now-playing view: cover on the left, synced lyrics on the right.
              if (controller.handle != null && !state.audioOnly)
                MediaPlayerView(handle: controller.handle!, fit: BoxFit.contain)
              else if (track != null)
                _NowPlayingBody(track: track, resolving: state.resolving)
              else
                _IdleSurface(track: track, resolving: state.resolving),

              // --------------------------------------------------- top info bar
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
                      Icon(Icons.music_note_rounded, size: 28.sp, color: tvTheme.focusColor),
                      SizedBox(width: 10.sp),
                      Expanded(
                        child: Text(
                          track?.title ?? i18n('music_player_title'),
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

              // ------------------------------------------------ bottom control bar
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                bottom: _controlsVisible ? 32.sp : -160.sp,
                left: 48.sp,
                right: 48.sp,
                child: IgnorePointer(
                  ignoring: !_controlsVisible || _queueOpen,
                  // Hidden must also mean unfocusable: a parked-offscreen bar
                  // that keeps its buttons focusable lets the d-pad land on
                  // controls the viewer cannot see.
                  child: ExcludeFocus(
                    excluding: !_controlsVisible || _queueOpen,
                    child: _ControlBar(
                      playNode: _playNode,
                      onOpenQueue: _openQueue,
                    ),
                  ),
                ),
              ),

              // ------------------------------------------------------ queue panel
              if (_queueOpen)
                Positioned(
                  top: 100.sp,
                  bottom: 100.sp,
                  right: 48.sp,
                  width: 520.sp,
                  child: _QueuePanel(
                    onClose: _closeQueue,
                  ),
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

/// What fills the screen while no stream is open: cover art dimmed behind a
/// spinner (resolving) or the plain dark plate.
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
                    ? Icon(Icons.library_music_rounded, size: 96.sp, color: Colors.white24)
                    : const SizedBox.shrink()),
        ),
      ],
    );
  }
}

/// The audio-only now-playing view, QQ music desktop's shape: the cover with
/// title and maker on the left, the synced lyric panel on the right.
class _NowPlayingBody extends StatelessWidget {
  const _NowPlayingBody({required this.track, required this.resolving});

  final MusicTrack track;
  final bool resolving;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 64.sp, vertical: 96.sp),
      child: Row(
        children: [
          Expanded(
            flex: 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28.sp),
                      child: CachedNetworkImage(
                        imageUrl: track.archive.cover,
                        width: 380.sp,
                        height: 380.sp,
                        fit: BoxFit.cover,
                        memCacheWidth: 720,
                        errorWidget: (_, _, _) => Container(
                          width: 380.sp,
                          height: 380.sp,
                          color: tvTheme.focusColor.withValues(alpha: 0.2),
                          child: Icon(Icons.music_note_rounded, size: 120.sp, color: tvTheme.focusColor),
                        ),
                      ),
                    ),
                    if (resolving)
                      SizedBox(
                        width: 72.sp,
                        height: 72.sp,
                        child: CircularProgressIndicator(strokeWidth: 5.sp, color: tvTheme.focusColor),
                      ),
                  ],
                ),
                SizedBox(height: 32.sp),
                Text(
                  track.title,
                  style: AppTextStyles.t30W700.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 10.sp),
                Text(track.archive.upName, style: AppTextStyles.t18W500.copyWith(color: Colors.white70)),
              ],
            ),
          ),
          SizedBox(width: 48.sp),
          Expanded(flex: 6, child: _LyricsPanel(track: track)),
        ],
      ),
    );
  }
}

/// The synced lyric panel: fetches the LRC for the current track, feeds the
/// player position into [LyricController], and seeks on a tapped line.
class _LyricsPanel extends ConsumerStatefulWidget {
  const _LyricsPanel({required this.track});

  final MusicTrack track;

  @override
  ConsumerState<_LyricsPanel> createState() => _LyricsPanelState();
}

class _LyricsPanelState extends ConsumerState<_LyricsPanel> {
  LyricController? _lyric;
  Timer? _syncTimer;
  bool _loading = true;
  bool _empty = false;
  String _loadedKey = '';

  /// One style for every panel instance: bigger than the package default so it
  /// reads at TV distance.
  static final LyricStyle _style = LyricStyles.default1.copyWith(
    textStyle: AppTextStyles.t20W500.copyWith(color: Colors.white60, height: 1.6),
    activeStyle: AppTextStyles.t26W700.copyWith(color: Colors.white, height: 1.6),
    translationStyle: AppTextStyles.t16W500.copyWith(color: Colors.white38),
    lineGap: 18,
  );

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(_LyricsPanel old) {
    super.didUpdateWidget(old);
    if (old.track.id != widget.track.id) _setup();
  }

  void _setup() {
    final key = widget.track.id;
    _loadedKey = key;
    _syncTimer?.cancel();
    _lyric?.dispose();
    final controller = LyricController();
    _lyric = controller;
    controller.setOnTapLineCallback((position) {
      ref.read(musicPlayerControllerProvider.notifier).seekTo(position);
    });
    _loading = true;
    _empty = false;

    // Position sync by polling: the handle appears some time after the page
    // (the track resolves first), so a one-shot stream subscription would miss
    // it; the poll re-reads whatever handle is live.
    _syncTimer = Timer.periodic(const Duration(milliseconds: 250), (_) {
      final handle = ref.read(musicPlayerControllerProvider.notifier).handle;
      if (!mounted || handle == null || _lyric == null) return;
      _lyric!.setProgress(handle.position);
    });

    MusicLyricService.instance
        .fetchLyric(
          widget.track.title,
          hint: widget.track.archive.title,
          aid: widget.track.archive.aid,
          bvid: widget.track.archive.bvid,
          cid: widget.track.part.cid,
        )
        .then((lrc) {
      if (!mounted || _loadedKey != key) return;
      setState(() {
        _loading = false;
        _empty = lrc == null;
      });
      if (lrc != null) controller.loadLyric(lrc);
    });
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _lyric?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Center(
        child: SizedBox(
          width: 48.sp,
          height: 48.sp,
          child: CircularProgressIndicator(strokeWidth: 4.sp, color: context.tvTheme.focusColor),
        ),
      );
    }
    if (_empty || _lyric == null) {
      return Center(
        child: Text(i18n('music_no_lyric'), style: AppTextStyles.t20W500.copyWith(color: Colors.white38)),
      );
    }
    return LyricView(controller: _lyric!, style: _style);
  }
}

/// Transport row + progress bar. Everything is a plain focusable control, so
/// d-pad left/right walks them and the bar's own node maps left/right to seek.
class _ControlBar extends ConsumerWidget {
  const _ControlBar({required this.playNode, required this.onOpenQueue});

  final FocusNode playNode;
  final VoidCallback onOpenQueue;

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
        // One stream drives the whole bar: the progress row and the play/pause
        // glyph, which otherwise went stale until the next controller state
        // change.
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
                    child: Text(
                      _timeLabel(position),
                      style: AppTextStyles.t18W500.copyWith(color: Colors.white70),
                    ),
                  ),
                  SizedBox(width: 16.sp),
                  Expanded(child: _ProgressBar(position: position, duration: duration)),
                  SizedBox(width: 16.sp),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: 120.sp),
                    child: Text(
                      _timeLabel(duration),
                      style: AppTextStyles.t18W500.copyWith(color: Colors.white70),
                    ),
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
                    title: i18n(state.mode.i18nKey),
                    icon: Icon(Icons.repeat_rounded, size: 22.sp),
                    size: TvButtonSize.mini,
                    isSecondary: true,
                    onTap: () => controller.cycleMode(),
                  ),
                  SizedBox(width: 12.sp),
                  TvButton(
                    title: i18n(state.audioOnly ? 'music_video_on' : 'music_audio_only'),
                    icon: Icon(state.audioOnly ? Icons.videocam_outlined : Icons.headphones_rounded, size: 22.sp),
                    size: TvButtonSize.mini,
                    isSecondary: true,
                    onTap: () => controller.toggleAudioOnly(),
                  ),
                  SizedBox(width: 12.sp),
                  TvButton(
                    title: i18n('music_tracks_title'),
                    icon: Icon(Icons.queue_music_rounded, size: 22.sp),
                    size: TvButtonSize.mini,
                    isSecondary: true,
                    onTap: onOpenQueue,
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

/// The seek bar. Focus lands on it from the row above; left/right step ±10s
/// (the same step the hidden-state arrows use).
class _ProgressBar extends ConsumerStatefulWidget {
  const _ProgressBar({required this.position, required this.duration});

  final Duration position;
  final Duration duration;

  @override
  ConsumerState<_ProgressBar> createState() => _ProgressBarState();
}

class _ProgressBarState extends ConsumerState<_ProgressBar> {
  final FocusNode _node = FocusNode();

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
          controller.seekBy(-10);
          return KeyEventResult.handled;
        }
        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
          controller.seekBy(10);
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
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                  ),
                ),
                if (focused)
                  Align(
                    alignment: Alignment.lerp(Alignment.centerLeft, Alignment.centerRight, progress) ??
                        Alignment.centerLeft,
                    child: Container(
                      width: 4.sp,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// The track list over the player. OK jumps; Back closes (handled by the page
/// root, which sees the event bubble up).
class _QueuePanel extends ConsumerWidget {
  const _QueuePanel({required this.onClose});

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
                Icon(Icons.queue_music_rounded, size: 28.sp, color: accent),
                SizedBox(width: 10.sp),
                Expanded(
                  child: Text(
                    '${i18n('music_tab_queue')}（${state.queue.length}）',
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
                                  ? Icon(Icons.graphic_eq_rounded, size: 24.sp, color: accent)
                                  : Text(
                                      '${index + 1}',
                                      style: AppTextStyles.t16W500.copyWith(color: Colors.white54),
                                    ),
                            ),
                            SizedBox(width: 10.sp),
                            Expanded(
                              child: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.t16W500.copyWith(
                                  color: isCurrent ? accent : Colors.white,
                                ),
                              ),
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
