import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/wallpaper/wallpaper_controls.dart';

/// 设置页里的「背景设置」分区。
///
/// 与播放页的全屏入口共用 [WallpaperControls]。
class WallpaperSettingsSectionPage extends StatelessWidget {
  const WallpaperSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const SingleChildScrollView(child: WallpaperControls());
  }
}
