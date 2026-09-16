import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/services/background_config/background_config_model.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/services/background_config/remote/background_repository.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/common/utils/color_util.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/cache_manager.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/widgets/index.dart';

import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/features/wallpaper/wallpaper_tile.dart';

/// Fill modes cycled by the preview's fill chip, same order as the settings
/// page offers.
const List<BoxFit> _kFitModes = <BoxFit>[
  BoxFit.fill,
  BoxFit.contain,
  BoxFit.cover,
  BoxFit.fitWidth,
  BoxFit.fitHeight,
  BoxFit.none,
  BoxFit.scaleDown,
];

const List<double> _kMaskSteps = <double>[0, 0.2, 0.35, 0.5, 0.7];

/// Fullscreen wallpaper preview.
///
/// One mode per route arguments: a random-image API (the page downloads a
/// fresh picture and re-fetches on demand) or a library shard walked with
/// prev/next. Left/Right always switch — the image-area Focus consumes them so
/// the dpad root never turns them into traversal; Down drops into the control
/// bar, whose chips are ordinary dpad targets. The remote's back key exits,
/// and [TvFocusRestorer] hands focus back to the tile/row that opened this
/// page.
class WallpaperPreviewPage extends ConsumerStatefulWidget {
  const WallpaperPreviewPage({super.key, required this.args});

  final WallpaperPreviewArgs args;

  @override
  ConsumerState<WallpaperPreviewPage> createState() => _WallpaperPreviewPageState();
}

class _WallpaperPreviewPageState extends ConsumerState<WallpaperPreviewPage> {
  /// Catalog mode: position in the shard.
  late int _index;

  /// API mode: the downloaded picture and its fetch state.
  Uint8List? _apiBytes;
  bool _apiLoading = false;
  bool _applying = false;

  @override
  void initState() {
    super.initState();
    _index = widget.args.initialIndex;
    if (widget.args.isApiMode) {
      _fetchApiImage();
    }
  }

  BackgroundKind? get _kind => widget.args.kind;

  BackgroundItem get _item => widget.args.items![_index];

  Future<void> _fetchApiImage() async {
    setState(() => _apiLoading = true);
    try {
      final bytes = await fetchRandomImage(widget.args.apiSource!);
      if (!mounted) return;
      if (bytes == null) {
        ToastUtil.show(i18nOr('wallpaper_fetch_failed', 'Failed to fetch an image'));
      } else {
        setState(() => _apiBytes = bytes);
      }
    } catch (_) {
      if (mounted) ToastUtil.show(i18nOr('wallpaper_fetch_failed', 'Failed to fetch an image'));
    } finally {
      if (mounted) setState(() => _apiLoading = false);
    }
  }

  void _next() {
    if (widget.args.isApiMode) {
      if (!_apiLoading) _fetchApiImage();
      return;
    }
    setState(() => _index = (_index + 1) % widget.args.items!.length);
  }

  void _prev() {
    if (widget.args.isApiMode) return;
    setState(() => _index = (_index - 1 + widget.args.items!.length) % widget.args.items!.length);
  }

