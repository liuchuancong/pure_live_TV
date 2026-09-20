import 'dart:async';

import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/features/wallpaper/wallpaper_image.dart';
import 'package:pure_live/features/wallpaper/wallpaper_tile.dart';
import 'package:pure_live/features/wallpaper/wallpaper_sequence.dart';
import 'package:pure_live/services/background_config/local/wallpaper_video.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/background_config/background_config_model.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';

/// Full-screen wallpaper viewer, a route of its own with no permanent buttons.
///
/// Up/Down moves through the sequence, OK applies the item as the app
/// background, Back returns to the preview page.
class WallpaperImmersivePage extends ConsumerStatefulWidget {
  const WallpaperImmersivePage({super.key, required this.args});

  final WallpaperPreviewArgs args;

  @override
  ConsumerState<WallpaperImmersivePage> createState() => _WallpaperImmersivePageState();
}

class _WallpaperImmersivePageState extends ConsumerState<WallpaperImmersivePage> {
  late final WallpaperSequence _sequence;
  late final FocusNode _focusNode = FocusNode(debugLabel: 'wallpaper-immersive');

  bool _applying = false;
  bool _hintVisible = true;
  Timer? _hintTimer;

  /// Short OK applies the app background; holding it applies the system one.
  Timer? _okHoldTimer;
  bool _okLongPressed = false;

  /// 返回只允许生效一次（PopScope 回调在预测性返回等场景会被重复调用，
  /// 弹两次会把预览页一起弹掉，用户就直接退到壁纸列表了）。
  bool _popping = false;

  /// Below this a press is a plain confirm, so remote jitter cannot set the
  /// system wallpaper.
  static const Duration _longPressThreshold = Duration(milliseconds: 1200);

  /// Online video plays here; the preview page pauses its own player while
  /// this route is on top.
  Player? _videoPlayer;
  VideoController? _videoController;
  String? _openedUrl;

