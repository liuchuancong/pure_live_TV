import 'dart:async';
import 'dart:io' show Platform;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/wallpaper/system_wallpaper.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/pagination/paging_core.dart';
import 'package:pure_live/shared/common/utils/color_util.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/features/wallpaper/wallpaper_tile.dart';
import 'package:pure_live/features/wallpaper/wallpaper_image.dart';
import 'package:pure_live/features/wallpaper/wallpaper_paging.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/pagination/models/paging_param.dart';
import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';
import 'package:pure_live/features/wallpaper/wallpaper_display_options.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/background_config/local/wallpaper_video.dart';
import 'package:pure_live/services/background_config/background_config_model.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';

/// What one button in the preview's action bar does.
enum _PreviewActionKind { prev, next, fresh, fit, mask, apply, playPause, immersive, systemWallpaper }

/// One entry of the preview's action bar.
class _PreviewAction {
  const _PreviewAction({required this.kind, required this.icon, required this.label, this.busy = false});

  final _PreviewActionKind kind;
  final IconData icon;
  final String label;
  final bool busy;
}

/// Fullscreen preview of exactly one wallpaper.
///
/// The bottom bar is a normal D-pad-navigable row: every button is its own
/// focus node, ←/→ move between them, OK activates the focused one, and the
/// page itself never touches the focus tree. That means popping this route
/// leaves the focus restoration to the framework — the previous page gets
/// its focus back without any manual bookkeeping.
class WallpaperPreviewPage extends ConsumerStatefulWidget {
  const WallpaperPreviewPage({super.key, required this.args});

  final WallpaperPreviewArgs args;

  @override
  ConsumerState<WallpaperPreviewPage> createState() => _WallpaperPreviewPageState();
}

class _WallpaperPreviewPageState extends ConsumerState<WallpaperPreviewPage> {
  /// Catalog mode: position in the paged list.
  int _index = 0;

  /// API mode: the downloaded picture and its fetch state.
  Uint8List? _apiBytes;
  bool _apiLoading = false;
  bool _applying = false;
  bool _settingSystem = false;

  /// Immersive mode: all chrome hidden; ↑/↓ switch entries, OK applies the
  /// entry as the background, back returns to the button bar.
  bool _immersive = false;
  late final FocusNode _immersiveNode = FocusNode(debugLabel: 'wallpaper-immersive', skipTraversal: true);

  /// Set when the user asked for the next entry while the next page was still
  /// being fetched; the advance happens as soon as the list grows.
  bool _waitingForPage = false;

  /// The paging parameters in force.
  PagingParam<BackgroundItem>? _param;

  /// Live-wallpaper playback. The player exists only for the video kind and is
  /// disposed with the page.
  Player? _videoPlayer;
  VideoController? _videoController;
  StreamSubscription<bool>? _playingSubscription;
  bool _videoPlaying = false;

  /// Playback level for the preview's own player.
  static const double _volume = 100;
  String? _openedVideoUrl;

  bool get _isVideo => !widget.args.isApiMode && widget.args.kind == BackgroundKind.video;

  @override
  void initState() {
    super.initState();
    _index = widget.args.initialIndex;
    if (widget.args.isApiMode) {
      _fetchApiImage();
    }
    if (_isVideo) {
      _createVideoPlayer();
    }
  }

  @override
  void dispose() {
    _immersiveNode.dispose();
    _playingSubscription?.cancel();
    _videoPlayer?.dispose();
    super.dispose();
  }

