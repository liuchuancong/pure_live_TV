import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/features/wallpaper/wallpaper_tile.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/services/background_config/remote/background_repository.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The thumbnail grid of one category.
///
/// Tapping any tile — picture, live wallpaper or gradient — opens the
/// fullscreen preview, which is the only place a background is applied. One
/// code path for "choose", one for "commit", and the grid stays a pure browser.
class WallpaperItemsPage extends ConsumerWidget {
  const WallpaperItemsPage({super.key, required this.sourceId, this.categoryId});

  final String sourceId;

  /// Null falls back to the source's first visible category.
  final String? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The source tree is compiled in, so this is synchronous: the grid knows its
    // title and which category to ask for before the first frame.
    final catalog = ref.watch(backgroundCatalogProvider);
    final bgState = ref.watch(backgroundControllerProvider);
    final languageCode = Localizations.localeOf(context).languageCode;

    final source = catalog.sourceById(sourceId);
    final category = source == null ? null : _pickCategory(source, categoryId);
    if (source == null || category == null) {
      return TvScaffold(
        title: i18nOr('wallpaper', '壁纸'),
        child: AppStatusView(
          type: AppStatusType.empty,
          subtitle: i18nOr('background_no_category', '该来源暂无数据'),
        ),
      );
    }

    final key = (sourceId: source.id, categoryId: category.id);
    final shardAsync = ref.watch(backgroundShardProvider(key));
    final String? currentFile = source.kind == BackgroundKind.video
        ? bgState.networkVideoUrl
        : bgState.networkImageUrl;

    return TvScaffold(
      title: category.localizedName(languageCode),
      child: shardAsync.when(
        loading: () => const AppStatusView(type: AppStatusType.loading),
        error: (error, _) => AppStatusView(
          type: AppStatusType.error,
          subtitle: i18nOr('background_load_failed', '壁纸加载失败'),
          onTap: () => ref.invalidate(backgroundShardProvider(key)),
        ),
        data: (shard) {
          final items = shard.items;
          if (items.isEmpty) {
            return AppStatusView(
              type: AppStatusType.empty,
              subtitle: i18nOr('background_no_item', '这个分类还没有资源'),
            );
          }
          return DpadRegion(
            verticalEdge: DpadEdgeBehavior.leave,
            child: GridView.builder(
              // The tiles are cheap (one small webp each), so keeping a couple
              // of screens cached stops the d-pad from outrunning the images on
              // a fast scroll.
              scrollCacheExtent: const ScrollCacheExtent.viewport(2),
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 16.sp),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                mainAxisSpacing: 16.w,
                crossAxisSpacing: 16.w,
                childAspectRatio: 16 / 9,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return WallpaperTile(
                  item: item,
                  kind: source.kind,
                  current: _isCurrent(currentFile, item.file),
                  onSelect: () => context.push(
                    AppRoutes.kWallpaperPreview,
                    extra: WallpaperPreviewArgs.catalog(
                      items: items,
                      kind: source.kind,
                      title: category.localizedName(languageCode),
                      initialIndex: index,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
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

  /// Whether the given entry backs the background in use right now.
  ///
  /// Entries are absolute URLs and gradients use a synthetic key, so the check
  /// is a plain equality or suffix test against the stored value.
  static bool _isCurrent(String? currentUrl, String file) {
    if (currentUrl == null || currentUrl.isEmpty || file.isEmpty) return false;
    return currentUrl == file || currentUrl.endsWith(file);
  }
}
