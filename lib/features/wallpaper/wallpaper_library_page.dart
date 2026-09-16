import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/services/background_config/remote/background_repository.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The picture library: one row per picture source.
///
/// The source tree is compiled in, so the page renders immediately — no loading
/// state and no failure state at this level. Only the individual category grids
/// talk to the network.
class WallpaperLibraryPage extends ConsumerWidget {
  const WallpaperLibraryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(backgroundCatalogProvider);
    final sources = catalog.imageSources;

    return TvScaffold(
      title: i18n('wallpaper_library'),
      child: sources.isEmpty
          ? AppStatusView(
              type: AppStatusType.empty,
              subtitle: i18nOr('background_catalog_empty', '远端目录为空'),
            )
          : ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
              itemCount: sources.length,
              itemBuilder: (context, index) {
                final source = sources[index];
                final categories = source.visibleCategories.length;
                return TvSettingsMenuTile<void>(
                  title: source.localizedName(Localizations.localeOf(context).languageCode),
                  subtitle: i18nOr(
                    'wallpaper_library_subtitle',
                    '{count} 张 · {categories} 个分类',
                    args: {'count': '${source.count}', 'categories': '$categories'},
                  ),
                  icon: Icons.image_outlined,
                  onTap: () => context.push(AppRoutes.kWallpaperGallery, extra: source),
                );
              },
            ),
    );
  }
}
