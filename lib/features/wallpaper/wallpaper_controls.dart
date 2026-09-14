import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/services/background_config/background_config_model.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/background_config/background_image_sources.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/consts/back_ground_source.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 背景/壁纸设置控件。
///
/// 设置页的「背景设置」分区和播放页的全屏「背景设置」入口复用同一份，改的是同一套
/// [BackgroundController] 状态，`TvScaffold` 会实时按新配置重绘背景。
class WallpaperControls extends ConsumerStatefulWidget {
  const WallpaperControls({super.key, this.showPreviewButton = true});

  /// 是否显示「全屏欣赏」入口。
  final bool showPreviewButton;

  @override
  ConsumerState<WallpaperControls> createState() => _WallpaperControlsState();
}

class _WallpaperControlsState extends ConsumerState<WallpaperControls> {
  /// UI 暴露的六种背景模式，映射到 `BackgroundSource`。
  static const List<String> _modeLabels = <String>[
    '跟随主题色',
    '纯色',
    '渐变底色',
    '在线壁纸',
    '本机图片',
    '本机视频',
  ];

  /// 自动换壁纸间隔（小时）。
  static const List<int> _intervalHours = <int>[1, 2, 6, 12, 24];

  /// 渐变预设（模型里存的是颜色数组，UI 只给几套常见配色）。
  static const List<({String name, List<Color> colors})> _gradientPresets = <({String name, List<Color> colors})>[
    (name: '深蓝夜色', colors: <Color>[Color(0xFF141E30), Color(0xFF243B55), Color(0xFF141E30)]),
    (name: '暗夜森林', colors: <Color>[Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)]),
    (name: '紫罗兰', colors: <Color>[Color(0xFF2B1055), Color(0xFF7597DE)]),
    (name: '落日', colors: <Color>[Color(0xFF3A1C71), Color(0xFFD76D77), Color(0xFFFFAF7B)]),
    (name: '墨黑', colors: <Color>[Color(0xFF000000), Color(0xFF1C1C1C)]),
  ];

  bool _busy = false;

  Future<void> _run(Future<bool> Function() action, String failure) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) ToastUtil.show(failure);
  }

  int _modeOf(BackgroundSource source) {
    switch (source) {
      case BackgroundSource.none:
        return 0;
      case BackgroundSource.color:
        return 1;
      case BackgroundSource.gradient:
        return 2;
      case BackgroundSource.localImage:
        return 4;
      case BackgroundSource.localVideo:
        return 5;
      // 其余在线图片/视频统一归到「在线壁纸」。
      default:
        return 3;
    }
  }

  void _applyMode(int index, BackgroundConfigModel config, BackgroundController bg) {
    switch (index) {
      case 0:
        bg.setNone();
      case 1:
        bg.setSolid(config.solidColor);
      case 2:
        bg.setGradient(config.gradientColors);
      case 4:
        _run(bg.pickLocalImage, '没有选择图片');
      case 5:
        _run(bg.pickLocalVideo, '没有选择视频');
      default:
        bg.setNetworkImage(config.networkImageUrl ?? '');
        if (config.currentBoxImageBase64.isEmpty) {
          _run(() => bg.getRandomImage(), '获取壁纸失败，换个图源再试');
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(backgroundControllerProvider);
    final bg = ref.read(backgroundControllerProvider.notifier);
    final tvTheme = context.tvTheme;

    final int mode = _modeOf(config.source);
    final bool isOnline = mode == 3;
    final bool isLocalImage = mode == 4;
    final bool isLocalVideo = mode == 5;

    final solidColors = PlayerConsts.themeColors;
    final solidNames = solidColors.keys.toList(growable: false);
    final solidIndex = solidNames.indexWhere((k) => solidColors[k]!.toARGB32() == config.solidColor.toARGB32());
    final gradientIndex = _gradientPresets.indexWhere(
      (preset) => preset.colors.isNotEmpty && config.gradientColors.isNotEmpty
          ? preset.colors.first.toARGB32() == config.gradientColors.first.toARGB32()
          : false,
    );
    final intervalIndex = _intervalHours.indexOf(config.autoSwitchIntervalHours);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CurrentWallpaper(config: config),

        TvSettingsOptionTile(
          title: '背景模式',
          subtitle: '主题色 / 纯色 / 渐变 / 在线壁纸 / 本机图片 / 本机视频',
          icon: Icons.wallpaper_rounded,
          options: _modeLabels,
          index: mode,
          onChanged: (index) => _applyMode(index, config, bg),
        ),

        if (mode == 1)
          TvSettingsOptionTile(
            title: '纯色颜色',
            icon: Icons.color_lens_outlined,
            options: solidNames,
            index: solidIndex < 0 ? 0 : solidIndex,
            onChanged: (index) => bg.setSolid(solidColors[solidNames[index]]!),
          ),

        if (mode == 2)
          TvSettingsOptionTile(
            title: '渐变配色',
            icon: Icons.gradient_rounded,
            options: _gradientPresets.map((e) => e.name).toList(growable: false),
            index: gradientIndex < 0 ? 0 : gradientIndex,
            onChanged: (index) => bg.setGradient(_gradientPresets[index].colors),
          ),

        if (isOnline) ...[
          TvSettingsOptionTile(
            title: '壁纸源',
            subtitle: '选中后会自动换一张',
            icon: Icons.image_search_rounded,
            options: BackgroundImageSources.names,
            index: bg.boxImageSourceIndex,
            onChanged: (index) => _run(() async {
              await bg.setBoxImageSourceIndex(index);
              return bg.getRandomImage();
            }, '获取壁纸失败，换个图源再试'),
          ),
          _ActionButton(
            label: _busy ? '获取中…' : '换一张',
            icon: Icons.refresh_rounded,
            onTap: _busy ? null : () => _run(() => bg.getRandomImage(), '获取壁纸失败，换个图源再试'),
          ),
        ],

        if (isLocalImage)
          _ActionButton(
            label: _busy ? '处理中…' : '选择图片',
            icon: Icons.add_photo_alternate_outlined,
            onTap: _busy ? null : () => _run(bg.pickLocalImage, '没有选择图片'),
          ),

        if (isLocalVideo)
          _ActionButton(
            label: _busy ? '处理中…' : '选择视频',
            icon: Icons.video_file_outlined,
            onTap: _busy ? null : () => _run(bg.pickLocalVideo, '没有选择视频'),
          ),

        TvSettingsOptionTile(
          title: '填充模式',
          icon: Icons.aspect_ratio_rounded,
          options: BackgroundFitOptions.labels,
          index: BackgroundFitOptions.indexOf(config.boxFit),
          onChanged: (index) => bg.setBoxFit(BackgroundFitOptions.values[index]),
        ),

        TvSettingsSliderTile(
          title: '遮罩浓度',
          subtitle: '压暗背景，保证文字可读',
          icon: Icons.opacity_rounded,
          value: config.maskOpacity,
          min: 0,
          max: 0.9,
          step: 0.05,
          displayValue: '${(config.maskOpacity * 100).round()}%',
          onChanged: (value) => bg.setMaskOpacity(value),
        ),

        TvSettingsSliderTile(
          title: '模糊度',
          subtitle: '把壁纸糊掉，让前景更清晰',
          icon: Icons.blur_on_rounded,
          value: config.blur,
          min: 0,
          max: 30,
          step: 1,
          displayValue: config.blur <= 0 ? '关闭' : config.blur.toStringAsFixed(0),
          onChanged: (value) => bg.setBlur(value),
        ),

        // 自动换壁纸只对在线图源有意义：本机图片/视频是单份文件，没有可轮换的对象。
        if (isOnline) ...[
          TvSettingsSwitchTile(
            title: '自动换壁纸',
            subtitle: '按下面的间隔自动换一张在线壁纸',
            icon: Icons.autorenew_rounded,
            value: config.autoSwitch,
            onChanged: (value) => bg.setAutoSwitch(value),
          ),
          if (config.autoSwitch)
            TvSettingsOptionTile(
              title: '切换间隔',
              icon: Icons.schedule_rounded,
              options: _intervalHours.map((h) => '$h 小时').toList(growable: false),
              index: intervalIndex < 0 ? 2 : intervalIndex,
              onChanged: (index) => bg.setAutoSwitchIntervalHours(_intervalHours[index]),
            ),
        ],

        if (widget.showPreviewButton && (isOnline || isLocalImage))
          _ActionButton(
            label: '全屏欣赏',
            icon: Icons.fullscreen_rounded,
            secondary: true,
            onTap: () => context.push(AppRoutes.kWallpaperPreview),
          ),

        Padding(
          padding: EdgeInsets.fromLTRB(16.sp, 10.sp, 16.sp, 0),
          child: Text(
            '提示：在线壁纸里「官方壁纸 / Wallhaven / Deepin」目前是占位示例地址，'
            '等真实接口就位后改 background_image_sources.dart 那张表即可。',
            style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
          ),
        ),
      ],
    );
  }
}

