import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/wallpaper/wallpaper_items_page.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';

/// Entry page for one wallpaper-library source.
///
/// Categorized sources show a vertical category list — a plain drill-down
/// list, not the old 19-tab bar whose every switch rebuilt the whole page.
/// Single-category sources jump straight to the grid.
class WallpaperGalleryPage extends ConsumerWidget {
  const WallpaperGalleryPage({super.key, required this.source});

  final BackgroundSource source;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final categories = source.visibleCategories;

    if (!source.categorized && categories.isNotEmpty) {
      return WallpaperItemsPage(source: source, category: categories.first);
    }

    return TvScaffold(
      title: source.localizedName(languageCode),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return TvSettingsMenuTile<void>(
            title: category.localizedName(languageCode),
            subtitle: i18nOr('wallpaper_category_count', '{count} items', args: {'count': '${category.count}'}),
            onTap: () => context.push(
              AppRoutes.kWallpaperItems,
              extra: WallpaperItemsArgs(source: source, category: category),
            ),
          );
        },
      ),
    );
  }
}
