import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/features/wallpaper/wallpaper_args.dart';
import 'package:pure_live/features/wallpaper/wallpaper_display_options.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Background settings home.
///
/// Deliberately a short list: four entries picking *what* the background is
/// (colors / live wallpapers / the wallpaper library / the random-image APIs),
/// then the three display switches that apply to whatever is picked. Each entry
/// is its own page, so the 5 700-item library and the 19 random APIs are never
/// rebuilt as part of this screen — the old page listed every source and every
/// API inline, which is what made it slow and long.
class WallpaperPage extends ConsumerWidget {
  const WallpaperPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watching the controller keeps the two value rows in step with a change
    // made in the preview (or by clearing the background right here).
    final bgState = ref.watch(backgroundControllerProvider);

    return TvScaffold(
      title: i18n('ui_background_settings'),
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TvSettingsGroupTitle(title: i18nOr('wallpaper_source_group', '背景来源')),
            TvSettingsCard(
              children: [
                TvSettingsNavTile(
                  title: i18nOr('wallpaper_solid_color', '纯色'),
                  subtitle: i18nOr('wallpaper_solid_color_subtitle', '纯色与渐变填充'),
                  icon: Icons.gradient_outlined,
                  onTap: () => context.push(
                    AppRoutes.kWallpaperItems,
                    extra: const WallpaperItemsArgs(sourceId: 'solid-color'),
                  ),
                ),
                TvSettingsNavTile(
                  title: i18nOr('wallpaper_video_wallpaper', '视频壁纸'),
                  subtitle: i18nOr('wallpaper_video_subtitle', '动态视频背景'),
                  icon: Icons.movie_outlined,
                  onTap: () => context.push(
                    AppRoutes.kWallpaperItems,
                    extra: const WallpaperItemsArgs(sourceId: 'video'),
                  ),
                ),
                TvSettingsNavTile(
                  title: i18n('wallpaper_library'),
                  subtitle: i18nOr('wallpaper_library_entry_subtitle', '官方、Wallhaven、必应等图库'),
                  icon: Icons.photo_library_outlined,
                  onTap: () => context.push(AppRoutes.kWallpaperLibrary),
                ),
                TvSettingsNavTile(
                  title: i18n('wallpaper_api_group'),
                  subtitle: i18nOr('wallpaper_api_entry_subtitle', '每次打开随机取一张图'),
                  icon: Icons.auto_awesome_outlined,
                  onTap: () => context.push(AppRoutes.kWallpaperApi),
                ),
              ],
            ),
            SizedBox(height: 20.sp),
            TvSettingsGroupTitle(title: i18n('wallpaper_display_group')),
            TvSettingsCard(
              children: [
                TvSettingsOptionTile(
                  title: i18n('wallpaper_fit_mode'),
                  icon: Icons.aspect_ratio_outlined,
                  options: [for (final fit in kWallpaperFitModes) wallpaperFitLabel(fit)],
                  index: kWallpaperFitModes.indexOf(bgState.boxFit).clamp(0, kWallpaperFitModes.length - 1),
                  onChanged: (index) => SettingsService.to.bg.setBoxFit(kWallpaperFitModes[index]),
                ),
                TvSettingsOptionTile(
                  title: i18nOr('wallpaper_mask', '遮罩'),
                  icon: Icons.brightness_6_outlined,
                  options: [for (final step in kWallpaperMaskSteps) wallpaperMaskLabel(step)],
                  index: wallpaperMaskIndex(bgState.maskOpacity),
                  onChanged: (index) => SettingsService.to.bg.setMaskOpacity(kWallpaperMaskSteps[index]),
                ),
                TvSettingsOptionTile(
                  title: i18n('background_clear'),
                  icon: Icons.layers_clear_outlined,
                  options: const <String>[''],
                  index: 0,
                  onChanged: (_) {
                    SettingsService.to.bg.setNone();
                    ToastUtil.show(i18n('wallpaper_background_cleared'));
                  },
                ),
              ],
            ),
            SizedBox(height: 40.sp),
          ],
        ),
      ),
    );
  }
}