/// 当前壁纸缩略图 + 来源说明。
class _CurrentWallpaper extends StatelessWidget {
  const _CurrentWallpaper({required this.config});

  final BackgroundConfigModel config;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final image = SettingsService.to.bg.cachedBackgroundImage;
    final isVideo =
        config.source == BackgroundSource.localVideo ||
        config.source == BackgroundSource.assetVideo ||
        config.source == BackgroundSource.networkVideo;

    return Padding(
      padding: EdgeInsets.fromLTRB(16.sp, 4.sp, 16.sp, 8.sp),
      child: Row(
        children: [
          Container(
            width: 160.sp,
            height: 90.sp,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: tvTheme.cardColor,
              borderRadius: BorderRadius.circular(10.sp),
              border: Border.all(color: tvTheme.secondaryTextColor.withValues(alpha: 0.25)),
            ),
            child: isVideo
                ? Icon(Icons.movie_rounded, size: 32.sp, color: tvTheme.secondaryTextColor)
                : image != null
                ? Image(image: image, fit: BoxFit.cover)
                : Icon(Icons.image_outlined, size: 32.sp, color: tvTheme.secondaryTextColor),
          ),
          SizedBox(width: 14.sp),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('当前壁纸', style: AppTextStyles.t18W600.copyWith(color: tvTheme.primaryTextColor)),
                SizedBox(height: 4.sp),
                Text(_describe(), style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _describe() {
    String tail(String? path) {
      if (path == null || path.isEmpty) return '';
      return path.split(RegExp(r'[\\/]')).last;
    }

    switch (config.source) {
      case BackgroundSource.none:
        return '跟随主题色';
      case BackgroundSource.color:
        return '纯色';
      case BackgroundSource.gradient:
        return '渐变底色';
      case BackgroundSource.localImage:
        return '本机图片 · ${tail(config.localImagePath)}';
      case BackgroundSource.assetImage:
        return '内置图片 · ${tail(config.assetImagePath)}';
      case BackgroundSource.localVideo:
        return '本机视频 · ${tail(config.localVideoPath)}';
      case BackgroundSource.assetVideo:
        return '内置视频 · ${tail(config.assetVideoPath)}';
      case BackgroundSource.networkVideo:
        return '在线视频';
      case BackgroundSource.networkImage:
        final source = BackgroundImageSources.at(SettingsService.to.bg.boxImageSourceIndex);
        return '在线壁纸 · ${source.name}';
    }
  }
}

/// 设置页里的一枚动作按钮（换一张 / 选择文件 / 全屏欣赏）。
class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.icon, this.onTap, this.secondary = false});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool secondary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 6.sp),
      child: TvButton(
        title: label,
        icon: Icon(icon, size: 22.sp),
        size: TvButtonSize.medium,
        isSecondary: secondary,
        onTap: onTap,
      ),
    );
  }
}
