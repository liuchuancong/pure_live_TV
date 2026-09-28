import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/modules/media/widgets/handle_video_surface.dart';
import 'package:pure_live/modules/music/controllers/library/music_library_controller.dart';
import 'package:pure_live/modules/music/pages/playback/widgets/player_widgets.dart';
import 'package:pure_live/modules/music/services/music_lyric_service.dart';
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
  bool _settingsOpen = false;

  /// The live_play follow gesture: a second Left press inside the window is
  /// the follow toggle, so a single stray Left costs nothing.
  DateTime _lastLeftPress = DateTime.fromMillisecondsSinceEpoch(0);

  /// Whether the next bar activation should land in the seek zone — the
  /// hidden-state arrow seeks raise the bar with the keyboard already there.
  bool _activateInSeekZone = false;

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

  /// live_play's clock: the bar hides itself five seconds after the last
  /// key, in every view — video, lyrics, poster.
  void _armAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(_autoHideAfter, () {
      if (!mounted || !_controlsVisible) return;
      _hideControls();
    });
  }

  void _showControls({bool inSeekZone = false}) {
    _activateInSeekZone = inSeekZone;
    if (!_controlsVisible) setState(() => _controlsVisible = true);
    _armAutoHide();
  }

  void _hideControls() {
    _autoHideTimer?.cancel();
    _activateInSeekZone = false;
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

    // Controls hidden: live_play's model — Right opens the playlist, a
    // double-pressed Left follows the album, Up/Down walk the queue, OK
    // raises the bar (whose seek zone owns the ±10s).
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    if (event.logicalKey == LogicalKeyboardKey.select ||
        event.logicalKey == LogicalKeyboardKey.enter) {
      _showControls();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _openQueue();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      final now = DateTime.now();
      final isDouble = now.difference(_lastLeftPress) < const Duration(milliseconds: 350);
      _lastLeftPress = now;
      if (isDouble) {
        final track = ref.read(musicPlayerControllerProvider).current;
        if (track != null) {
          ref.read(musicLibraryControllerProvider.notifier).toggleFavorite(track.archive);
        }
      }
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      controller.previous();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      controller.next();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _openQueue() {
    _autoHideTimer?.cancel();
    if (!_queueOpen || _settingsOpen) {
      setState(() {
        _queueOpen = true;
        _settingsOpen = false;
      });
    }
  }

  void _closeQueue() {
    if (_queueOpen) setState(() => _queueOpen = false);
    _armAutoHide();
  }

  void _openSettings() {
    _autoHideTimer?.cancel();
    if (!_settingsOpen || _queueOpen) {
      setState(() {
        _settingsOpen = true;
        _queueOpen = false;
      });
    }
  }

  void _closeSettings() {
    if (_settingsOpen) setState(() => _settingsOpen = false);
    _armAutoHide();
  }

  /// Bumped when a lyric is picked by hand, so the now-playing view rebuilds
  /// and loads it.
  int _lyricRevision = 0;

  /// Lists every lyric the chain can find for the current track and lets the
  /// viewer pick one; the pick is remembered and used for every later play.
  Future<void> _showLyricPicker() async {
    final track = ref.read(musicPlayerControllerProvider).current;
    if (track == null || !mounted) return;

    final MusicLyricCandidate? picked = await TvDialogUtils.show<MusicLyricCandidate>(
      context: context,
      builder: (_) => MusicLyricPickerDialog(track: track),
    );

    if (picked == null || !mounted) return;

    MusicLyricService.instance.saveManualLyric(track.title, picked.lyric);
    setState(() => _lyricRevision++);
    ToastUtil.show(i18n('music_lyric_picked'));
  }

  /// Moves music playback onto another engine, re-opening the current track
  /// where it is playing now.

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
      canPop: !_queueOpen && !_settingsOpen && !_controlsVisible,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_queueOpen) {
          _closeQueue();
        } else if (_settingsOpen) {
          _closeSettings();
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
                MusicNowPlayingView(track: track, resolving: state.resolving, lyricRevision: _lyricRevision)
              else
                PlayerIdleSurface(track: track, resolving: state.resolving),

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
                    child: MusicControlBar(
                      active: _controlsVisible && !_queueOpen && !_settingsOpen,
                      onSettings: _openSettings,
                      activateInSeekZone: _activateInSeekZone,
                      onQueue: _openQueue,
                      onInteraction: _armAutoHide,
                      onPickLyric: _showLyricPicker,
                    ),
                  ),
                ),
              ),

              // -------------------------------------------------- settings panel
              if (_settingsOpen)
                Positioned(
                  top: 100.sp,
                  bottom: 100.sp,
                  right: 48.sp,
                  width: 640.sp,
                  child: MusicPlayerSettingsPanel(onClose: _closeSettings),
                ),

              // --------------------------------------- flush-bottom progress line
              Positioned(left: 0, right: 0, bottom: 0, child: MusicBottomProgressLine()),

              // ------------------------------------------------------ queue panel
              if (_queueOpen && !_settingsOpen)
                Positioned(
                  top: 100.sp,
                  bottom: 100.sp,
                  right: 48.sp,
                  width: 520.sp,
                  child: MusicQueuePanel(
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

