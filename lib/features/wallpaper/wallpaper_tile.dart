import 'dart:math' as math;

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/wallpaper/wallpaper_image.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/shared/common/utils/color_util.dart';
import 'package:pure_live/shared/theme/index.dart';

/// One grid tile of the wallpaper browser: pictures load a grid-sized copy,
/// live wallpapers show their poster, gradients are painted locally.
class WallpaperTile extends StatelessWidget {
  const WallpaperTile({
    super.key,
    required this.item,
    required this.kind,
    required this.current,
    required this.onSelect,
    this.onFocus,
  });

  final BackgroundItem item;
  final BackgroundKind kind;

  /// Marks the item that backs the background in use right now.
  final bool current;
  final VoidCallback onSelect;

  /// Fired when the d-pad lands on this tile. The grid uses it to pull the next
  /// page as soon as the cursor gets near the end of what is loaded, which is
  /// what actually drives paging on a remote: focus traversal does not always
  /// produce a scroll event near the bottom.
  final VoidCallback? onFocus;

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final radius = BorderRadius.circular(12.sp);

    return DpadFocusable(
      onSelect: onSelect,
      onFocusChange: (focused) {
        if (focused) onFocus?.call();
      },
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
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: theme.cardColor, child: _buildPreview(theme)),
            if (item.bytes != null)
              Positioned(right: 6.sp, bottom: 6.sp, child: WallpaperBadge(text: sizeLabel(item.bytes!))),
            if (kind == BackgroundKind.video)
              Positioned(
                left: 6.sp,
                bottom: 6.sp,
                child: Icon(Icons.play_circle_fill, size: 20.sp, color: Colors.white.withValues(alpha: 0.9)),
              ),
            if (current)
              Positioned(
                right: 6.sp,
                top: 6.sp,
                child: Icon(Icons.check_circle, size: 20.sp, color: theme.focusColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreview(TvThemeData theme) {
    if (kind == BackgroundKind.gradient) {
      return GradientPreview(item: item);
    }
    if (kind == BackgroundKind.video) {
      final poster = item.poster ?? item.file;
      if (poster.isEmpty) return const SizedBox.shrink();
      return WallpaperNetworkImage(
        url: item.thumb ?? poster,
        fallbackUrl: poster,
        memCacheWidth: 480,
        placeholder: ColoredBox(color: theme.cardColor),
        fallback: Center(
          child: Icon(Icons.broken_image_outlined, size: 24.sp, color: theme.secondaryTextColor),
        ),
      );
    }
    if (item.file.isEmpty) return const SizedBox.shrink();
    return WallpaperNetworkImage(
      url: item.thumb ?? item.file,
      fallbackUrl: item.file,
      memCacheWidth: 480,
      placeholder: ColoredBox(color: theme.cardColor),
      fallback: Center(
        child: Icon(Icons.broken_image_outlined, size: 24.sp, color: theme.secondaryTextColor),
      ),
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
///
/// The angle follows the CSS convention the source table uses (0° points up,
/// positive is clockwise), so a 120° gradient runs the same way here as it does
/// on the iTab new-tab page.
class GradientPreview extends StatelessWidget {
  const GradientPreview({super.key, required this.item});

  final BackgroundItem item;

  /// CSS angle → Flutter begin/end alignment pair.
  static (Alignment, Alignment) alignmentsFor(int deg) {
    final double radians = deg * math.pi / 180;
    final double x = math.sin(radians);
    final double y = -math.cos(radians);
    if (x == 0 && y == 0) {
      return (Alignment.bottomCenter, Alignment.topCenter);
    }
    return (Alignment(-x, -y), Alignment(x, y));
  }

  @override
  Widget build(BuildContext context) {
    final stops = item.gradient ?? const <BackgroundGradientStop>[];
    final colors = <Color>[];
    final positions = <double>[];
    for (final stop in stops) {
      colors.add(ColorUtil.hexToColor(stop.color));
      positions.add((stop.pos / 100).clamp(0.0, 1.0));
    }
    if (colors.isEmpty) return const ColoredBox(color: Color(0xFF141E30));
    if (colors.length < 2) return ColoredBox(color: colors.first);

    final (Alignment begin, Alignment end) = alignmentsFor(item.deg);
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: begin,
          end: end,
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
      child: Text(text, style: TextStyle(fontSize: 13.sp, color: Colors.white)),
    );
  }
}
