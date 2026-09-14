import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/wallpaper/wallpaper_controls.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 全屏「背景设置」页。
///
/// 播放页底部控制栏的「背景设置」按钮和 `AppRoutes.kWallpaperPage` 指向这里；
/// 控件本体是 [WallpaperControls]，与设置页里的分区共用。
class WallpaperPage extends StatelessWidget {
  const WallpaperPage({super.key});

  @override
  Widget build(BuildContext context) {
    return TvScaffold(
      title: i18nOr('ui_background_settings', '背景设置'),
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: const WallpaperControls(),
      ),
    );
  }
}
