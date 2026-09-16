import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';

List<IconData> _kApiIcons = <IconData>[
  Icons.travel_explore, // 必应随机
  RemixIcons.image_2_line, // 小晓API
  RemixIcons.calendar_line, // 无铭必应每日壁纸
  RemixIcons.user_heart_line, // 无铭随机美囡图片
  RemixIcons.vip_crown_line, // 无铭随机黑丝图片
  RemixIcons.star_line, // 无铭随机白丝图片
  RemixIcons.tiktok_line, // 无铭随机抖音美女图片
  RemixIcons.artboard_line, // 无铭半次元cosplay
  RemixIcons.movie_line, // 无铭动漫壁纸
  RemixIcons.landscape_line, // 无铭随机唯美女生图片
  RemixIcons.image_line, // mtyqx
  RemixIcons.gallery_line, // 栗次元
  RemixIcons.camera_line, // picsum
  RemixIcons.hearts_line, // dmoe
  RemixIcons.leaf_line, // loliApi（可爱/自然）
  RemixIcons.palette_line, // 搏天动漫
  RemixIcons.women_line, // 搏天妹子
  RemixIcons.shuffle_line, // 搏天随机
  Icons.pets, // catvod
];

IconData _apiIcon(int index) => index < _kApiIcons.length ? _kApiIcons[index] : RemixIcons.apps_2_line;

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
            icon: _apiIcon(index),
            onTap: () =>
                context.push(AppRoutes.kWallpaperPreview, extra: WallpaperPreviewArgs.api(source, title: source.name)),
          );
        },
      ),
    );
  }
}