  Future<void> _apply() async {
    if (_applying) return;
    final bg = SettingsService.to.bg;
    setState(() => _applying = true);
    try {
      if (widget.args.isApiMode) {
        final bytes = _apiBytes;
        if (bytes == null) return;
        bg.setNetworkImageBytes(bytes);
      } else {
        switch (_kind!) {
          case BackgroundKind.image:
            bg.setNetworkImage(await BackgroundRepository.instance.urlOf(_item.file));
          case BackgroundKind.video:
            bg.setNetworkVideo(await BackgroundRepository.instance.urlOf(_item.file));
          case BackgroundKind.gradient:
            final colors = <Color>[
              for (final stop in _item.gradient ?? const <BackgroundGradientStop>[]) ColorUtil.hexToColor(stop.color),
            ];
            if (colors.length < 2) {
              ToastUtil.show(i18nOr('background_invalid_gradient', 'Gradient data is incomplete'));
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

  @override
  Widget build(BuildContext context) {
    final bgState = ref.watch(backgroundControllerProvider);

    return TvScaffold(
      showAppBar: false,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // The image area owns Left/Right. It is a focusable leaf: dpad Up/Down
          // from here moves into the control bar below, while Left/Right never
          // become traversal.
          Focus(
            autofocus: true,
            onKeyEvent: _handleImageKeyEvent,
            child: _buildViewer(bgState),
          ),
          // Top scrim + title.
          Positioned(
            top: 0,
            left: 0,
            right: 0,
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
                      _title(),
                      style: TextStyle(fontSize: 18.sp, color: Colors.white, fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!widget.args.isApiMode && widget.args.items!.length > 1)
                    Text(
                      '${_index + 1}/${widget.args.items!.length}',
                      style: TextStyle(fontSize: 15.sp, color: Colors.white70),
                    ),
                ],
              ),
            ),
          ),
          // Control bar.
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24.sp, 40.sp, 24.sp, 20.sp),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      i18nOr('wallpaper_preview_hint', '←→ switch · ↓ actions · back to exit'),
                      style: TextStyle(fontSize: 13.sp, color: Colors.white70),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.args.isApiMode)
                    _PreviewChip(
                      icon: Icons.refresh_rounded,
                      label: i18nOr('wallpaper_change_image', 'New image'),
                      busy: _apiLoading,
                      onSelect: _next,
                    )
                  else ...[
                    _PreviewChip(
                      icon: Icons.chevron_left_rounded,
                      label: i18nOr('wallpaper_prev', 'Prev'),
                      onSelect: _prev,
                    ),
                    SizedBox(width: 10.sp),
                    _PreviewChip(
                      icon: Icons.chevron_right_rounded,
                      label: i18nOr('wallpaper_next', 'Next'),
                      onSelect: _next,
                    ),
                  ],
                  SizedBox(width: 10.sp),
                  _PreviewChip(
                    icon: Icons.aspect_ratio_outlined,
                    label: _fitLabel(bgState.boxFit),
                    onSelect: _cycleFit,
                  ),
                  SizedBox(width: 10.sp),
                  _PreviewChip(
                    icon: Icons.brightness_6_outlined,
                    label: '${(bgState.maskOpacity * 100).round()}%',
                    onSelect: _cycleMask,
                  ),
                  SizedBox(width: 10.sp),
                  _PreviewChip(
                    icon: Icons.check_rounded,
                    label: i18nOr('wallpaper_set_background', 'Set as background'),
                    busy: _applying,
                    highlight: true,
                    onSelect: _apply,
                  ),
                ],
              ),
            ),
          ),
          if (_apiLoading)
            const Center(
              child: SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  KeyEventResult _handleImageKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
      _prev();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
      _next();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _title() {
    if (widget.args.isApiMode) {
      return '${widget.args.apiSource!.name} · ${i18nOr('wallpaper_random_image', 'Random image')}';
    }
    final name = _item.name ?? '';
    return name.isNotEmpty ? name : '${i18nOr('wallpaper', 'Wallpaper')} ${_index + 1}';
  }

  Widget _buildViewer(BackgroundConfigModel bgState) {
    if (widget.args.isApiMode) {
      final bytes = _apiBytes;
      if (bytes == null) {
        return ColoredBox(color: Colors.black.withValues(alpha: 0.8));
      }
      return Image.memory(bytes, fit: bgState.boxFit, gaplessPlayback: true);
    }

    switch (_kind!) {
      case BackgroundKind.gradient:
        return GradientPreview(item: _item);
      case BackgroundKind.video:
        return Stack(
          fit: StackFit.expand,
          children: [
            _NetworkViewer(url: _item.poster ?? _item.file, fit: BoxFit.cover),
            Center(
              child: Icon(Icons.play_circle_outline_rounded, size: 64.sp, color: Colors.white70),
            ),
          ],
        );
      case BackgroundKind.image:
        return _NetworkViewer(url: _item.file, fit: bgState.boxFit);
    }
  }

  void _cycleFit() {
    final bg = SettingsService.to.bg;
    final current = _kFitModes.indexOf(SettingsService.to.bgState.boxFit);
    final next = _kFitModes[(current + 1) % _kFitModes.length];
    bg.setBoxFit(next);
  }

  void _cycleMask() {
    final bg = SettingsService.to.bg;
    final state = SettingsService.to.bgState;
    var best = 0;
    var bestDelta = double.infinity;
    for (var i = 0; i < _kMaskSteps.length; i++) {
      final delta = (_kMaskSteps[i] - state.maskOpacity).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        best = i;
      }
    }
    bg.setMaskOpacity(_kMaskSteps[(best + 1) % _kMaskSteps.length]);
  }
}

