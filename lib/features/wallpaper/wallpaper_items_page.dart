import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/pagination/paging_core.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/features/wallpaper/wallpaper_tile.dart';
import 'package:pure_live/features/wallpaper/wallpaper_paging.dart';
import 'package:pure_live/shared/pagination/base_paged_tv_view.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/pagination/models/paging_param.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';
import 'package:pure_live/app/router/app_router.dart';

/// The wallpaper grid of one source/category.
///
/// It runs on the app's shared paging component, so the iTab API is paged the
/// same way hot pages its sites: the grid scrolls, the core appends the next
/// page, and the preview keeps walking the very same list. Tapping a tile opens
/// the fullscreen preview, which is the only place a background is applied.
class WallpaperItemsPage extends ConsumerWidget {
  const WallpaperItemsPage({super.key, required this.sourceId, this.categoryId});

  final String sourceId;

  /// Null falls back to the source's first visible category.
  final String? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The source tree is compiled in, so this is synchronous: the grid knows its
    // title and which category to page through before the first frame.
    final catalog = ref.watch(backgroundCatalogProvider);
    final bgState = ref.watch(backgroundControllerProvider);
    final languageCode = Localizations.localeOf(context).languageCode;

    final source = catalog.sourceById(sourceId);
    final category = source == null ? null : _pickCategory(source, categoryId);
    if (source == null || category == null) {
      return TvPageScaffold(
        title: i18nOr('wallpaper', '壁纸'),
        child: AppStatusView(type: AppStatusType.empty, subtitle: i18nOr('background_no_category', '该来源暂无数据')),
      );
    }

    final param = wallpaperPagingParam(source, category);
    final String? currentFile = source.kind == BackgroundKind.video ? bgState.networkVideoUrl : bgState.networkImageUrl;
    final String title = category.localizedName(languageCode);

    return TvPageScaffold(
      title: title,
      // The paged view deliberately installs no region of its own; this one lets
      // the d-pad leave upward so the scaffold can hand focus to the back button.
      child: DpadRegion(
        verticalEdge: DpadEdgeBehavior.leave,
        child: BasePagedTvView<BackgroundItem>(
          key: ValueKey<String>('wallpaper_${source.id}_${category.id}'),
          param: param,
          getNotifier: () => ref.read(pagingCoreProvider(param).notifier),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 16.w,
            crossAxisSpacing: 16.w,
            childAspectRatio: 16 / 9,
          ),
          itemBuilder: (context, item, index) => WallpaperTile(
            item: item,
            kind: source.kind,
            current: _isCurrent(currentFile, item.file),
            onFocus: () => _pageAhead(ref, param, index),
            onSelect: () => WallpaperPreviewRoute(
              WallpaperPreviewArgs.catalog(
                sourceId: source.id,
                categoryId: category.id,
                kind: source.kind,
                title: title,
                initialIndex: index,
              ),
            ).push(context),
          ),
        ),
      ),
    );
  }

  /// Pulls the next page in when the cursor reaches the tail of the loaded list.
  ///
  /// Relying on the scroll listener alone is not enough on a TV: focus
  /// traversal can reach the last built tile without the scroll offset getting
  /// within its threshold, and then the grid looks like it simply ends.
  static void _pageAhead(WidgetRef ref, PagingParam<BackgroundItem> param, int index) {
    final state = ref.read(pagingCoreProvider(param));
    if (!state.canLoadMore || state.controllerState.loading) return;
    if (index < state.items.length - 4) return;
    ref.read(pagingCoreProvider(param).notifier).loadNextPage();
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
  static bool _isCurrent(String? currentUrl, String file) {
    if (currentUrl == null || currentUrl.isEmpty || file.isEmpty) return false;
    return currentUrl == file || currentUrl.endsWith(file);
  }
}
