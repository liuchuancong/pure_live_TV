import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';

/// Arguments for the wallpaper items grid: one catalog source + one of its
/// categories.
class WallpaperItemsArgs {
  final BackgroundSource source;
  final BackgroundCategory category;

  const WallpaperItemsArgs({required this.source, required this.category});
}

/// Arguments for the fullscreen preview.
///
/// Exactly one mode is set: [apiSource] previews a random-image API (the page
/// fetches a fresh picture), [items] walks a catalog shard with prev/next.
class WallpaperPreviewArgs {
  final WallpaperApiSource? apiSource;
  final List<BackgroundItem>? items;

  /// Catalog kind, needed to tell video posters and gradients apart.
  final BackgroundKind? kind;
  final int initialIndex;

  const WallpaperPreviewArgs.api(WallpaperApiSource this.apiSource)
      : items = null,
        kind = null,
        initialIndex = 0;

  const WallpaperPreviewArgs.catalog({
    required List<BackgroundItem> this.items,
    required BackgroundKind this.kind,
    this.initialIndex = 0,
  }) : apiSource = null;

  bool get isApiMode => apiSource != null;
}