/// Full-size preview image, resolved through the mirror each time the item
/// changes.
class _NetworkViewer extends StatefulWidget {
  const _NetworkViewer({required this.url, required this.fit});

  final String url;
  final BoxFit fit;

  @override
  State<_NetworkViewer> createState() => _NetworkViewerState();
}

class _NetworkViewerState extends State<_NetworkViewer> {
  String? _resolved;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolve();
  }

  @override
  void didUpdateWidget(covariant _NetworkViewer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _resolved = null;
      _failed = false;
      _resolve();
    }
  }

  Future<void> _resolve() async {
    try {
      final url = await BackgroundRepository.instance.urlOf(widget.url);
      if (!mounted) return;
      setState(() => _resolved = url);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _resolved;
    if (url == null || _failed) {
      return ColoredBox(color: Colors.black.withValues(alpha: 0.8));
    }
    return CachedNetworkImage(
      imageUrl: url,
      cacheManager: CustomImageCacheManager.instance,
      fit: widget.fit,
      memCacheWidth: 1920,
      fadeInDuration: const Duration(milliseconds: 150),
      placeholder: (context, _) => ColoredBox(color: Colors.black.withValues(alpha: 0.8)),
      errorWidget: (context, _, _) => ColoredBox(color: Colors.black.withValues(alpha: 0.8)),
    );
  }
}

String _fitLabel(BoxFit fit) => switch (fit) {
  BoxFit.fill => i18nOr('wallpaper_fit_fill', 'Stretch'),
  BoxFit.contain => i18nOr('wallpaper_fit_contain', 'Fit'),
  BoxFit.cover => i18nOr('wallpaper_fit_cover', 'Cover'),
  BoxFit.fitWidth => i18nOr('wallpaper_fit_fit_width', 'Fit width'),
  BoxFit.fitHeight => i18nOr('wallpaper_fit_fit_height', 'Fit height'),
  BoxFit.none => i18nOr('wallpaper_fit_none', 'Original'),
  BoxFit.scaleDown => i18nOr('wallpaper_fit_scale_down', 'Scale down'),
};

/// Focusable button in the preview control bar.
class _PreviewChip extends StatelessWidget {
  const _PreviewChip({
    required this.icon,
    required this.label,
    required this.onSelect,
    this.busy = false,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onSelect;
  final bool busy;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final radius = BorderRadius.circular(20.sp);
    final Color fill = highlight ? theme.focusColor : theme.cardColor;
    final Color fg = highlight ? theme.focusedCardColor : theme.primaryTextColor;

    return DpadFocusable(
      onSelect: onSelect,
      effects: <DpadEffect>[
        DpadScaleEffect(scale: 1.05, duration: const Duration(milliseconds: 100)),
        DpadBorderEffect(color: theme.focusColor, width: 2, borderRadius: radius, duration: const Duration(milliseconds: 100)),
      ],
      child: Container(
        height: 38.sp,
        padding: EdgeInsets.symmetric(horizontal: 16.sp),
        alignment: Alignment.center,
        decoration: BoxDecoration(color: fill, borderRadius: radius),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (busy)
              SizedBox(
                width: 16.sp,
                height: 16.sp,
                child: const CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            else
              Icon(icon, size: 17.sp, color: fg),
            SizedBox(width: 6.sp),
            Text(label, style: TextStyle(fontSize: 14.sp, color: fg)),
          ],
        ),
      ),
    );
  }
}