  void _createVideoPlayer() {
    final player = Player();
    _videoPlayer = player;
    _videoController = VideoController(player, configuration: wallpaperVideoControllerConfiguration());
    player.setVolume(_volume);
    _playingSubscription = player.stream.playing.listen((playing) {
      if (mounted) setState(() => _videoPlaying = playing);
    });
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

  Future<void> _togglePlay() async {
    final player = _videoPlayer;
    if (player == null) return;
    if (_videoPlaying) {
      await player.pause();
    } else {
      await player.play();
    }
  }

  static const BackgroundItem _emptyItem = BackgroundItem(file: '');

  /// Android only, and only for things that are actually pictures: catalog
  /// images and downloaded random-API images.
  bool get _canSetSystemWallpaper {
    if (!Platform.isAndroid) return false;
    if (widget.args.isApiMode) return _apiBytes != null;
    return widget.args.kind == BackgroundKind.image;
  }

  BackgroundItem _itemAt(List<BackgroundItem> items) {
    if (items.isEmpty) return _emptyItem;
    return items[_index.clamp(0, items.length - 1)];
  }

  Future<void> _fetchApiImage() async {
    setState(() => _apiLoading = true);
    var failed = false;
    try {
      final bytes = await fetchRandomImage(widget.args.apiSource!);
      if (!mounted) return;
      if (bytes == null) {
        failed = true;
      } else {
        setState(() => _apiBytes = bytes);
      }
    } catch (_) {
      failed = true;
    } finally {
      if (mounted) {
        setState(() => _apiLoading = false);
        if (failed && _apiBytes != null) {
          ToastUtil.show(i18nOr('wallpaper_fetch_failed', 'Failed to fetch an image, try again'));
        }
      }
    }
  }

  void _prefetch(List<BackgroundItem> items, {bool force = false}) {
    final param = _param;
    if (param == null) return;
    final state = ref.read(pagingCoreProvider(param));
    if (!state.canLoadMore || state.controllerState.loading) return;
    if (!force && _index < items.length - 3) return;
    ref.read(pagingCoreProvider(param).notifier).loadNextPage();
  }

  void _next(List<BackgroundItem> items) {
    if (widget.args.isApiMode) {
      if (!_apiLoading) _fetchApiImage();
      return;
    }
    if (items.length < 2) return;

    final int next = _index + 1;
    if (next < items.length) {
      setState(() => _index = next);
      _prefetch(items);
      return;
    }

    final param = _param;
    if (param != null && ref.read(pagingCoreProvider(param)).canLoadMore) {
      _waitingForPage = true;
      _prefetch(items, force: true);
      return;
    }
    setState(() => _index = 0);
  }

  void _prev(List<BackgroundItem> items) {
    if (widget.args.isApiMode) {
      _next(items);
      return;
    }
    if (items.length < 2) return;
    setState(() => _index = _index <= 0 ? items.length - 1 : _index - 1);
  }

  Future<void> _apply(BackgroundItem item) async {
    if (_applying) return;
    final bg = SettingsService.to.bg;
    setState(() => _applying = true);
    try {
      if (widget.args.isApiMode) {
        final bytes = _apiBytes;
        if (bytes == null) return;
        bg.setNetworkImageBytes(bytes);
      } else {
        switch (widget.args.kind!) {
          case BackgroundKind.image:
            bg.setNetworkImage(item.file);
          case BackgroundKind.video:
            await _applyVideo(item);
          case BackgroundKind.gradient:
            final colors = <Color>[
              for (final stop in item.gradient ?? const <BackgroundGradientStop>[]) ColorUtil.hexToColor(stop.color),
            ];
            if (colors.length < 2) {
              ToastUtil.show(i18nOr('background_invalid_gradient', '这个渐变数据不完整'));
              return;
            }
            bg.setGradient(colors);
        }
      }
      if (mounted) ToastUtil.show(i18nOr('wallpaper_set_done', 'Background updated'));
    } catch (error) {
      if (mounted) {
        ToastUtil.show(i18nOr('background_apply_failed', 'Failed to apply: {msg}', args: {'msg': '$error'}));
      }
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  /// Writes the current picture to the Android launcher wallpaper. Catalog
  /// images are downloaded first; API pictures already hold their bytes.
  Future<void> _setSystemWallpaper(List<BackgroundItem> items) async {
    if (_settingSystem) return;
    setState(() => _settingSystem = true);
    try {
      Uint8List? bytes;
      if (widget.args.isApiMode) {
        bytes = _apiBytes;
      } else {
        // Catalog items carry absolute URLs (see WallpaperNetworkImage).
        final url = _itemAt(items).file;
        final response = await Dio(
          BaseOptions(connectTimeout: const Duration(seconds: 20), receiveTimeout: const Duration(minutes: 5)),
        ).get<List<int>>(url, options: Options(responseType: ResponseType.bytes));
        bytes = response.data == null ? null : Uint8List.fromList(response.data!);
      }
      if (bytes == null) throw StateError('no image bytes');
      final ok = await SystemWallpaper.setImage(bytes);
      if (!mounted) return;
      ToastUtil.show(
        ok ? i18nOr('wallpaper_system_set_done', 'System wallpaper updated') : i18nOr('wallpaper_system_set_failed', 'Failed to set the system wallpaper'),
      );
    } catch (_) {
      if (mounted) ToastUtil.show(i18nOr('wallpaper_system_set_failed', 'Failed to set the system wallpaper'));
    } finally {
      if (mounted) setState(() => _settingSystem = false);
    }
  }

  Future<void> _applyVideo(BackgroundItem item) async {
    final bg = SettingsService.to.bg;
    try {
      final String path = await WallpaperVideoStore.download(item.file);
      bg.setLocalVideo(path);
    } catch (_) {
      bg.setNetworkVideo(item.file);
      if (mounted) {
        ToastUtil.show(i18nOr('wallpaper_video_download_failed', '视频下载失败，已改用在线播放'));
      }
    }
  }

  void _cycleFit() {
    final current = kWallpaperFitModes.indexOf(SettingsService.to.bgState.boxFit);
    SettingsService.to.bg.setBoxFit(kWallpaperFitModes[(current + 1) % kWallpaperFitModes.length]);
  }

  void _cycleMask() {
    final current = wallpaperMaskIndex(SettingsService.to.bgState.maskOpacity);
    SettingsService.to.bg.setMaskOpacity(kWallpaperMaskSteps[(current + 1) % kWallpaperMaskSteps.length]);
  }

  List<_PreviewAction> _buildActions() {
    final bgState = SettingsService.to.bgState;
    return <_PreviewAction>[
      if (widget.args.isApiMode)
        _PreviewAction(
          kind: _PreviewActionKind.fresh,
          icon: Icons.refresh_rounded,
          label: i18nOr('wallpaper_change_image', 'New image'),
          busy: _apiLoading,
        )
      else if (_isVideo) ...[
        _PreviewAction(
          kind: _PreviewActionKind.playPause,
          icon: _videoPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          label: _videoPlaying ? i18nOr('wallpaper_pause', 'Pause') : i18nOr('wallpaper_play', 'Play'),
        ),
        _PreviewAction(
          kind: _PreviewActionKind.prev,
          icon: Icons.chevron_left_rounded,
          label: i18nOr('wallpaper_prev', 'Prev'),
        ),
        _PreviewAction(
          kind: _PreviewActionKind.next,
          icon: Icons.chevron_right_rounded,
          label: i18nOr('wallpaper_next', 'Next'),
        ),
      ] else ...[
        _PreviewAction(
          kind: _PreviewActionKind.prev,
          icon: Icons.chevron_left_rounded,
          label: i18nOr('wallpaper_prev', 'Prev'),
        ),
        _PreviewAction(
          kind: _PreviewActionKind.next,
          icon: Icons.chevron_right_rounded,
          label: i18nOr('wallpaper_next', 'Next'),
        ),
      ],
      _PreviewAction(
        kind: _PreviewActionKind.fit,
        icon: Icons.aspect_ratio_outlined,
        label: wallpaperFitLabel(bgState.boxFit),
      ),
      _PreviewAction(
        kind: _PreviewActionKind.mask,
        icon: Icons.brightness_6_outlined,
        label: wallpaperMaskLabel(bgState.maskOpacity),
      ),
      _PreviewAction(
        kind: _PreviewActionKind.apply,
        icon: Icons.check_rounded,
        label: i18nOr('wallpaper_set_background', 'Set as background'),
        busy: _applying,
      ),
      if (_canSetSystemWallpaper)
        _PreviewAction(
          kind: _PreviewActionKind.systemWallpaper,
          icon: Icons.wallpaper_rounded,
          label: i18nOr('wallpaper_set_system', 'Set as system wallpaper'),
          busy: _settingSystem,
        ),
      _PreviewAction(
        kind: _PreviewActionKind.immersive,
        icon: Icons.fullscreen_rounded,
        label: i18nOr('wallpaper_immersive', 'Immersive'),
      ),
    ];
  }

  void _enterImmersive() {
    setState(() => _immersive = true);
    ToastUtil.show(i18nOr('wallpaper_immersive_hint', '↑↓ 切换 · OK 设为壁纸 · 返回退出'));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _immersive) _immersiveNode.requestFocus();
    });
  }

