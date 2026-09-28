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
import 'package:pure_live/modules/media/widgets/handle_video_surface.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// The full-screen music player.
///
/// Remote model — one key handler owns the page and steers an index, the way the
/// live player does, so there is no per-button focus ring to hunt for:
/// - controls hidden: OK brings them back, left/right seek ±10s;
/// - bar up: left/right walk its buttons with wrap, OK activates the highlighted
///   one, down drops into the seek bar (left/right seek there), up opens the
///   queue, Back peels one layer out (queue → controls → page);
/// - video mode without a key press for five seconds slides the bar away — the
///   lyrics and poster views keep it, because nothing there is being watched.
///
/// Leaving the page does not stop the music — the queue keeps playing while the
/// viewer browses, which is the whole point of a music mode on a TV.
class MusicPlayerPage extends ConsumerStatefulWidget {
  const MusicPlayerPage({super.key});

  @override
  ConsumerState<MusicPlayerPage> createState() => _MusicPlayerPageState();
}

class _MusicPlayerPageState extends ConsumerState<MusicPlayerPage> {
  final FocusNode _rootNode = FocusNode(debugLabel: 'music/page');
  bool _controlsVisible = true;
  bool _queueOpen = false;

  /// The bar hides itself over the picture; every key the page or the bar
  /// handles re-arms this.
  Timer? _autoHideTimer;
  static const Duration _autoHideAfter = Duration(seconds: 5);

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((Object _) {});
    _armAutoHide();
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((Object _) {});
    _autoHideTimer?.cancel();
    _rootNode.dispose();
    super.dispose();
  }

  /// Only the video view auto-hides: over the poster or the lyrics there is
  /// nothing the bar could be covering up.
  void _armAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(_autoHideAfter, () {
      if (!mounted || !_controlsVisible) return;
      if (ref.read(musicPlayerControllerProvider).audioOnly) return;
      _hideControls();
    });
  }

  void _showControls() {
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _armAutoHide();
  }

  void _hideControls() {
    _autoHideTimer?.cancel();
    if (_controlsVisible) setState(() => _controlsVisible = false);
    _rootNode.requestFocus();
  }

  KeyEventResult _onRootKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;

    // Back always peels one layer: queue panel first, then the controls, then
    // the page itself.
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.browserBack) {
      if (_queueOpen) {
        _closeQueue();
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
      // The bar owns left/right/OK/down; up is the page's, and it opens the
      // queue — the layer above the bar, mirroring the live player.
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _openQueue();
        return KeyEventResult.handled;
      }
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _hideControls();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Controls hidden: this node owns the keyboard.
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _showControls();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      controller.seekAccelerated(-1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      controller.seekAccelerated(1);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _openQueue() {
    _autoHideTimer?.cancel();
    if (!_queueOpen) setState(() => _queueOpen = true);
  }

  void _closeQueue() {
    if (_queueOpen) setState(() => _queueOpen = false);
    _armAutoHide();
  }

  // --------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final track = state.current;

    // The picture and the lyrics views hide the bar on different clocks: going
    // to video mode starts the countdown, coming back to the lyrics cancels it.
    ref.listen(musicPlayerControllerProvider.select((s) => s.audioOnly), (_, _) => _armAutoHide());

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
              // Video keeps the picture; audio-only becomes the now-playing view:
              // the cover alone in the middle, and the synced lyrics beside it
              // once they arrive.
              if (controller.handle != null && !state.audioOnly)
                HandleVideoSurface(handle: controller.handle!, fit: BoxFit.contain)
              else if (track != null)
                _NowPlayingView(track: track, resolving: state.resolving)
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
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                bottom: _controlsVisible ? 32.sp : -180.sp,
                left: 48.sp,
                right: 48.sp,
                child: IgnorePointer(
                  ignoring: !_controlsVisible || _queueOpen,
                  // Hidden must also mean unfocusable: a parked-offscreen bar
                  // that keeps its buttons focusable lets the remote land on
                  // controls the viewer cannot see.
                  child: ExcludeFocus(
                    excluding: !_controlsVisible || _queueOpen,
                    child: _ControlBar(
                      active: _controlsVisible && !_queueOpen,
                      onQueue: _openQueue,
                      onInteraction: _armAutoHide,
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

/// The audio-only view: the cover in the middle to begin with, then — once the
/// track has timed lyrics — the same cover on the left with the lines beside it.
///
/// The switch is the "lyrics arrived" animation: a fade with a slight slide, so
/// the cover travels out of the centre instead of the page jumping between two
/// unrelated layouts.
class _NowPlayingView extends ConsumerStatefulWidget {
  const _NowPlayingView({required this.track, required this.resolving});

  final MusicTrack track;
  final bool resolving;

  @override
  ConsumerState<_NowPlayingView> createState() => _NowPlayingViewState();
}

class _NowPlayingViewState extends ConsumerState<_NowPlayingView> {
  LyricController? _lyric;
  Timer? _syncTimer;
  bool _loading = true;
  bool _empty = false;
  String _loadedKey = '';

  @override
  void initState() {
    super.initState();
    _setup();
  }

  @override
  void didUpdateWidget(_NowPlayingView old) {
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
    final bool withLyrics = !_loading && !_empty && _lyric != null;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 420),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero).animate(animation),
          child: child,
        ),
      ),
      child: withLyrics
          ? _LyricsLayout(key: const ValueKey('lyrics'), track: widget.track, lyric: _lyric!)
          : _PosterLayout(
              key: const ValueKey('poster'),
              track: widget.track,
              resolving: widget.resolving,
              // Only once the lookup has actually answered: a spinner over the
              // cover for a lyric request nobody asked for reads as the track
              // being stuck.
              status: _loading ? '' : (_empty ? i18n('music_no_lyric') : ''),
            ),
    );
  }
}

