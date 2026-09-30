part of 'video_player_page.dart';


/// The video-mode player, modelled on newBV's layer scheme:
///
/// - the picture is always on; the bar starts hidden (live_play's overlay
///   model) and OK raises it with the focus on play;
/// - left/right seek ±10s with newBV's acceleration (consecutive presses
///   within 200ms grow the step by 5s, up to 60s);
/// - Up opens the part list, Down closes it;
/// - without a key for five seconds the bar slides away — every bar key and
///   every panel close re-arms the countdown, an open panel pauses it;
/// - Back peels one layer: any menu → part list → controls → exit page.
///
/// Beyond the base scheme this page carries the newBV player extras: the
/// subtitle track (x/player/wbi/v2), the danmaku settings panel, the aspect
/// toggle, the live viewer count, and the watch-progress recorder that feeds
/// both the local resume store and the bilibili heartbeat.
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

  /// live_play's overlay model: the bar starts hidden, OK raises it, and it
  /// hides itself five seconds after the last key — in menus-open state the
  /// countdown is paused instead.
  bool _controlsVisible = false;
  bool _partsOpen = false;
  bool _commentsOpen = false;
  final ScrollController _commentsScroll = ScrollController();
  final List<CommentItem> _comments = [];
  bool _commentsLoading = false;
  bool _commentsHasMore = true;
  int _commentsPage = 0;
  bool _qualityOpen = false;
  bool _danmakuOn = true;
  bool _subtitleOn = false;
  bool _aspectFill = false;
  final GlobalKey<VodDanmakuOverlayState> _danmakuKey = GlobalKey();

  // Per-part player extras: subtitles, online count, progress heartbeat.
  List<SubtitleCue> _subtitleCues = const [];
  SubtitleTrack? _subtitleTrack;
  int _onlineCount = 0;
  int _onlineCountForCid = 0;
  int _lastExtrasCid = 0;
  int _lastHeartbeatAt = 0;
  Timer? _progressTimer;
  Timer? _autoHideTimer;
  static const Duration _autoHideAfter = Duration(seconds: 5);
  String? _lastTrackId;

  /// The mode the music player held before this page is restored on exit.
  MusicPlayMode? _modeBeforeVideo;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((Object _) {});
    EmojiManager().preload('bilibili');
    final player = ref.read(musicPlayerControllerProvider.notifier);
    _modeBeforeVideo = ref.read(musicPlayerControllerProvider).mode;
    player.setPlayMode(MusicPlayMode.sequence);
    player.wrapAtQueueEnd = false;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // The bar starts hidden (live_play's entry): the root owns the keyboard
      // until OK raises the bar.
      _rootNode.requestFocus();
      // rendition rides the next resolve, the default rate applies once on
      // entry — a rate the user set (or a restored session carried) stands.
      if (!SettingsService.to.isInitialized) return;
      final video = SettingsService.to.videoState;
      final controller = ref.read(musicPlayerControllerProvider.notifier);
      controller.setPreferredQuality(video.preferredQuality);
      if (ref.read(musicPlayerControllerProvider).speed == 1.0 && video.defaultSpeed != 1.0) {
        unawaited(controller.setSpeed(video.defaultSpeed));
      }
    });
    _progressTimer = Timer.periodic(const Duration(seconds: 10), (_) => _recordProgress());
    ref.listenManual(musicPlayerControllerProvider, (previous, next) {
      final track = next.current;
      if (track?.id == _lastTrackId) return;
      _lastTrackId = track?.id;
      _loadPartExtras(track);
    }, fireImmediately: true);
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _autoHideTimer?.cancel();
    _commentsScroll.dispose();
    WakelockPlus.disable().catchError((Object _) {});
    // Video is not a resident session: back closes the video and tears the
    // player down — unlike music, whose queue keeps playing behind the UI.
    final player = ref.read(musicPlayerControllerProvider.notifier);
    player.wrapAtQueueEnd = true;
    unawaited(player.stop());
    if (_modeBeforeVideo != null) player.setPlayMode(_modeBeforeVideo!);
    _rootNode.dispose();
    _playNode.dispose();
    super.dispose();
  }

  /// Video part stepping: sequential, no wrap. The ends answer with a toast —
  /// unlike the music queue, whose next() cycles to the other end.
  Future<void> _gotoPart(int delta) async {
    final state = ref.read(musicPlayerControllerProvider);
    final target = state.index + delta;
    if (target < 0) {
      ToastUtil.show(i18n('video_part_first'));
      return;
    }
    if (target >= state.queue.length) {
      ToastUtil.show(i18n('video_part_last'));
      return;
    }
    await ref.read(musicPlayerControllerProvider.notifier).jumpTo(target);
  }

  /// Subtitles, the viewer count and the heartbeat are per part.
  Future<void> _loadPartExtras(MusicTrack? track) async {
    final cid = track?.part.cid ?? 0;
    if (track == null || cid <= 0) {
      if (mounted) {
        setState(() {
          _subtitleCues = const [];
          _subtitleTrack = null;
          _subtitleOn = false;
          _onlineCount = 0;
          _lastExtrasCid = 0;
        });
      }
      return;
    }
    if (_lastExtrasCid == cid) return;
    _lastExtrasCid = cid;
    setState(() {
      _subtitleCues = const [];
      _subtitleTrack = null;
      _subtitleOn = false;
      _onlineCount = 0;
    });
    try {
      final subtitles = await BilibiliUgcApi.instance.getSubtitles(bvid: track.archive.bvid, cid: cid);
      if (!mounted || track.id != _lastTrackId) return;
      setState(() {
        _subtitleTrack = subtitles.isEmpty ? null : subtitles.first;
        _subtitleOn = _subtitleTrack != null;
      });
      if (_subtitleTrack != null) {
        final cues = await BilibiliUgcApi.instance.fetchSubtitleCues(_subtitleTrack!.url);
        if (!mounted || track.id != _lastTrackId) return;
        setState(() => _subtitleCues = cues);
      }
    } catch (_) {
      // Subtitles are a bonus; nothing degrades without them.
    }
    if (_onlineCountForCid != cid) {
      _onlineCountForCid = cid;
      try {
        final count = await BilibiliUgcApi.instance.getOnlineCount(bvid: track.archive.bvid, cid: cid);
        if (!mounted || track.id != _lastTrackId) return;
        setState(() => _onlineCount = count);
      } catch (_) {}
    }
    // One heartbeat per part start keeps the bilibili history row fresh.
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    if (track.archive.aid > 0 && now - _lastHeartbeatAt > 60) {
      _lastHeartbeatAt = now;
      BilibiliUgcApi.instance
          .reportHistory(aid: track.archive.aid, cid: cid, progress: 0, bvid: track.archive.bvid)
          .catchError((Object _) {});
    }
  }

  /// The local resume store tick — every 10s the position lands in
  /// `videoWatchProgress`, which the cards' progress bars read.
  void _recordProgress() {
    final handle = ref.read(musicPlayerControllerProvider.notifier).handle;
    final track = ref.read(musicPlayerControllerProvider).current;
    if (handle == null || track == null || track.part.epId > 0) return;
    final position = handle.position.inSeconds;
    final duration = handle.duration.inSeconds;
    if (duration <= 0) return;
    ref
        .read(videoProgressControllerProvider.notifier)
        .record(
          track.archive.bvid,
          cid: track.part.cid,
          position: position,
          duration: duration,
          archive: track.archive,
        );
  }

  /// live_play's clock: five seconds after the last key the bar slides away.
  /// Every bar key re-arms this through [_ControlBar.onInteraction].
  void _armAutoHide() {
    _autoHideTimer?.cancel();
    _autoHideTimer = Timer(_autoHideAfter, () {
      if (!mounted || !_controlsVisible) return;
      _hideControls();
    });
  }

  void _showControls() {
    _autoHideTimer?.cancel();
    setState(() => _controlsVisible = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controlsVisible) _playNode.requestFocus();
    });
    _armAutoHide();
  }

  void _hideControls() {
    _autoHideTimer?.cancel();
    setState(() => _controlsVisible = false);
    _rootNode.requestFocus();
  }

  bool get _anyMenuOpen => _qualityOpen;

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
      unawaited(_gotoPart(1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.mediaTrackPrevious) {
      unawaited(_gotoPart(-1));
      return KeyEventResult.handled;
    }

    // Back peels one layer: menus, then parts, then the controls, then the
    // page pops — and the pop disposes the player. Video is not a resident
    // session like the music queue.
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.browserBack) {
      if (_qualityOpen) {
        setState(() => _qualityOpen = false);
        _armAutoHide();
        return KeyEventResult.handled;
      }
      if (_commentsOpen) {
        _closeComments();
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
    if (_commentsOpen) return KeyEventResult.ignored;
    if (_partsOpen) return KeyEventResult.ignored;

    if (_controlsVisible) {
      // The bar owns left/right/OK/now — only Up reaches here (bubbled, the
      // bar zone returns it ignored): it opens the parts list.
      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        _autoHideTimer?.cancel();
        setState(() => _partsOpen = true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Controls hidden: the root owns the keyboard. Left/Right seek without
    // raising the bar, so a held key streams KeyRepeatEvents through the same
    // call and walks newBV's acceleration up to 60s — raising the bar would
    // hand the repeats to the bar's index walk instead.
    if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
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
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      // Hidden-state Up/Down step parts — sequential, no wrap, a toast at
      // each end.
      unawaited(_gotoPart(-1));
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      unawaited(_gotoPart(1));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _closeParts() {
    setState(() => _partsOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controlsVisible) _playNode.requestFocus();
    });
    _armAutoHide();
  }

  /// In-player comments (newBV's player comments): pages the shared reply API
  /// for the open archive into the side panel.
  Future<void> _loadComments(int oid) async {
    if (_commentsLoading || oid <= 0) return;
    _commentsLoading = true;
    try {
      final page = _commentsPage + 1;
      final (roots, _, hasMore) = await BilibiliUgcApi.instance.getComments(oid: oid, page: page, hot: true);
      if (!mounted) return;
      setState(() {
        _comments.addAll(roots);
        _commentsPage = page;
        _commentsHasMore = hasMore;
        _commentsLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _commentsLoading = false);
    }
  }

  void _openComments(MusicTrack? track) {
    final oid = track?.archive.aid ?? 0;
    if (oid <= 0) return;
    _autoHideTimer?.cancel();
    setState(() {
      _commentsOpen = true;
      if (_commentsPage == 0) _loadComments(oid);
    });
  }

  void _closeComments() {
    setState(() => _commentsOpen = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _controlsVisible) _playNode.requestFocus();
    });
    _armAutoHide();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final track = state.current;

    return PopScope(
      canPop: !_anyMenuOpen && !_commentsOpen && !_partsOpen && !_controlsVisible,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_qualityOpen) {
          setState(() => _qualityOpen = false);
        } else if (_commentsOpen) {
          _closeComments();
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
                    HandleVideoSurface(handle: controller.handle!, fit: _aspectFill ? BoxFit.cover : BoxFit.contain)
                  else
                    VideoIdleSurface(track: track, resolving: state.resolving),

                  // ---------------------------------------------------- danmaku
                  if (_danmakuOn && controller.handle != null && track != null && track.part.cid > 0)
                    VodDanmakuOverlay(
                      key: _danmakuKey,
                      handle: controller.handle!,
                      cid: track.part.cid,
                      aid: track.archive.aid,
                      bvid: track.archive.bvid,
                    ),

                  // ---------------- state tips (newBV's PlayStateTips):
                  // error > buffering > paused, three mutually exclusive faces.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: StreamBuilder<PlaybackState>(
                        stream: controller.playbackStream,
                        builder: (context, snapshot) {
                          final playback = snapshot.data;
                          if (state.error.isNotEmpty) {
                            return Center(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 14.sp),
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.72),
                                  borderRadius: BorderRadius.circular(16.sp),
                                ),
                                child: Text(
                                  state.error,
                                  style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white),
                                ),
                              ),
                            );
                          }
                          if (playback?.buffering == true) {
                            return Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 44.sp,
                                    height: 44.sp,
                                    child: CircularProgressIndicator(strokeWidth: 3.sp, color: tvTheme.focusColor),
                                  ),
                                  SizedBox(height: 12.sp),
                                  Text(
                                    i18n('video_state_buffering'),
                                    style: AppTextStyles.t16.copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          if (controller.handle != null && playback?.isPlaying == false && track != null) {
                            return Align(
                              alignment: Alignment.bottomRight,
                              child: Padding(
                                padding: EdgeInsets.only(right: 48.sp, bottom: 64.sp),
                                child: Icon(
                                  Icons.pause_circle_outline_rounded,
                                  size: 72.sp,
                                  color: Colors.white.withValues(alpha: 0.55),
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),

                  // --------------------------------------------------- subtitle
                  if (_subtitleOn && controller.handle != null)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 140.sp,
                      child: IgnorePointer(
                        child: SubtitleLines(cues: _subtitleCues, handle: controller.handle!),
                      ),
                    ),

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
                              style: AppTextStyles.t22.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                          ),
                          SizedBox(width: 12.sp),
                          if (track != null && track.archive.parts.length > 1)
                            Text(
                              'P${track.part.page}/${track.archive.parts.length}',
                              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white70),
                            ),
                          SizedBox(width: 12.sp),
                          if (BilibiliMusicApi.qualityLabel(state.quality).isNotEmpty)
                            Text(
                              BilibiliMusicApi.qualityLabel(state.quality),
                              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white70),
                            ),
                          SizedBox(width: 12.sp),
                          if (_onlineCount > 0) ...[
                            Icon(Icons.visibility_outlined, size: 20.sp, color: Colors.white70),
                            SizedBox(width: 4.sp),
                            Text(
                              readableCount(_onlineCount.toString()),
                              style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w500, color: Colors.white70),
                            ),
                            SizedBox(width: 12.sp),
                          ],
                          if (track != null)
                            ConstrainedBox(
                              constraints: BoxConstraints(maxWidth: 220.sp),
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

                  // --------------------------------------------- bottom control bar
                  AnimatedPositioned(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    bottom: _controlsVisible ? 32.sp : -160.sp,
                    left: 48.sp,
                    right: 48.sp,
                    child: IgnorePointer(
                      ignoring: !_controlsVisible || _anyMenuOpen || _partsOpen || _commentsOpen,
                      child: ExcludeFocus(
                        excluding: !_controlsVisible || _anyMenuOpen || _partsOpen || _commentsOpen,
                        child: VideoPlayerControlBar(
                          playNode: _playNode,
                          onInteraction: _armAutoHide,
                          onPrevPart: () => unawaited(_gotoPart(-1)),
                          onNextPart: () => unawaited(_gotoPart(1)),
                          onOpenParts: () {
                            _autoHideTimer?.cancel();
                            setState(() => _partsOpen = true);
                          },
                          onOpenQuality: () {
                            _autoHideTimer?.cancel();
                            setState(() => _qualityOpen = true);
                          },
                          onOpenDanmakuSettings: () {
                            _autoHideTimer?.cancel();
                            const DanmakuSettingsRoute().push(context);
                          },
                          commentsEnabled: track != null && track.archive.aid > 0,
                          onOpenComments: () => _openComments(track),
                          danmakuOn: _danmakuOn,
                          subtitleOn: _subtitleOn,
                          aspectFill: _aspectFill,
                          onToggleDanmaku: () => setState(() => _danmakuOn = !_danmakuOn),
                          onToggleSubtitle: _subtitleTrack == null
                              ? null
                              : () => setState(() => _subtitleOn = !_subtitleOn),
                          onToggleAspect: () => setState(() => _aspectFill = !_aspectFill),
                        ),
                      ),
                    ),
                  ),

                  // ------------------------------ bottom edge progress line
                  // newBV's thin line: the whole video's progress as one hair
                  if (ref.watch(videoSettingsControllerProvider.select((m) => m.persistentProgress)))
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: StreamBuilder<PlaybackState>(
                        stream: ref.read(musicPlayerControllerProvider.notifier).playbackStream,
                        builder: (context, snapshot) {
                          final playback = snapshot.data;
                          final position = playback?.position ?? Duration.zero;
                          final duration = playback?.duration ?? Duration.zero;
                          final double progress = duration > Duration.zero
                              ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
                              : 0.0;
                          final accent = tvTheme.focusColor;
                          return SizedBox(
                            height: 5.sp,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ColoredBox(color: Colors.white.withValues(alpha: 0.16)),
                                FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: progress,
                                  child: ColoredBox(color: accent),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                  // ----------------------------------------------- comments panel
                  if (_commentsOpen && track != null)
                    Positioned(
                      top: 100.sp,
                      bottom: 100.sp,
                      right: 48.sp,
                      width: 620.sp,
                      child: VideoCommentsPanel(
                        oid: track.archive.aid,
                        comments: _comments,
                        scroll: _commentsScroll,
                        loading: _commentsLoading,
                        hasMore: _commentsHasMore,
                        onLoadMore: () => _loadComments(track.archive.aid),
                        onClose: _closeComments,
                      ),
                    ),

                  // -------------------------------------------------- parts panel
                  if (_partsOpen)
                    Positioned(
                      top: 100.sp,
                      bottom: 100.sp,
                      right: 48.sp,
                      width: 520.sp,
                      child: VideoPartsPanel(onClose: _closeParts),
                    ),

                  // ------------------------------------------------- quality menu
                  if (_qualityOpen)
                    Positioned(
                      top: 100.sp,
                      right: 48.sp,
                      width: 320.sp,
                      child: VideoQualityMenu(onClose: () => setState(() => _qualityOpen = false)),
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