  void _exitImmersive() {
    if (!_immersive) return;
    setState(() => _immersive = false);
  }

  KeyEventResult _handleImmersiveKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    final items = _resolveItems(ref);
    if (key == LogicalKeyboardKey.arrowUp || key == LogicalKeyboardKey.arrowLeft) {
      _prev(items);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown || key == LogicalKeyboardKey.arrowRight) {
      _next(items);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.gameButtonA ||
        key == LogicalKeyboardKey.space) {
      unawaited(_apply(_itemAt(items)));
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.goBack || key == LogicalKeyboardKey.escape) {
      _exitImmersive();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _run(_PreviewAction action, List<BackgroundItem> items) {
    switch (action.kind) {
      case _PreviewActionKind.fresh:
      case _PreviewActionKind.next:
        _next(items);
      case _PreviewActionKind.prev:
        _prev(items);
      case _PreviewActionKind.fit:
        _cycleFit();
      case _PreviewActionKind.mask:
        _cycleMask();
      case _PreviewActionKind.apply:
        _apply(_itemAt(items));
      case _PreviewActionKind.playPause:
        unawaited(_togglePlay());
      case _PreviewActionKind.immersive:
        _enterImmersive();
      case _PreviewActionKind.systemWallpaper:
        unawaited(_setSystemWallpaper(items));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgState = ref.watch(backgroundControllerProvider);
    final List<BackgroundItem> items = _resolveItems(ref);

    if (_waitingForPage && _index + 1 < items.length) {
      _waitingForPage = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _index += 1);
      });
    }