/// The cover in the middle of the screen with the name under it.
class _PosterLayout extends StatelessWidget {
  const _PosterLayout({super.key, required this.track, required this.resolving, required this.status});

  final MusicTrack track;
  final bool resolving;
  final String status;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28.sp),
                child: CachedNetworkImage(
                  imageUrl: track.archive.cover,
                  width: 420.sp,
                  height: 420.sp,
                  fit: BoxFit.cover,
                  memCacheWidth: 840,
                  errorWidget: (_, _, _) => Container(
                    width: 420.sp,
                    height: 420.sp,
                    color: tvTheme.focusColor.withValues(alpha: 0.2),
                    child: Icon(Icons.music_note_rounded, size: 140.sp, color: tvTheme.focusColor),
                  ),
                ),
              ),
              if (resolving)
                SizedBox(
                  width: 76.sp,
                  height: 76.sp,
                  child: CircularProgressIndicator(strokeWidth: 5.sp, color: tvTheme.focusColor),
                ),
            ],
          ),
          SizedBox(height: 36.sp),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 120.sp),
            child: Text(
              track.title,
              style: AppTextStyles.t34W700.copyWith(color: Colors.white),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(height: 12.sp),
          Text(track.archive.upName, style: AppTextStyles.t20W500.copyWith(color: Colors.white70)),
          if (status.isNotEmpty) ...[
            SizedBox(height: 14.sp),
            Text(status, style: AppTextStyles.t18W500.copyWith(color: Colors.white38)),
          ],
        ],
      ),
    );
  }
}

/// The synced lyric view: the cover and the track on the left, the lines beside
/// them. Tapping a line seeks to it.
class _LyricsLayout extends StatelessWidget {
  const _LyricsLayout({super.key, required this.track, required this.lyric});

  final MusicTrack track;
  final LyricController lyric;

  /// One style for every panel instance: bigger than the package default so it
  /// reads at TV distance.
  static final LyricStyle style = LyricStyles.default1.copyWith(
    textStyle: AppTextStyles.t20W500.copyWith(color: Colors.white60, height: 1.6),
    activeStyle: AppTextStyles.t26W700.copyWith(color: Colors.white, height: 1.6),
    translationStyle: AppTextStyles.t16W500.copyWith(color: Colors.white38),
    lineGap: 18,
  );

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
                ClipRRect(
                  borderRadius: BorderRadius.circular(24.sp),
                  child: CachedNetworkImage(
                    imageUrl: track.archive.cover,
                    width: 300.sp,
                    height: 300.sp,
                    fit: BoxFit.cover,
                    memCacheWidth: 600,
                    errorWidget: (_, _, _) => Container(
                      width: 300.sp,
                      height: 300.sp,
                      color: tvTheme.focusColor.withValues(alpha: 0.2),
                      child: Icon(Icons.music_note_rounded, size: 96.sp, color: tvTheme.focusColor),
                    ),
                  ),
                ),
                SizedBox(height: 28.sp),
                Text(
                  track.title,
                  style: AppTextStyles.t26W700.copyWith(color: Colors.white),
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
          Expanded(flex: 6, child: LyricView(controller: lyric, style: style)),
        ],
      ),
    );
  }
}

