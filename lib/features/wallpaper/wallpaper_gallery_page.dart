import 'package:flutter/material.dart';
import 'package:pure_live/core/widgets/index.dart';
import 'package:pure_live/core/i18n/locale_helper.dart';
import 'package:pure_live/core/theme/tv_text_scale.dart';
import 'package:pure_live/app/router/app/app_router.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/features/wallpaper/wallpaper_items_page.dart';
import 'package:pure_live/services/background_config/remote/background_catalog.dart';

/// Entry page for one wallpaper-library source.
///
/// A categorised source gets a vertical category list — a plain drill-down,
/// not the old 19-tab bar whose every switch rebuilt the whole page. A source
/// with a single hidden group goes straight to its grid.
class WallpaperGalleryPage extends StatelessWidget {
  const WallpaperGalleryPage({super.key, required this.source});

  final BackgroundSource source;

  @override
  Widget build(BuildContext context) {
    final languageCode = Localizations.localeOf(context).languageCode;
    final categories = source.visibleCategories;

    if (categories.isEmpty) {
      return TvPageScaffold(
        title: source.localizedName(languageCode),
        child: AppStatusView(
          type: AppStatusType.empty,
          title: i18nOr('background_no_category', '该来源暂无数据'),
          icon: Remix.image_line,
        ),
      );
    }

    if (!source.categorized || categories.length == 1) {
      return WallpaperItemsPage(sourceId: source.id, categoryId: categories.first.id);
    }

    return TvPageScaffold(
      title: source.localizedName(languageCode),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 24.ts(context), vertical: 12.ts(context)),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          return TvSettingsMenuTile<void>(
            title: category.localizedName(languageCode),
            icon: Icons.photo_outlined,
            onTap: () =>
                WallpaperItemsRoute(WallpaperItemsArgs(sourceId: source.id, categoryId: category.id)).push(context),
          );
        },
      ),
    );
  }
}