    final BackgroundItem item = _itemAt(items);
    final actions = _buildActions();
    final bool hasPicture = !widget.args.isApiMode || _apiBytes != null;

    if (_isVideo && item.file.isNotEmpty && item.file != _openedVideoUrl) {
      _openedVideoUrl = item.file;
      final String url = item.file;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_openVideo(url));
      });
    }

    // No page-level Focus wrapper in button mode: the bottom bar owns the
    // focusable nodes. In immersive mode this node takes the keyboard — it is
    // only focusable then, so it never interferes with normal traversal.
    return PopScope(
      canPop: !_immersive,
      onPopInvokedWithResult: (didPop, _) {
        // System back exits immersive first instead of leaving the page.
        if (!didPop) _exitImmersive();
      },
      child: TvPageScaffold(
      showAppBar: false,
      child: Focus(
        focusNode: _immersiveNode,
        canRequestFocus: _immersive,
        onKeyEvent: _handleImmersiveKey,
        child: Stack(
        fit: StackFit.expand,
        children: [
          _buildViewer(bgState, item),
          // The mask the app applies over this wallpaper, drawn here too so the
          // mask action shows what it does: before, the button moved a number
          // and nothing on screen changed.
          IgnorePointer(child: _buildMask(bgState)),
          if (widget.args.isApiMode && _apiLoading && hasPicture)
            const Positioned(
              top: 16,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(height: 28, width: 28, child: AppStatusView(type: AppStatusType.loading, isMini: true)),
              ),
            ),
          _chrome(child: _buildTopBar(items, item)),
          _chrome(child: _buildBottomBar(actions, items)),
        ],
      ),
      ),
    ),
    );
  }

  /// Bars stay mounted (their focus nodes survive) but fade out and stop
  /// taking input while immersive.
  Widget _chrome({required Widget child}) {
    return AnimatedOpacity(
      opacity: _immersive ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      child: IgnorePointer(ignoring: _immersive, child: child),
    );
  }

  List<BackgroundItem> _resolveItems(WidgetRef ref) {
    if (widget.args.isApiMode) return const <BackgroundItem>[];
    final catalog = ref.watch(backgroundCatalogProvider);
    final source = catalog.sourceById(widget.args.sourceId!);
    if (source == null) return const <BackgroundItem>[];
    final category = _pickCategory(source, widget.args.categoryId);
    if (category == null) return const <BackgroundItem>[];

    final param = wallpaperPagingParam(source, category);
    _param = param;
    final state = ref.watch(pagingCoreProvider(param));
    if (state.canLoadMore && !state.controllerState.loading && _index >= state.items.length - 3) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _prefetch(state.items);
      });
    }
    return state.items;
  }

  static BackgroundCategory? _pickCategory(BackgroundSource source, String? wanted) {
    final categories = source.visibleCategories;
    if (categories.isEmpty) return null;
    if (wanted == null) return categories.first;
    for (final category in categories) {
      if (category.id == wanted) return category;
    }
    return categories.first;
  }

  /// The readability wash the app puts over the wallpaper, in the preview.
  ///
  /// Same rule as the app-wide layer: a light palette is washed white, a dark
  /// one black, so the preview agrees with what set as background will produce.
  Widget _buildMask(BackgroundConfigModel bgState) {
    if (bgState.maskOpacity <= 0) return const SizedBox.shrink();
    final bool lightSurface = context.tvTheme.backgroundColor.computeLuminance() > 0.5;
    return ColoredBox(
      color: (lightSurface ? Colors.white : Colors.black).withValues(alpha: bgState.maskOpacity),
    );
  }

  Widget _buildViewer(BackgroundConfigModel bgState, BackgroundItem item) {    if (widget.args.isApiMode) {
      final bytes = _apiBytes;
      if (bytes == null) {
        return _apiLoading
            ? const AppStatusView(type: AppStatusType.loading)
            : AppStatusView(
                type: AppStatusType.error,
                subtitle: i18nOr('wallpaper_fetch_failed', 'Failed to fetch an image, try again'),
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
          placeholder: const ColoredBox(color: Colors.black),
          fallback: const ColoredBox(color: Colors.black),
        );
    }
  }

  Widget _buildTopBar(List<BackgroundItem> items, BackgroundItem item) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: Container(
          padding: EdgeInsets.fromLTRB(24.sp, 16.sp, 24.sp, 40.sp),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _title(item),
                  style: TextStyle(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (!widget.args.isApiMode && items.length > 1)
                Text(
                  '${_index + 1}/${items.length}',
                  style: TextStyle(fontSize: 18.sp, color: Colors.white70),
                ),
              if (_isVideo) ...[
                SizedBox(width: 18.sp),
                Icon(Icons.volume_up_rounded, size: 18.sp, color: Colors.white70),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(List<_PreviewAction> actions, List<BackgroundItem> items) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(24.sp, 40.sp, 24.sp, 20.sp),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.72), Colors.transparent],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              i18nOr('wallpaper_preview_hint', '←→ 选择按钮 · OK 确认 · 返回退出'),
              style: TextStyle(fontSize: 16.sp, color: Colors.white70),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 18.sp),
            // The bar is a normal focus scope now. OrderedTraversalPolicy
            // keeps ←/→ following the on-screen order, so adding or removing
            // the playback buttons never breaks navigation.
            FocusTraversalGroup(
              policy: OrderedTraversalPolicy(),
              child: Wrap(
                spacing: 10.sp,
                runSpacing: 10.sp,
                children: [
                  for (int i = 0; i < actions.length; i++)
                    _PreviewActionButton(
                      action: actions[i],
                      autofocus: i == 0,
                      onActivate: () => _run(actions[i], items),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _title(BackgroundItem item) {
    final override = widget.args.title;
    if (override != null && override.isNotEmpty) return override;
    if (widget.args.isApiMode) {
      return '${widget.args.apiSource!.name} · ${i18nOr('wallpaper_random_image', 'Random image')}';
    }
    final name = item.name ?? '';
    return name.isNotEmpty ? name : '${i18nOr('wallpaper', 'Wallpaper')} ${_index + 1}';
  }
}

/// One bottom-bar button.
///
/// A real focus node: it lights up when focused, activates on OK, and lets the
/// framework move the highlight with ←/→. Nothing here talks to the page or
/// manipulates the focus tree, so the route can pop cleanly.
class _PreviewActionButton extends StatefulWidget {
  const _PreviewActionButton({required this.action, required this.onActivate, this.autofocus = false});

  final _PreviewAction action;
  final VoidCallback onActivate;
  final bool autofocus;

  @override
  State<_PreviewActionButton> createState() => _PreviewActionButtonState();
}

class _PreviewActionButtonState extends State<_PreviewActionButton> {
  late final FocusNode _focusNode = FocusNode(debugLabel: 'preview-action');
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    if (mounted) setState(() => _focused = _focusNode.hasFocus);
  }

  KeyEventResult _handleKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA) {
      widget.onActivate();
      return KeyEventResult.handled;
    }
    // Everything else — including the back key — falls through so the route
    // pops normally and the framework restores the previous focus.
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final radius = BorderRadius.circular(26.sp);
    final Color fill = _focused ? theme.focusColor : theme.cardColor;
    final Color foreground = Colors.white;

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onKeyEvent: _handleKey,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            // Mouse click: move the highlight here too, so TV and mouse stay
            // in sync instead of fighting each other.
            _focusNode.requestFocus();
            widget.onActivate();
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOutCubic,
            height: 56.sp,
            padding: EdgeInsets.symmetric(horizontal: 24.sp),
            decoration: BoxDecoration(color: fill, borderRadius: radius),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.action.busy)
                  SizedBox(
                    width: 26.sp,
                    height: 26.sp,
                    child: const AppStatusView(type: AppStatusType.loading, isMini: true, iconColor: Colors.white),
                  )
                else
                  Icon(widget.action.icon, size: 24.sp, color: foreground),
                SizedBox(width: 10.sp),
                Text(
                  widget.action.label,
                  style: TextStyle(fontSize: 18.sp, color: foreground, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