/// Which part of the control layer the remote is steering.
enum _BarZone { bar, seek }

/// Transport row + progress bar, steered by an index rather than by focus
/// traversal — the live player's control bar, in the music player's shape.
///
/// One [FocusNode] owns the keys and the highlighted item is drawn by
/// `selected:`, so what the viewer sees highlighted is exactly what OK
/// activates: no per-button focus ring to lose, and no d-pad hop that can land
/// on a button next to the one the ring was on.
class _ControlBar extends ConsumerStatefulWidget {
  const _ControlBar({required this.active, required this.onQueue, required this.onInteraction});

  /// Whether the controls are on screen; becoming active takes the keyboard.
  final bool active;

  final VoidCallback onQueue;

  /// Every key the bar consumes re-arms the page's auto-hide countdown.
  final VoidCallback onInteraction;

  @override
  ConsumerState<_ControlBar> createState() => _ControlBarState();
}

class _ControlBarState extends ConsumerState<_ControlBar> {
  final FocusNode _node = FocusNode(debugLabel: 'music/controls');

  /// Play/pause sits in the middle of the row; the highlight opens there.
  int _index = 2;
  _BarZone _zone = _BarZone.bar;

  static const int _itemCount = 8;

  @override
  void initState() {
    super.initState();
    if (widget.active) _takeFocus();
  }

  @override
  void didUpdateWidget(_ControlBar old) {
    super.didUpdateWidget(old);
    if (!old.active && widget.active) {
      _zone = _BarZone.bar;
      _takeFocus();
    }
  }

  @override
  void dispose() {
    _node.dispose();
    super.dispose();
  }