  @override
  void initState() {
    super.initState();
    _sequence = WallpaperSequence(
      args: widget.args,
      ref: ref,
      initialIndex: widget.args.initialIndex,
    );
    if (widget.args.isApiMode) {
      unawaited(_fetchApi(initial: true));
    }
    if (_sequence.isVideo) {
      _createVideoPlayer();
    }
    // Fades out after 4s instead of sitting in the middle of the screen.
    _hintTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _hintVisible = false);
    });
  }

  @override
  void dispose() {
    _hintTimer?.cancel();
    _okHoldTimer?.cancel();
    _focusNode.dispose();
    _videoPlayer?.dispose();
    super.dispose();
  }

  void _createVideoPlayer() {
    final player = Player();
    _videoPlayer = player;
    _videoController = VideoController(player, configuration: wallpaperVideoControllerConfiguration());
    player.setVolume(100);
  }

  Future<void> _openVideo(String url) async {
    final player = _videoPlayer;
    if (player == null || url.isEmpty) return;
    try {
      await player.open(Media(url), play: true);
    } catch (_) {
      if (mounted) ToastUtil.show(i18nOr('wallpaper_video_failed', 'Playback failed'));
    }
  }

  Future<void> _fetchApi({bool initial = false}) async {
    // Nothing built yet on the initial load: apiLoading applies on the first
    // frame without a setState.
    if (!initial) setState(() {});
    final ok = await _sequence.fetchApiImage();
    if (!mounted) return;
    setState(() {});
    if (!ok && !initial) {
      ToastUtil.show(i18nOr('wallpaper_fetch_failed', 'Failed to fetch an image, try again'));
    }
  }

  Future<void> _apply() async {
    if (_applying) return;
    setState(() => _applying = true);
    try {
      await _sequence.applyCurrent();
      if (mounted) ToastUtil.show(i18nOr('wallpaper_set_done', 'Background updated'));
    } catch (error) {
      if (mounted) {
        ToastUtil.show(i18nOr('background_apply_failed', 'Failed to apply: {msg}', args: {'msg': '$error'}));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  /// Long OK writes the current item as the system wallpaper (video goes
  /// through the live-wallpaper confirm screen).
  Future<void> _setSystemWallpaper() async {
    if (_applying) return;
    _hintTimer?.cancel();
    setState(() {
      _applying = true;
      _hintVisible = true;
    });
    try {
      final bool needsConfirmation = await _sequence.applyToSystemWallpaper();
      if (!mounted) return;
      ToastUtil.show(
        needsConfirmation
            ? i18nOr('wallpaper_live_confirm_hint', 'Confirm in the system dialog to apply the live wallpaper')
            : i18nOr('wallpaper_system_set_done', 'System wallpaper updated'),
      );
    } on StateError catch (error) {
      if (mounted) {
        ToastUtil.show(
          i18nOr('wallpaper_system_set_failed_reason', 'Failed to set the system wallpaper: {msg}', args: {'msg': error.message}),
        );
      }
    } catch (error) {
      if (mounted) {
        ToastUtil.show(
          i18nOr('wallpaper_system_set_failed_reason', 'Failed to set the system wallpaper: {msg}', args: {'msg': '$error'}),
        );
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  /// Left/Right stay with focus traversal (this page has one node, so they do
  /// nothing) rather than reaching anything else.
  static bool _isConfirmKey(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.gameButtonA ||
      key == LogicalKeyboardKey.space;

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    final key = event.logicalKey;

    // OK: start the timer on press and dispatch on release, before the early
    // returns below, since a KeyUpEvent is neither of their cases.
    if (_isConfirmKey(key)) {
      if (event is KeyDownEvent) {
        _okLongPressed = false;
        _okHoldTimer?.cancel();
        _okHoldTimer = Timer(_longPressThreshold, () {
          _okLongPressed = true;
          unawaited(_setSystemWallpaper());
        });
        return KeyEventResult.handled;
      }
      if (event is KeyRepeatEvent) return KeyEventResult.handled;
      if (event is KeyUpEvent) {
        _okHoldTimer?.cancel();
        _okHoldTimer = null;
        if (!_okLongPressed) unawaited(_apply());
        _okLongPressed = false;
        return KeyEventResult.handled;
      }
      return KeyEventResult.ignored;
    }

    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;

    if (key == LogicalKeyboardKey.arrowUp) {
      unawaited(_step(forward: false));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      unawaited(_step(forward: true));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowRight) {
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _step({required bool forward}) async {
    if (widget.args.isApiMode) {
      await _fetchApi();
      return;
    }
    if (forward) {
      await _sequence.next();
    } else {
      _sequence.previous();
    }
    if (!mounted) return;
    setState(() {});
  }

  /// Returns to the preview page, carrying the final position back.
  ///
  /// Idempotent: the remote's back key can arrive through both the key event
  /// and the system pop, and popping twice would drop the preview as well.
  void _pop() {
    if (_popping) return;
    _popping = true;
    Navigator.of(context).pop(_sequence.index);
  }

  @override
  Widget build(BuildContext context) {
    final bgState = ref.watch(backgroundControllerProvider);
    final items = _sequence.visibleItems;
    if (_sequence.consumePendingAdvance(items)) {
      // Steps forward once the requested page arrives, as the preview does.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
    final item = _sequence.itemAt(items);

    if (_sequence.isVideo && item.file.isNotEmpty && item.file != _openedUrl) {
      _openedUrl = item.file;
      final String url = item.file;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_openVideo(url));
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Focus(
          focusNode: _focusNode,
          autofocus: true,
          onKeyEvent: _handleKey,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _buildViewer(bgState, item),
              if (bgState.maskOpacity > 0) IgnorePointer(child: _buildMask(bgState)),
              // First-entry hint; it disappears on its own.
              AnimatedOpacity(
                opacity: _hintVisible ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      margin: EdgeInsets.only(bottom: 48.sp),
                      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 14.sp),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.65),
                        borderRadius: BorderRadius.circular(28.sp),
                      ),
                      child: Text(
                        i18nOr(
                          'wallpaper_immersive_hint_long',
                          '↑↓ 切换 · OK 设为壁纸 · 长按 OK 设为系统壁纸 · 返回退出',
                        ),
                        style: TextStyle(fontSize: 18.sp, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
              // Spinner while applying; pinned to the middle of the screen.
              if (_applying || (widget.args.isApiMode && _sequence.apiLoading))
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: SizedBox(
                        height: 44,
                        width: 44,
                        child: AppStatusView(type: AppStatusType.loading, isMini: true, iconColor: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildViewer(BackgroundConfigModel bgState, BackgroundItem item) {
    if (widget.args.isApiMode) {
      final bytes = _sequence.apiBytes;
      if (bytes == null) {
        return const ColoredBox(
          color: Colors.black,
          child: Center(
            child: SizedBox(height: 44, width: 44, child: AppStatusView(type: AppStatusType.loading, isMini: true)),
          ),
        );
      }
      return SizedBox.expand(child: Image.memory(bytes, fit: bgState.boxFit, gaplessPlayback: true));
    }

    switch (widget.args.kind!) {
      case BackgroundKind.gradient:
        return GradientPreview(item: item);
      case BackgroundKind.video:
        final controller = _videoController;
        if (controller == null) {
          return WallpaperNetworkImage(
            url: item.poster ?? item.thumb ?? item.file,
            fit: BoxFit.cover,
            placeholder: const ColoredBox(color: Colors.black),
            fallback: const ColoredBox(color: Colors.black),
          );
        }
        return Video(controller: controller, fit: bgState.boxFit, controls: (state) => const SizedBox.shrink());
      case BackgroundKind.image:
        return WallpaperNetworkImage(
          url: item.file,
          fit: bgState.boxFit,
          placeholder: _centeredLoading(),
          fallback: const ColoredBox(color: Colors.black),
        );
    }
  }

  Widget _centeredLoading() {
    return const ColoredBox(
      color: Colors.black,
      child: Center(
        child: SizedBox(height: 44, width: 44, child: AppStatusView(type: AppStatusType.loading, isMini: true)),
      ),
    );
  }

  /// Same rule as the app background layer: light themes wash out, dark
  /// themes darken, so the preview matches the result.
  Widget _buildMask(BackgroundConfigModel bgState) {
    final bool lightSurface = context.tvTheme.backgroundColor.computeLuminance() > 0.5;
    return ColoredBox(
      color: (lightSurface ? Colors.white : Colors.black).withValues(alpha: bgState.maskOpacity),
    );
  }
}
