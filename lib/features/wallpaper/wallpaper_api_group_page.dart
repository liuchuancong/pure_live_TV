import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Icon per source, keyed by name.
///
/// Keyed by name rather than by list position on purpose: the groups get
/// reordered and extended, and an index-based table silently shifts every icon
/// the moment one entry is inserted.
const Map<String, IconData> _kSourceIcons = <String, IconData>{
  '必应随机': Icons.travel_explore,
  '小晓API': RemixIcons.image_2_line,
  '无铭必应每日壁纸': RemixIcons.calendar_line,
  '无铭随机美囡图片': RemixIcons.user_heart_line,
  '无铭随机黑丝图片': RemixIcons.vip_crown_line,
  '无铭随机白丝图片': RemixIcons.star_line,
  '无铭随机抖音美女图片': RemixIcons.tiktok_line,
  '无铭半次元cosplay': RemixIcons.artboard_line,
  '无铭动漫壁纸': RemixIcons.movie_line,
  '无铭随机唯美女生图片': RemixIcons.landscape_line,
  'mtyqx': RemixIcons.image_line,
  'picsum': RemixIcons.camera_line,
  'dmoe': RemixIcons.hearts_line,
  'loliApi': RemixIcons.leaf_line,
  'catvod': Icons.pets,
};

IconData _sourceIcon(WallpaperApiSource source) {
  final mapped = _kSourceIcons[source.name];
  if (mapped != null) return mapped;
  // Every 栗次元 row keeps the family icon, including the categories.
  if (source.url.startsWith(WallpaperApiSource.alcyBase)) return RemixIcons.gallery_line;
  return RemixIcons.apps_2_line;
}

/// The sources inside one API group.
///
/// Picking a row opens the fullscreen preview, which downloads a picture and
/// offers 换一张 until the user commits one as the background.
class WallpaperApiGroupPage extends StatelessWidget {
  const WallpaperApiGroupPage({super.key, required this.group});

  final WallpaperApiGroup group;

  @override
  Widget build(BuildContext context) {
    return TvPageScaffold(
      title: group.localizedName(Localizations.localeOf(context).languageCode),
      child: ListView.builder(
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
        itemCount: group.sources.length,
        itemBuilder: (context, index) {
          final source = group.sources[index];
          return TvSettingsMenuTile<void>(
            title: source.name,
            subtitle: source.host,
            icon: _sourceIcon(source),
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