  void _takeFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.active && !_node.hasFocus) _node.requestFocus();
    });
  }

  static bool _isConfirm(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA;

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (!mounted) return KeyEventResult.ignored;

    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final key = event.logicalKey;
    widget.onInteraction();

    if (_isConfirm(key)) {
      if (_zone == _BarZone.seek) {
        setState(() => _zone = _BarZone.bar);
        return KeyEventResult.handled;
      }
      _activateIndex(_index);
      return KeyEventResult.handled;
    }

    switch (key) {
      case LogicalKeyboardKey.arrowLeft:
      case LogicalKeyboardKey.arrowRight:
        final int delta = key == LogicalKeyboardKey.arrowLeft ? -1 : 1;
        if (_zone == _BarZone.seek) {
          controller.seekAccelerated(delta);
        } else {
          setState(() => _index = (_index + delta + _itemCount) % _itemCount);
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowUp:
        // In the buttons row this is the page's key: it opens the queue.
        if (_zone == _BarZone.seek) {
          setState(() => _zone = _BarZone.bar);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowDown:
        if (_zone == _BarZone.bar) {
          setState(() => _zone = _BarZone.seek);
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
        unawaited(controller.seekAccelerated(-1));
      case 1:
        unawaited(controller.previous());
      case 2:
        unawaited(controller.togglePlayPause());
      case 3:
        unawaited(controller.next());
      case 4:
        unawaited(controller.seekAccelerated(1));
      case 5:
        unawaited(controller.cycleMode());
      case 6:
        unawaited(controller.toggleAudioOnly());
      case 7:
        widget.onQueue();
    }
  }

  /// A tap highlights the button it hit and runs it, so the mouse and the
  /// remote can never disagree about what is selected.
  void _activateAt(int index) {
    if (mounted) {
      setState(() {
        _zone = _BarZone.bar;
        _index = index;
      });
    }
    widget.onInteraction();
    _activateIndex(index);
  }

  static String _timeLabel(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    return h > 0 ? '$h:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicPlayerControllerProvider);
    final tvTheme = context.tvTheme;
    final bool seekZone = _zone == _BarZone.seek;

    return Focus(
      focusNode: _node,
      onKeyEvent: _onKey,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 18.sp),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(24.sp),
          border: Border.all(
            color: tvTheme.focusColor.withValues(alpha: seekZone ? 0.9 : 0.35),
            width: seekZone ? 2.sp : 1.sp,
          ),
        ),
        child: StreamBuilder<PlaybackState>(
          // One stream drives the whole bar: the progress row and the play/pause
          // glyph, which otherwise went stale until the next controller state
          // change.
          stream: ref.read(musicPlayerControllerProvider.notifier).playbackStream,
          builder: (context, snapshot) {
            final playback = snapshot.data;
            final position = playback?.position ?? Duration.zero;
            final duration = playback?.duration ?? Duration.zero;
            final handle = ref.read(musicPlayerControllerProvider.notifier).handle;
            final isPlaying = playback?.isPlaying ?? (handle?.isPlaying ?? false);
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
                    Expanded(
                      child: _ProgressBar(
                        position: position,
                        duration: duration,
                        focused: seekZone,
                        onInteraction: widget.onInteraction,
                      ),
                    ),
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
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12.sp,
                  runSpacing: 10.sp,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _excluded(
                      TvIconButton(
                        icon: const Icon(Icons.replay_10_rounded),
                        label: i18n('music_seek_back'),
                        size: TvIconButtonSize.large,
                        isSecondary: true,
                        selected: _index == 0,
                        onTap: () => _activateAt(0),
                      ),
                    ),
                    _excluded(
                      TvIconButton(
                        icon: const Icon(Icons.skip_previous_rounded),
                        label: i18n('music_prev'),
                        size: TvIconButtonSize.large,
                        isSecondary: true,
                        selected: _index == 1,
                        onTap: () => _activateAt(1),
                      ),
                    ),
                    SizedBox(width: 20.sp),
                    _excluded(
                      TvIconButton(
                        icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        label: i18n('music_play'),
                        size: TvIconButtonSize.large,
                        selected: _index == 2,
                        onTap: () => _activateAt(2),
                      ),
                    ),
                    _excluded(
                      TvIconButton(
                        icon: const Icon(Icons.skip_next_rounded),
                        label: i18n('music_next'),
                        size: TvIconButtonSize.large,
                        isSecondary: true,
                        selected: _index == 3,
                        onTap: () => _activateAt(3),
                      ),
                    ),
                    _excluded(
                      TvIconButton(
                        icon: const Icon(Icons.forward_10_rounded),
                        label: i18n('music_seek_forward'),
                        size: TvIconButtonSize.large,
                        isSecondary: true,
                        selected: _index == 4,
                        onTap: () => _activateAt(4),
                      ),
                    ),
                    _excluded(
                      TvButton(
                        title: i18n(state.mode.i18nKey),
                        icon: Icon(Icons.repeat_rounded, size: 22.sp),
                        size: TvButtonSize.mini,
                        isSecondary: true,
                        selected: _index == 5,
                        onTap: () => _activateAt(5),
                      ),
                    ),
                    _excluded(
                      TvButton(
                        title: i18n(state.audioOnly ? 'music_video_on' : 'music_audio_only'),
                        icon: Icon(state.audioOnly ? Icons.videocam_outlined : Icons.headphones_rounded, size: 22.sp),
                        size: TvButtonSize.mini,
                        isSecondary: true,
                        selected: _index == 6,
                        onTap: () => _activateAt(6),
                      ),
                    ),
                    _excluded(
                      TvButton(
                        title: i18n('music_tracks_title'),
                        icon: Icon(Icons.queue_music_rounded, size: 22.sp),
                        size: TvButtonSize.mini,
                        isSecondary: true,
                        selected: _index == 7,
                        onTap: () => _activateAt(7),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// The buttons draw the highlight but never take focus: one node owns the
  /// keys, and a d-pad hop can no longer land on a button next to the one the
  /// highlight was on. They stay tappable for a mouse.
  Widget _excluded(Widget child) => ExcludeFocus(child: child);
}

/// The seek bar. It has no FocusNode of its own — the bar's index steers it, so
/// the highlight it draws is the zone the remote is in.
class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.position,
    required this.duration,
    required this.focused,
    required this.onInteraction,
  });

  final Duration position;
  final Duration duration;
  final bool focused;
  final VoidCallback onInteraction;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final double progress = duration > Duration.zero
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return GestureDetector(
      onTap: onInteraction,
      child: AnimatedContainer(
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
