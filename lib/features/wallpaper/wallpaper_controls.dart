import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/background_config/background_image_sources.dart';
import 'package:pure_live/shared/consts/back_ground_source.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 背景/壁纸设置控件。
///
/// 设置页的「背景设置」分区和播放页的全屏「背景设置」入口复用同一份，
/// 保证两条路径改的是同一套 [BackgroundController] 状态（`TvScaffold` 会
/// 实时按新配置重绘背景）。
class WallpaperControls extends ConsumerStatefulWidget {
  const WallpaperControls({super.key, this.showPreviewButton = true});

  /// 是否显示「全屏欣赏」入口。
  final bool showPreviewButton;

  @override
  ConsumerState<WallpaperControls> createState() => _WallpaperControlsState();
}

class _WallpaperControlsState extends ConsumerState<WallpaperControls> {
  /// 背景模式。只暴露最常用的三种，避免让遥控器在 9 种 BackgroundSource 里翻。
  static const List<String> _modeLabels = <String>['不使用', '渐变底色', '随机壁纸'];

  bool _loading = false;

  Future<void> _fetch() async {
    if (_loading) return;
    setState(() => _loading = true);
    final ok = await ref.read(backgroundControllerProvider.notifier).getRandomImage();
    if (!mounted) return;
    setState(() => _loading = false);
    if (!ok) ToastUtil.show(i18nOr('ui_wallpaper_fetch_failed', '获取壁纸失败，换个图源再试'));
  }

  int _modeOf(BackgroundSource source) {
    switch (source) {
      case BackgroundSource.none:
      case BackgroundSource.color:
        return 0;
      case BackgroundSource.gradient:
        return 1;
      default:
        return 2;
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(backgroundControllerProvider);
    final bg = ref.read(backgroundControllerProvider.notifier);
    final int sourceIndex = bg.boxImageSourceIndex;
    final bool isRandomMode = _modeOf(config.source) == 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: i18nOr('ui_background_mode', '背景模式'),
          subtitle: i18nOr('ui_background_mode_desc', '不使用 / 渐变底色 / 随机壁纸'),
          icon: Icons.wallpaper_rounded,
          options: _modeLabels,
          index: _modeOf(config.source),
          onChanged: (index) async {
            switch (index) {
              case 0:
                bg.setNone();
              case 1:
                bg.setGradient(config.gradientColors);
              default:
                // 切到随机壁纸时如果还没有图，立刻抓一张，避免出现纯色空白。
                if (config.currentBoxImageBase64.isEmpty) {
                  await _fetch();
                } else {
                  bg.setNetworkImage(config.networkImageUrl ?? '');
                }
            }
          },
        ),
        TvSettingsOptionTile(
          title: i18nOr('ui_wallpaper_source', '壁纸源'),
          subtitle: i18nOr('ui_wallpaper_source_desc', '选择图源后会自动换一张'),
          icon: Icons.image_search_rounded,
          options: BackgroundImageSources.names,
          index: sourceIndex,
          onChanged: (index) async {
            await bg.setBoxImageSourceIndex(index);
            await _fetch();
          },
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
          child: TvButton(
            title: _loading ? i18nOr('ui_loading', '获取中…') : i18nOr('ui_wallpaper_next', '换一张'),
            icon: Icon(Icons.refresh_rounded, size: 22.sp),
            size: TvButtonSize.medium,
            onTap: _loading ? null : _fetch,
          ),
        ),
        TvSettingsOptionTile(
          title: i18nOr('ui_background_fit', '填充模式'),
          icon: Icons.aspect_ratio_rounded,
          options: BackgroundFitOptions.labels,
          index: BackgroundFitOptions.indexOf(config.boxFit),
          onChanged: (index) => bg.setBoxFit(BackgroundFitOptions.values[index]),
        ),
        TvSettingsSliderTile(
          title: i18nOr('ui_background_mask', '遮罩浓度'),
          subtitle: i18nOr('ui_background_mask_desc', '压暗背景，保证文字可读'),
          icon: Icons.opacity_rounded,
          value: config.maskOpacity,
          min: 0,
          max: 0.9,
          step: 0.05,
          displayValue: '${(config.maskOpacity * 100).round()}%',
          onChanged: (value) => bg.setMaskOpacity(value),
        ),
        if (widget.showPreviewButton && isRandomMode)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
            child: TvButton(
              title: i18nOr('ui_wallpaper_preview', '全屏欣赏'),
              icon: Icon(Icons.fullscreen_rounded, size: 22.sp),
              size: TvButtonSize.medium,
              isSecondary: true,
              onTap: () => context.push(AppRoutes.kWallpaperPreview),
            ),
          ),
      ],
    );
  }
}
