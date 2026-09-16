import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The random-wallpaper APIs, one row each.
///
/// Picking a row opens the fullscreen preview, which downloads a picture and
/// offers 换一张 until the user commits one as the background. All 19 sources
/// used to be listed on the settings home page itself; they live here now so
/// that page stays four rows long.
class WallpaperApiPage extends StatelessWidget {
  const WallpaperApiPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TvScaffold(
      title: i18n('wallpaper_api_group'),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
        itemCount: kWallpaperApiSources.length,
        itemBuilder: (context, index) {
          final source = kWallpaperApiSources[index];
          return TvSettingsMenuTile<void>(
            title: source.name,
            subtitle: source.host,
            icon: Icons.casino_outlined,
            onTap: () => context.push(
              AppRoutes.kWallpaperPreview,
              extra: WallpaperPreviewArgs.api(source, title: source.name),
            ),
          );
        },
      ),
    );
  }
}
