import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:pure_live/exports/exports.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:pure_live/modules/vod/widgets/handle_video_surface.dart';
import 'package:pure_live/modules/music/services/music_lyric_service.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';
import 'package:pure_live/modules/music/pages/playback/widgets/player_widgets.dart';

/// The full-screen music player.
///
/// Remote model — one key handler owns the page and steers an index, the way the
/// live player does, so there is no per-button focus ring to hunt for:
/// - controls hidden: OK brings them back, left/right seek with newBV's press
///   acceleration (a long press streams repeats through the same call and
///   walks the step up to 60s), up/down previous/next;
/// - bar up: left/right walk its buttons with wrap, OK activates the highlighted
///   one, down drops into the seek bar (left/right seek there), Back peels one
///   layer out (queue → controls → page). The playlist opens from its bar
///   button only; no key shortcut raises it.
/// - without a key for five seconds the bar slides away in every view —
///   video, lyrics and poster alike (live_play's overlay model): the bar
///   starts hidden, OK raises it, and every key re-arms the countdown.
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

  /// live_play's entry: the bar starts hidden — OK raises it, and it hides
  /// itself five seconds after the last key, in every view.
  bool _controlsVisible = false;
  bool _queueOpen = false;
  bool _settingsOpen = false;

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
    // A previous visit that left with the picture on lost its texture: mpv
    // keeps decoding into the output it lost track of, so re-entering shows
    // black until the output is rebuilt. One vid cycle re-attaches it (the
    final player = ref.read(musicPlayerControllerProvider.notifier);
    if (!ref.read(musicPlayerControllerProvider).audioOnly && player.videoSurfaceNeedsReattach) {
      player.videoSurfaceNeedsReattach = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(player.reattachVideoSurface());
      });
    }
  }

  @override
  void dispose() {
    WakelockPlus.disable().catchError((Object _) {});
    _autoHideTimer?.cancel();
    // Leaving with the picture on: the texture dies with this page while the
    // resident session keeps playing — flag the re-attach for the next mount.
    final player = ref.read(musicPlayerControllerProvider.notifier);
    if (!ref.read(musicPlayerControllerProvider).audioOnly && player.handle != null) {
      player.videoSurfaceNeedsReattach = true;
    }
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
      // The bar owns left/right/OK/down. Up is left unhandled so the bar's own
      // rows can take it; the playlist itself opens from its bar button only.
      if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        _hideControls();
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Media keys work in every layer, like the video player's handling.
    if (event.logicalKey == LogicalKeyboardKey.mediaPlayPause ||
        event.logicalKey == LogicalKeyboardKey.mediaPlay ||
        event.logicalKey == LogicalKeyboardKey.mediaPause) {
      ref.read(musicPlayerControllerProvider.notifier).togglePlayPause();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.mediaTrackNext) {
      ref.read(musicPlayerControllerProvider.notifier).next();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.mediaTrackPrevious) {
      ref.read(musicPlayerControllerProvider.notifier).previous();
      return KeyEventResult.handled;
    }

    // Controls hidden: live_play's model — OK raises the bar, Up/Down walk the
    // queue, and Left/Right seek with newBV's press acceleration. Holding the
    // key streams KeyRepeatEvents through the same call, so a long press walks
    // the step up to 60s without the bar ever getting in the way.
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
      _showControls();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      controller.seekAccelerated(1);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      controller.seekAccelerated(-1);
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

    // Switching between the picture and the lyrics view is a key-driven mode
    // change too: it re-arms the same 5s countdown every key uses.
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
                    top: _controlsVisible ? 24.ts(context) : -120.ts(context),
                    left: 48.sp,
                    right: 48.sp,
                    child: IgnorePointer(
                      ignoring: !_controlsVisible,
                      child: Row(
                        children: [
                          Icon(Icons.music_note_rounded, size: 28.ts(context), color: tvTheme.focusColor),
                          SizedBox(width: 10.ts(context)),
                          Expanded(
                            child: Text(
                              track?.title ?? i18n('music_player_title'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.t22.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 12.ts(context)),
                          if (track != null && track.archive.parts.length > 1)
                            Text(
                              'P${track.part.page}/${track.archive.parts.length}',
                              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white70),
                            ),
                          SizedBox(width: 12.ts(context)),
                          if (BilibiliMusicApi.qualityLabel(state.quality).isNotEmpty)
                            Text(
                              BilibiliMusicApi.qualityLabel(state.quality),
                              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white70),
                            ),
                          SizedBox(width: 12.ts(context)),
                          if (track != null)
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 220.ts(context)),
                              child: Text(
                                track.archive.upName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white70),
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
                    bottom: _controlsVisible ? 32.ts(context) : -180.ts(context),
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
                      width: 640.ts(context),
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
                      width: 520.ts(context),
                      child: MusicQueuePanel(onClose: _closeQueue),
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
