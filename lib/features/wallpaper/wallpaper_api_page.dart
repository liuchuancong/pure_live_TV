import 'package:flutter/material.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';
import 'package:pure_live/app/router/app_router.dart';

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
            leading: NumberLeading(index + 1),
            onTap: () => WallpaperApiGroupRoute(group).push(context),
          );
        },
      ),
    );
  }
}
