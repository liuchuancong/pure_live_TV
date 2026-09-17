import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/wallpaper/wallpaper_api_source.dart';

/// Icon per source, keyed by name.
///
/// Keyed by name rather than by list position on purpose: the groups get
/// reordered and extended, and an index-based table silently shifts every icon
/// the moment one entry is inserted.
const Map<String, IconData> _kSourceIcons = <String, IconData>{
  // 必应
  '必应随机': Icons.travel_explore,
  '必应随机Biturl': Icons.travel_explore,
  '必应随机Jason Zeng': Icons.travel_explore,
  '必应随机Adunm': Icons.travel_explore,
  '必应随机UAPI': Icons.travel_explore,
  '必应随机W3H5': Icons.travel_explore,
  '必应随机YingJoy': Icons.travel_explore,
  '无铭必应每日壁纸': RemixIcons.calendar_line,

  // 无铭 API
  '无铭随机美囡图片': RemixIcons.user_heart_line,
  '无铭随机黑丝图片': RemixIcons.vip_crown_line,
  '无铭随机白丝图片': RemixIcons.star_line,
  '无铭随机抖音美女图片': RemixIcons.tiktok_line,
  '无铭半次元cosplay': RemixIcons.artboard_line,
  '无铭动漫壁纸': RemixIcons.movie_line,
  '无铭随机唯美女生图片': RemixIcons.landscape_line,

  // 其他图源
  '小晓API': RemixIcons.image_2_line,
  'mtyqx': RemixIcons.image_line,
  'picsum': RemixIcons.camera_line,
  'dmoe': RemixIcons.hearts_line,
  'loliApi': RemixIcons.leaf_line,
  'catvod': Icons.pets,
  'LQB二次元DM': RemixIcons.movie_line,
  'LQB二次元PC': RemixIcons.computer_line,
  'UAPI随机二次元': RemixIcons.image_2_line,
  'UAPI随机风景': RemixIcons.landscape_line,
  'UAPI随机AI绘画': RemixIcons.magic_line,
  '360壁纸美女': RemixIcons.user_heart_line,
  '360壁纸风景': RemixIcons.landscape_line,
  '360壁纸动漫': RemixIcons.movie_line,

  // 性感美女
  '随机黑丝·小小API': RemixIcons.vip_crown_line,
  '随机白丝·小小API': RemixIcons.star_line,
  '随机JK·小小API': RemixIcons.artboard_line,
  '随机美腿·云知API': RemixIcons.women_fill,
  '随机小姐姐·素颜API': RemixIcons.user_heart_line,
  '随机美女·素颜API': RemixIcons.user_heart_line,
  '随机妹子·素颜API': RemixIcons.user_heart_line,
  '随机黑丝·素颜API': RemixIcons.vip_crown_line,
  '随机美女·星海API': RemixIcons.user_heart_line,
  '随机妹子·小渡API': RemixIcons.user_heart_line,
  '随机丝袜·Nonebot': RemixIcons.vip_crown_line,
  '甜辣妹壁纸·Lolimi': RemixIcons.heart_3_line,
  'PC美女壁纸·Ltywl': RemixIcons.computer_line,
  'PE美女壁纸·Ltywl': RemixIcons.smartphone_line,
  '美女壁纸·极数本源': RemixIcons.user_heart_line,
  '电脑端小姐姐·Nsuuu': RemixIcons.computer_line,
  '随机白丝·Nsuuu': RemixIcons.star_line,
  '随机黑丝·AA1': RemixIcons.vip_crown_line,
  '随机白丝·AA1': RemixIcons.star_line,
  '随机小姐姐·AA1': RemixIcons.user_heart_line,
  '随机美女·搏天API': RemixIcons.user_heart_line,
  '随机二次元·搏天API': RemixIcons.movie_line,
  '随机美女·姬长信API': RemixIcons.user_heart_line,
  '随机小姐姐·姬长信API': RemixIcons.user_heart_line,
  '随机美女·API盒子': RemixIcons.user_heart_line,
  '随机小姐姐·快手': RemixIcons.video_line,
  '随机Cos·Nonebot': RemixIcons.artboard_line,
  '随机美女·IMGBOX': RemixIcons.user_heart_line,
  '随机美女·HeylieAPI': RemixIcons.user_heart_line,
  '随机美女·CZL': RemixIcons.user_heart_line,
  '随机小姐姐·夏柔专线': RemixIcons.user_heart_line,
  '随机美女·Mioical': RemixIcons.user_heart_line,
  '抖音随机美女·HeylieAPI': RemixIcons.tiktok_line,
  '随机AI美女·HeylieAPI': RemixIcons.magic_line,
  '抖音博主·削七': RemixIcons.tiktok_line,
  '随机美女·PicCDN': RemixIcons.user_heart_line,
  '随机美女·WaifuLand': RemixIcons.user_heart_line,

  // 抖音小姐姐
  '抖音美女·无铭API': RemixIcons.tiktok_line,
  '抖音随机·HeylieAPI': RemixIcons.tiktok_line,
  '抖音小姐姐·小渡API': RemixIcons.tiktok_line,
  '抖音随机·Nsuuu': RemixIcons.tiktok_line,
  '抖音美女·山he': RemixIcons.tiktok_line,
  '抖音随机·AA1': RemixIcons.tiktok_line,

  // 小红书美女
  '小红书随机·小渡API': RemixIcons.book_2_line,
  '小红书美女·Nsuuu': RemixIcons.book_2_line,
  '小红书随机·山he': RemixIcons.book_2_line,
  '小红书随机·AA1': RemixIcons.book_2_line,
  '小红书图集·RedNote': RemixIcons.book_2_line,
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
            onTap: () =>
                context.push(AppRoutes.kWallpaperPreview, extra: WallpaperPreviewArgs.api(source, title: source.name)),
          );
        },
      ),
    );
  }
}
