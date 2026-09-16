import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';

/// Arguments for the wallpaper grid: which catalog source, and (for a
/// categorised source) which of its categories.
///
/// Only ids travel through the route. The page resolves them against
/// `backgroundCatalogProvider`, so a route never captures a stale catalog
/// object and the library keeps working after the catalog is refreshed.
class WallpaperItemsArgs {
  const WallpaperItemsArgs({required this.sourceId, this.categoryId});

  final String sourceId;

  /// Null picks the source's first visible category, which is what the
  /// single-category sources (colors, live wallpapers) need.
  final String? categoryId;
}

/// Arguments for the fullscreen preview.
///
/// Exactly one mode is set: [apiSource] previews a random-image API (the page
/// downloads a fresh picture per request), [items] walks a loaded shard.
class WallpaperPreviewArgs {
  const WallpaperPreviewArgs.api(WallpaperApiSource this.apiSource, {this.title})
    : items = null,
      kind = null,
      initialIndex = 0;

  const WallpaperPreviewArgs.catalog({
    required List<BackgroundItem> this.items,
    required BackgroundKind this.kind,
    this.title,
    this.initialIndex = 0,
  }) : apiSource = null;

  final WallpaperApiSource? apiSource;
  final List<BackgroundItem>? items;

  /// Catalog kind, needed to tell video posters and gradients apart.
  final BackgroundKind? kind;

  /// Header override; the API mode and the category grid both pass one.
  final String? title;
  final int initialIndex;

  bool get isApiMode => apiSource != null;
}
