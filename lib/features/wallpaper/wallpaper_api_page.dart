import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';

/// Icon per API group, keyed by the group id.
const Map<String, IconData> _kGroupIcons = <String, IconData>{
  'bing': RemixIcons.calendar_line,
  'alcy': RemixIcons.gallery_line,
  'wuming': RemixIcons.apps_2_line,
  'misc': RemixIcons.image_line,
};

/// The random-wallpaper APIs, grouped.
///
/// The list reached nearly thirty entries once 栗次元's categories became
/// individual sources, which is far too long for a remote: one screenful became
/// four. A group row opens its sources on a second-level page, and a source
/// there opens the fullscreen preview.
class WallpaperApiPage extends StatelessWidget {
  const WallpaperApiPage({super.key});

  @override
  Widget build(BuildContext context) {
    final String languageCode = Localizations.localeOf(context).languageCode;

    return TvPageScaffold(
      title: i18n('wallpaper_api_group'),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
        itemCount: kWallpaperApiGroups.length,
        itemBuilder: (context, index) {
          final group = kWallpaperApiGroups[index];
          return TvSettingsMenuTile<void>(
            title: group.localizedName(languageCode),
            subtitle: i18nOr('wallpaper_api_group_count', '{count} 个来源', args: {'count': '${group.sources.length}'}),
            icon: _kGroupIcons[group.id] ?? RemixIcons.apps_2_line,
            onTap: () => context.push(AppRoutes.kWallpaperApiGroup, extra: group),
          );
        },
      ),
    );
  }
}
