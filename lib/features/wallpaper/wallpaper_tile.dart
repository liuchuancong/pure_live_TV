import 'package:cached_network_image/cached_network_image.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/common/utils/color_util.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/cache_manager.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/services/background_config/remote/background_repository.dart';

/// One grid tile of the wallpaper browser: images load a scaled-down
/// thumbnail, videos show their poster, gradients are painted locally.
///
/// Kept as its own StatefulWidget so thumbnail resolution state lives and dies
/// with the tile; the grid page never rebuilds when one thumbnail arrives.
class WallpaperTile extends StatefulWidget {
  const WallpaperTile({
    super.key,
    required this.item,
    required this.kind,
    required this.current,
    required this.applying,
    required this.onSelect,
    this.autofocus = false,
  });

  final BackgroundItem item;
  final BackgroundKind kind;
  final bool current;
  final bool applying;
  final VoidCallback onSelect;

  /// Set once when returning from the fullscreen preview so the d-pad lands
  /// back on the tile the user left from.
  final bool autofocus;

  @override
  State<WallpaperTile> createState() => _WallpaperTileState();
}

class _WallpaperTileState extends State<WallpaperTile> {
  String? _thumbUrl;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _resolveThumb();
  }

  @override
  void didUpdateWidget(covariant WallpaperTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.file != widget.item.file) {
      _thumbUrl = null;
      _failed = false;
      _resolveThumb();
    }
  }

  Future<void> _resolveThumb() async {
    // Videos use their poster image, everything else uses the file itself.
    final raw = await BackgroundRepository.instance.urlOf(widget.item.poster ?? widget.item.file);
    if (!mounted) return;
    setState(() => _thumbUrl = raw);
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final radius = BorderRadius.circular(12.sp);

    return DpadFocusable(
      autofocus: widget.autofocus,
      effects: <DpadEffect>[
        DpadScaleEffect(
          scale: 1.04,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
        ),
        DpadGlowEffect(
          color: theme.focusColor,
          blurRadius: 16,
          borderRadius: radius,
          duration: const Duration(milliseconds: 120),
        ),
        DpadBorderEffect(
          color: theme.focusColor,
          width: 3,
          borderRadius: radius,
          duration: const Duration(milliseconds: 120),
        ),
      ],
      onSelect: widget.onSelect,
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(
              color: theme.cardColor,
              child: _buildPreview(theme),
            ),
            if (widget.item.bytes != null)
              Positioned(
                right: 6.sp,
                bottom: 6.sp,
                child: WallpaperBadge(text: sizeLabel(widget.item.bytes!)),
              ),
            if (widget.kind == BackgroundKind.video)
              Positioned(
                left: 6.sp,
                bottom: 6.sp,
                child: Icon(
                  Icons.play_circle_fill,
                  size: 20.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            if (widget.current)
              Positioned(
                right: 6.sp,
                top: 6.sp,
                child: Icon(
                  Icons.check_circle,
                  size: 20.sp,
                  color: theme.focusColor,
                ),
              ),
            if (widget.applying)
              ColoredBox(
                color: Colors.black.withValues(alpha: 0.45),
                child: const Center(
                  child: SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(TvThemeData theme) {
    if (widget.kind == BackgroundKind.gradient) {
      return GradientPreview(item: widget.item);
    }
    final thumb = _thumbUrl;
    if (thumb == null) return const SizedBox.shrink();
    if (_failed) {
      return Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 24.sp,
          color: theme.secondaryTextColor,
        ),
      );
    }
    return CachedNetworkImage(
      imageUrl: BackgroundRepository.thumbnail(thumb),
      cacheManager: CustomImageCacheManager.instance,
      fit: BoxFit.cover,
      memCacheWidth: 480,
      fadeInDuration: const Duration(milliseconds: 120),
      placeholder: (context, _) => ColoredBox(color: theme.cardColor),
      errorWidget: (context, _, _) {
        // Thumbnail service unavailable, fall back to the full-size file.
        return CachedNetworkImage(
          imageUrl: thumb,
          cacheManager: CustomImageCacheManager.instance,
          fit: BoxFit.cover,
          memCacheWidth: 480,
          errorWidget: (context, _, _) {
            if (!_failed) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _failed = true);
              });
            }
            return const SizedBox.shrink();
          },
        );
      },
    );
  }

  static String sizeLabel(int bytes) {
    if (bytes >= 1024 * 1024) {
      return '${(bytes / 1024 / 1024).toStringAsFixed(1)}M';
    }
    return '${(bytes / 1024).round()}K';
  }
}

/// Paints a gradient tile locally; no download involved.
class GradientPreview extends StatelessWidget {
  const GradientPreview({super.key, required this.item});

  final BackgroundItem item;

  @override
  Widget build(BuildContext context) {
    final stops = item.gradient ?? const <BackgroundGradientStop>[];
    final colors = <Color>[];
    final positions = <double>[];
    for (final stop in stops) {
      colors.add(ColorUtil.hexToColor(stop.color));
      positions.add((stop.pos / 100).clamp(0.0, 1.0));
    }
    if (colors.length < 2) {
      return ColoredBox(
        color: colors.isNotEmpty ? colors.first : const Color(0xFF141E30),
      );
    }
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: positions,
        ),
      ),
    );
  }
}

/// Rounded size label drawn over a tile.
class WallpaperBadge extends StatelessWidget {
  const WallpaperBadge({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6.sp),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11.sp, color: Colors.white),
      ),
    );
  }
}
