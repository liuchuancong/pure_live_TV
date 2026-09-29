import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_core/media_core.dart';
import 'package:pure_live/services/index.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pure_live/modules/media/api/bilibili_ugc_api.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/media/api/bilibili_danmaku_api.dart';
import 'package:pure_live/modules/media/widgets/music_video_card.dart';
import 'package:pure_live/modules/video/widgets/vod_danmaku_overlay.dart';
import 'package:pure_live/modules/media/widgets/handle_video_surface.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/modules/video/controllers/playback/video_progress_controller.dart';

/// The video-mode player, modelled on newBV's layer scheme:
///
/// - the picture is always on; controls start visible with the focus on play;
/// - OK toggles the controls, left/right seek ±10s with newBV's acceleration
///   (consecutive presses within 200ms grow the step by 5s, up to 60s);
/// - Up opens the part list, Down closes it;
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
  bool _controlsVisible = true;
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
  String? _lastTrackId;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable().catchError((Object _) {});
    EmojiManager().preload('bilibili');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _playNode.requestFocus();
      // The video settings' player defaults (newBV's 播放设置): the preferred
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
    _commentsScroll.dispose();
    WakelockPlus.disable().catchError((Object _) {});
    _rootNode.dispose();
    _playNode.dispose();
    super.dispose();
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
      controller.next();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.mediaTrackPrevious) {
      controller.previous();
      return KeyEventResult.handled;
    }

    // Back peels one layer: menus, then parts, then the controls, then the
    // page pops. (Popping never stops the video — the shared controller keeps
    // playing.)
    if (event.logicalKey == LogicalKeyboardKey.escape ||
        event.logicalKey == LogicalKeyboardKey.goBack ||
        event.logicalKey == LogicalKeyboardKey.browserBack) {
      if (_qualityOpen) {
        setState(() => _qualityOpen = false);
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
        setState(() => _partsOpen = true);
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    // Controls hidden: the root owns the keyboard. A seek raises the bar and
    // lands the focus on it — the viewer asked for the controls, and the bar's
    // own keys (walk / seek / OK) take over from there.
    if (event.logicalKey == LogicalKeyboardKey.select || event.logicalKey == LogicalKeyboardKey.enter) {
      _showControls();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      controller.seekAccelerated(-1);
      _showControls();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      controller.seekAccelerated(1);
      _showControls();
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
  }

  /// TV send-danmaku flow: a dialog with the soft keyboard, then the web
  /// send endpoint; the comment is echoed locally on success.
  Future<void> _showSendDialog(MusicTrack track) async {
    final api = BilibiliDanmakuApi.instance;
    if (!BilibiliUgcApi.instance.isLoggedIn) {
      ToastUtil.show(i18n('video_action_need_login'));
      return;
    }
    final controller = TextEditingController();
    final sent = await showDialog<bool>(
      context: context,
      builder: (context) {
        final tvTheme = context.tvTheme;
        return Dialog(
          backgroundColor: tvTheme.cardColor,
          insetPadding: EdgeInsets.symmetric(horizontal: 460.sp, vertical: 280.sp),
          child: Padding(
            padding: EdgeInsets.all(24.sp),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  i18n('video_danmaku_send'),
                  style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w700, color: tvTheme.primaryTextColor),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.sp),
                TvInputField(
                  controller: controller,
                  hint: i18n('video_danmaku_send_hint'),
                  height: 64.sp,
                  maxLines: 1,
                  onSubmitted: (value) => Navigator.pop(context, value.trim().isNotEmpty),
                ),
                SizedBox(height: 16.sp),
                TvButton(
                  title: i18n('send'),
                  icon: Icon(Icons.send_rounded, size: 24.sp),
                  onTap: controller.text.trim().isNotEmpty ? () => Navigator.pop(context, true) : null,
                ),
                SizedBox(height: 4.sp),
                Text(
                  i18n('video_danmaku_send_rules'),
                  style: AppTextStyles.t14.copyWith(color: tvTheme.secondaryTextColor),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
    final text = controller.text.trim();
    controller.dispose();
    if (sent != true || text.isEmpty) return;
    try {
      await api.sendDanmaku(aid: track.archive.aid, cid: track.part.cid, message: text, bvid: track.archive.bvid);
      _danmakuKey.currentState?.inject(text);
      if (mounted) ToastUtil.show(i18n('video_danmaku_sent'));
    } catch (_) {
      if (mounted) ToastUtil.show(i18n('video_action_failed'));
    }
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
                    _IdleSurface(track: track, resolving: state.resolving),

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
                        child: _ControlBar(
                          playNode: _playNode,
                          onOpenParts: () => setState(() => _partsOpen = true),
                          onOpenQuality: () => setState(() => _qualityOpen = true),
                          onOpenDanmakuSettings: () => const DanmakuSettingsRoute().push(context),
                          onSendDanmaku: (track == null || track.part.cid <= 0) ? null : () => _showSendDialog(track),
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
                  // at the very bottom during playback, on by the 常显进度条 setting.
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
                      child: _CommentsPanel(
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

/// The subtitle line stack, driven by a timer against the handle position.
class SubtitleLines extends StatefulWidget {
  const SubtitleLines({super.key, required this.cues, required this.handle});

  final List<SubtitleCue> cues;
  final PlayerHandle handle;

  @override
  State<SubtitleLines> createState() => _SubtitleLinesState();
}

class _SubtitleLinesState extends State<SubtitleLines> {
  Timer? _timer;
  String _text = '';

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(milliseconds: 250), (_) => _tick());
  }

  void _tick() {
    if (widget.cues.isEmpty) return;
    final now = widget.handle.position.inMilliseconds / 1000.0;
    String active = '';
    for (final cue in widget.cues) {
      if (now >= cue.from && now <= cue.to) {
        active = cue.text;
        break;
      }
    }
    if (active != _text) setState(() => _text = active);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_text.isEmpty) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final line in _text.split('\n').take(2))
          Container(
            margin: EdgeInsets.only(top: 4.sp),
            padding: EdgeInsets.symmetric(horizontal: 14.sp, vertical: 6.sp),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8.sp),
            ),
            child: Text(
              line,
              textAlign: TextAlign.center,
              style: AppTextStyles.t20.copyWith(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                shadows: [Shadow(color: Colors.black, blurRadius: 4)],
              ),
            ),
          ),
      ],
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

/// Bottom controls, live_play's index-driven model: the bar holds ONE focus
/// node and owns every key while visible — left/right walk the buttons (with
/// wrap), OK activates the highlighted one, down drops into the seek strip
/// where left/right seek and up returns. The buttons themselves never take
/// focus; they only draw the highlight, so nothing fights the bar.
enum _BarZone { bar, seek }

class _ControlBar extends ConsumerStatefulWidget {
  const _ControlBar({
    required this.playNode,
    required this.onOpenParts,
    required this.onOpenQuality,
    required this.onOpenDanmakuSettings,
    required this.commentsEnabled,
    required this.onOpenComments,
    required this.onSendDanmaku,
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
  final VoidCallback onOpenParts;
  final VoidCallback onOpenQuality;
  final VoidCallback onOpenDanmakuSettings;
  final bool commentsEnabled;
  final VoidCallback onOpenComments;
  final VoidCallback? onSendDanmaku;
  final bool danmakuOn;
  final bool subtitleOn;
  final bool aspectFill;
  final VoidCallback onToggleDanmaku;
  final VoidCallback? onToggleSubtitle;
  final VoidCallback onToggleAspect;

  @override
  ConsumerState<_ControlBar> createState() => _ControlBarState();
}

class _ControlBarState extends ConsumerState<_ControlBar> {
  _BarZone _zone = _BarZone.bar;
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

  static const int _itemCount = 14;

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
          if (_zone == _BarZone.bar) _revealSelection();
        }
        return KeyEventResult.handled;
      case LogicalKeyboardKey.arrowDown:
        if (_zone == _BarZone.bar) {
          setState(() => _zone = _BarZone.seek);
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      case LogicalKeyboardKey.arrowUp:
        if (_zone == _BarZone.seek) {
          setState(() => _zone = _BarZone.bar);
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
        unawaited(controller.previous());
      case 1:
        unawaited(controller.togglePlayPause());
      case 2:
        unawaited(controller.next());
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
        widget.onSendDanmaku?.call();
      case 11:
        widget.onOpenDanmakuSettings();
      case 12:
        widget.onToggleSubtitle?.call();
      case 13:
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
            color: tvTheme.focusColor.withValues(alpha: _zone == _BarZone.seek ? 0.9 : 0.35),
            width: _zone == _BarZone.seek ? 2.sp : 1.sp,
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
                label: i18n('music_prev'),
                icon: const Icon(Icons.skip_previous_rounded),
                active: false,
                secondary: true,
                onTap: () => controller.previous(),
              ),
              (
                label: i18n('music_play'),
                icon: Icon(isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                active: true,
                secondary: false,
                onTap: () => controller.togglePlayPause(),
              ),
              (
                label: i18n('music_next'),
                icon: const Icon(Icons.skip_next_rounded),
                active: false,
                secondary: true,
                onTap: () => controller.next(),
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
                label: i18n('music_tracks_title'),
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
                label: i18n('video_danmaku_send'),
                icon: Icon(Icons.edit_outlined, size: 22.sp),
                active: false,
                secondary: true,
                onTap: widget.onSendDanmaku,
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
            final bool seekZone = _zone == _BarZone.seek;

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
                  height: _BarPill.height,
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
                        selected: _zone == _BarZone.bar && _index == i,
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
class _BarPill extends StatelessWidget {
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

  static double get height => _height.sp;

  final Widget icon;
  final String label;
  final bool selected;
  final bool active;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const Color foreground = Colors.white;
    final TextStyle textStyle = (selected ? AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600) : AppTextStyles.t20)
        .copyWith(color: foreground);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedScale(
        scale: selected ? 1.05 : 1.0,
        duration: TvFocusStyle.focusDuration(selected),
        curve: TvFocusStyle.curve,
        child: AnimatedContainer(
          duration: TvFocusStyle.focusDuration(selected),
          curve: TvFocusStyle.curve,
          height: _height.sp,
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: _hPadding.sp),
          decoration: BoxDecoration(
            color: selected ? accent : Colors.white.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular((_height / 3).sp),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconTheme.merge(
                data: IconThemeData(color: selected ? foreground : (active ? accent : Colors.white70)),
                child: icon,
              ),
              SizedBox(width: _gap.sp),
              Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: textStyle),
            ],
          ),
        ),
      ),
    );
  }
}

class _PartListPanel extends ConsumerStatefulWidget {
  const _PartListPanel({required this.onClose});

  final VoidCallback onClose;

  @override
  ConsumerState<_PartListPanel> createState() => _PartListPanelState();
}

/// Opens with the keyboard ON the playing row, the music queue's recipe:
/// per-row nodes, one post-frame jump, one requestFocus — opened, the panel
/// used to leave focus nowhere and the remote dead.
class _PartListPanelState extends ConsumerState<_PartListPanel> {
  final ScrollController _scroll = ScrollController();
  final Map<int, FocusNode> _rowNodes = <int, FocusNode>{};
  bool _steered = false;

  FocusNode _nodeAt(int index) => _rowNodes.putIfAbsent(index, FocusNode.new);

  @override
  void dispose() {
    _scroll.dispose();
    for (final node in _rowNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  /// Only the first build steers; rebuilds must not drag focus back.
  void _steerToCurrent(int index) {
    _steered = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      // Row stride: 64.sp height + 8.sp bottom margin.
      final target = (index * 72.0).sp - _scroll.position.viewportDimension / 2;
      _scroll.jumpTo(target.clamp(0.0, _scroll.position.maxScrollExtent));
      _nodeAt(index).requestFocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicPlayerControllerProvider);
    final controller = ref.read(musicPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    if (!_steered && state.index >= 0 && state.queue.isNotEmpty) _steerToCurrent(state.index);

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
                    style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                TvIconButton(
                  icon: const Icon(Icons.close_rounded),
                  size: TvIconButtonSize.small,
                  isSecondary: true,
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: EdgeInsets.only(left: 16.sp, right: 16.sp, bottom: 16.sp),
              itemCount: state.queue.length,
              itemBuilder: (context, index) {
                final track = state.queue[index];
                final isCurrent = index == state.index;
                return Padding(
                  padding: EdgeInsets.only(bottom: 8.sp),
                  child: TvFocusable(
                    focusNode: _nodeAt(index),
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
                                  : Text(
                                      '${index + 1}',
                                      style: AppTextStyles.t16.copyWith(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white54,
                                      ),
                                    ),
                            ),
                            SizedBox(width: 10.sp),
                            Expanded(
                              child: Text(
                                track.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.t16.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isCurrent ? accent : Colors.white,
                                ),
                              ),
                            ),
                            Text(
                              MusicVideoCard.formatDuration(
                                track.part.duration > 0 ? track.part.duration : track.archive.duration,
                              ),
                              style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: Colors.white54),
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
                Expanded(
                  child: Text(
                    i18n('video_quality'),
                    style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
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
          for (final option in state.qualityOptions)
            Padding(
              padding: EdgeInsets.only(left: 12.sp, right: 12.sp, bottom: 8.sp),
              child: TvFocusable(
                autofocus: option.quality == state.quality,
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
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isCurrent ? accent : Colors.white,
                            ),
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

class _CommentsPanel extends StatefulWidget {
  const _CommentsPanel({
    required this.oid,
    required this.comments,
    required this.scroll,
    required this.loading,
    required this.hasMore,
    required this.onLoadMore,
    required this.onClose,
  });

  final int oid;
  final List<CommentItem> comments;
  final ScrollController scroll;
  final bool loading;
  final bool hasMore;
  final VoidCallback onLoadMore;
  final VoidCallback onClose;

  @override
  State<_CommentsPanel> createState() => _CommentsPanelState();
}

/// newBV's comment surface: every row can be liked, and a comment with
/// replies opens its thread (楼中楼) inline — the preview replies the list API
/// carries first, the full set fetched from the reply endpoint on expand.
class _CommentsPanelState extends State<_CommentsPanel> {
  final Map<int, ({int like, bool liked})> _likeOverrides = {};
  final Map<int, List<CommentItem>> _replies = {};
  final Set<int> _expanded = {};
  final Set<int> _replyLoading = {};

  int _likeOf(CommentItem c) => _likeOverrides[c.rpid]?.like ?? c.like;
  bool _likedOf(CommentItem c) => _likeOverrides[c.rpid]?.liked ?? c.liked;

  Future<void> _like(CommentItem comment) async {
    final next = !_likedOf(comment);
    setState(() => _likeOverrides[comment.rpid] = (like: _likeOf(comment) + (next ? 1 : -1), liked: next));
    try {
      await BilibiliUgcApi.instance.likeComment(oid: widget.oid, rpid: comment.rpid, like: next);
    } catch (_) {
      if (mounted) setState(() => _likeOverrides.remove(comment.rpid));
    }
  }

  List<CommentItem> _repliesOf(CommentItem comment) => _replies[comment.rpid] ?? comment.replies;

  Future<void> _toggleReplies(CommentItem comment) async {
    if (!_expanded.remove(comment.rpid)) {
      _expanded.add(comment.rpid);
      if (!_replies.containsKey(comment.rpid) && comment.rcount > comment.replies.length) {
        _replyLoading.add(comment.rpid);
        setState(() {});
        try {
          final replies = await BilibiliUgcApi.instance.getCommentReplies(oid: widget.oid, rpid: comment.rpid);
          if (mounted) setState(() => _replies[comment.rpid] = replies);
        } catch (_) {
          // The preview replies stay on screen when the fetch fails.
        } finally {
          _replyLoading.remove(comment.rpid);
          if (mounted) setState(() {});
        }
        return;
      }
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(24.sp),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20.sp),
            child: Row(
              children: [
                Icon(Icons.comment_outlined, size: 28.sp, color: accent),
                SizedBox(width: 10.sp),
                Expanded(
                  child: Text(
                    i18n('video_comments_title'),
                    style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                TvIconButton(
                  icon: const Icon(Icons.close_rounded),
                  size: TvIconButtonSize.small,
                  isSecondary: true,
                  onTap: widget.onClose,
                ),
              ],
            ),
          ),
          Expanded(
            child: widget.comments.isEmpty && widget.loading
                ? Center(
                    child: SizedBox(
                      width: 40.sp,
                      height: 40.sp,
                      child: CircularProgressIndicator(strokeWidth: 3.sp, color: accent),
                    ),
                  )
                : ListView.builder(
                    controller: widget.scroll,
                    padding: EdgeInsets.only(left: 16.sp, right: 16.sp, bottom: 16.sp),
                    itemCount: widget.comments.length + (widget.hasMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index >= widget.comments.length) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (widget.scroll.hasClients && widget.scroll.position.extentAfter < 300) {
                            widget.onLoadMore();
                          }
                        });
                        return Padding(
                          padding: EdgeInsets.all(14.sp),
                          child: Center(
                            child: widget.loading
                                ? SizedBox(
                                    width: 26.sp,
                                    height: 26.sp,
                                    child: CircularProgressIndicator(strokeWidth: 3.sp, color: accent),
                                  )
                                : const SizedBox.shrink(),
                          ),
                        );
                      }
                      return _CommentTile(
                        comment: widget.comments[index],
                        oid: widget.oid,
                        autofocus: index == 0,
                        like: _likeOf,
                        liked: _likedOf,
                        onLike: () => unawaited(_like(widget.comments[index])),
                        expanded: _expanded.contains(widget.comments[index].rpid),
                        replies: _repliesOf(widget.comments[index]),
                        repliesLoading: _replyLoading.contains(widget.comments[index].rpid),
                        onToggleReplies: () => unawaited(_toggleReplies(widget.comments[index])),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

/// One comment: body OK opens the thread, the like pill is its own focusable.
class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.autofocus,
    required this.comment,
    required this.oid,
    required this.like,
    required this.liked,
    required this.onLike,
    required this.expanded,
    required this.replies,
    required this.repliesLoading,
    required this.onToggleReplies,
  });

  /// The panel opens with the keyboard on the first comment's like pill.
  final bool autofocus;
  final CommentItem comment;
  final int oid;
  final int Function(CommentItem) like;
  final bool Function(CommentItem) liked;
  final VoidCallback onLike;
  final bool expanded;
  final List<CommentItem> replies;
  final bool repliesLoading;
  final VoidCallback onToggleReplies;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final hasThread = comment.rcount > 0;

    return Container(
      margin: EdgeInsets.only(bottom: 8.sp),
      padding: EdgeInsets.all(12.sp),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12.sp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  comment.uname,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w600, color: accent),
                ),
              ),
              TvFocusable(
                autofocus: autofocus,
                onTap: onLike,
                builder: (context, focused, _) => AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  padding: EdgeInsets.symmetric(horizontal: 10.sp, vertical: 4.sp),
                  decoration: BoxDecoration(
                    color: liked(comment)
                        ? accent.withValues(alpha: 0.18)
                        : focused
                        ? Colors.white.withValues(alpha: 0.12)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(10.sp),
                    border: Border.all(color: focused ? accent : Colors.transparent, width: 1.5.sp),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        liked(comment) ? Icons.thumb_up_alt_rounded : Icons.thumb_up_alt_outlined,
                        size: 16.sp,
                        color: liked(comment) ? accent : Colors.white54,
                      ),
                      SizedBox(width: 4.sp),
                      Text(
                        readableCount(like(comment).toString()),
                        style: AppTextStyles.t14.copyWith(
                          fontWeight: FontWeight.w500,
                          color: liked(comment) ? accent : Colors.white54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 6.sp),
          Text(
            comment.content,
            style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w500, color: Colors.white, height: 1.4),
          ),
          if (hasThread) ...[
            SizedBox(height: 6.sp),
            TvFocusable(
              onTap: onToggleReplies,
              builder: (context, focused, _) => Text(
                repliesLoading
                    ? i18n('video_replies_loading')
                    : expanded
                    ? i18n('video_replies_collapse')
                    : i18n('video_replies_expand', args: {'count': '${comment.rcount}'}),
                style: AppTextStyles.t14.copyWith(
                  fontWeight: FontWeight.w500,
                  color: focused ? accent : Colors.white54,
                ),
              ),
            ),
          ],
          if (expanded)
            Padding(
              padding: EdgeInsets.only(left: 18.sp, top: 6.sp),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final reply in replies)
                    Padding(
                      padding: EdgeInsets.only(bottom: 4.sp),
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${reply.uname}: ',
                              style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w600, color: accent),
                            ),
                            TextSpan(
                              text: reply.content,
                              style: AppTextStyles.t14.copyWith(fontWeight: FontWeight.w300, color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
