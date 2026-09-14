import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/background_config/background_presets.dart';
import 'package:pure_live/services/background_config/background_config_model.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/background_config/background_image_sources.dart';
import 'package:pure_live/services/background_config/background_video_sources.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/consts/back_ground_source.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 背景/壁纸设置控件。
///
/// 设置页的「背景设置」分区和播放页的全屏「背景设置」入口复用同一份，改的是同一套
/// [BackgroundController] 状态，`TvScaffold` 会实时按新配置重绘背景。
///
/// 对照 iTab 的壁纸库，七种模式一个不少：
/// 纯色（取色板 + 自定义色值）、渐变（webGradients 那套预设）、
/// 在线壁纸（图源表 + 换一张 + 上一张）、自定义在线图片链接、
/// 在线动态壁纸（视频页签：图源 + 分类 + 随机一条）、本机图片、本机视频。
class WallpaperControls extends ConsumerStatefulWidget {
  const WallpaperControls({super.key, this.showPreviewButton = true});

  /// 是否显示「全屏欣赏」入口。
  final bool showPreviewButton;

  @override
  ConsumerState<WallpaperControls> createState() => _WallpaperControlsState();
}

class _WallpaperControlsState extends ConsumerState<WallpaperControls> {
  /// UI 暴露的背景模式，映射到 `BackgroundSource`。
  static const List<String> _modeLabels = <String>[
    '跟随主题色',
    '纯色',
    '渐变底色',
    '在线壁纸',
    '自定义图片链接',
    '在线动态壁纸',
    '本机图片',
    '本机视频',
  ];

  /// 自动换壁纸间隔（小时）。
  static const List<int> _intervalHours = <int>[1, 2, 6, 12, 24];

  bool _busy = false;

  Future<void> _run(Future<bool> Function() action, String failure) async {
    if (_busy) return;
    setState(() => _busy = true);
    final ok = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    if (!ok) ToastUtil.show(failure);
  }

  BackgroundController get _bg => ref.read(backgroundControllerProvider.notifier);

  /// 把当前壁纸存到下载目录。
  ///
  /// 与 iTab 的「下载壁纸」同一件事：在线壁纸只是一张网图，用户想留一份原图。
  Future<void> _saveWallpaper() async {
    if (_busy) return;
    setState(() => _busy = true);
    final path = await _bg.saveCurrentWallpaper();
    if (!mounted) return;
    setState(() => _busy = false);
    ToastUtil.show(path == null ? '保存失败' : '已保存到 $path');
  }

  /// 翻回上一张在线壁纸。
  Future<void> _restorePrevious() => _run(_bg.restorePreviousWallpaper, '没有可回退的上一张壁纸');

  /// 手输色值（iTab 纯色页签的取色器可以直接敲色号）。
  Future<void> _inputSolidColor() async {
    final input = await TvDialogUtils.showInput(
      context: context,
      title: '输入颜色值',
      hintText: '#RRGGBB，例如 #141E30',
      initialValue: _hexOf(_bg.config.solidColor),
    );
    if (input == null || input.trim().isEmpty) return;
    final color = BackgroundPresets.parseHexColor(input);
    if (color == null) {
      ToastUtil.show('色值格式不对，示例：#141E30');
      return;
    }
    _bg.setSolid(color);
  }

  /// `Color` → `#RRGGBB`（`toHex()` 只挂在 HexColor 上，这里自己拼，避免多引一层类型）。
  static String _hexOf(Color color) {
    final rgb = color.toARGB32() & 0xFFFFFF;
    return '#${rgb.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  /// 手输在线图片链接（iTab「使用在线图片链接」）。
  Future<void> _inputCustomImageUrl() async {
    final input = await TvDialogUtils.showInput(
      context: context,
      title: '在线图片链接',
      hintText: 'https://…/wallpaper.jpg',
      initialValue: _bg.config.customImageUrl,
    );
    if (input == null || input.trim().isEmpty) return;
    await _run(() => _bg.applyCustomImageUrl(input), '图片拉取失败，检查链接是否可直连');
  }

  /// 手输在线视频链接（动态壁纸）。
  Future<void> _inputCustomVideoUrl() async {
    final input = await TvDialogUtils.showInput(
      context: context,
      title: '在线视频链接',
      hintText: 'https://…/wallpaper.mp4',
      initialValue: _bg.config.customVideoUrl,
    );
    if (input == null || input.trim().isEmpty) return;
    await _run(() => _bg.applyCustomVideoUrl(input), '视频地址不可用');
  }

  /// 填写自定义动态壁纸接口，并顺手探活一次。
  Future<void> _inputCustomVideoApi() async {
    final input = await TvDialogUtils.showInput(
      context: context,
      title: '动态壁纸接口地址',
      hintText: 'https://…/random?page={page}&tag={tag}',
      initialValue: _bg.config.customVideoApiUrl,
      maxLength: 500,
    );
    if (input == null || input.trim().isEmpty) return;
    await _bg.setCustomVideoApiUrl(input);
    final result = await _bg.probeCustomVideoApi(input);
    if (!mounted) return;
    ToastUtil.show(result.message);
    if (result.ok) await _run(() => _bg.getRandomNetworkVideo(), '获取动态壁纸失败，换个图源再试');
  }

  int _modeOf(BackgroundSource source, BackgroundConfigModel config) {
    switch (source) {
      case BackgroundSource.none:
        return 0;
      case BackgroundSource.color:
        return 1;
      case BackgroundSource.gradient:
        return 2;
      case BackgroundSource.localImage:
        return 6;
      case BackgroundSource.localVideo:
      case BackgroundSource.assetVideo:
        return 7;
      case BackgroundSource.networkVideo:
        return 5;
      default:
        // 在线图片源只区分「自定义链接」和「图源表」两种，都用同一个 enum 值。
        return config.customImageUrl.isNotEmpty && config.customImageUrl == config.networkImageUrl ? 4 : 3;
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
        // 已经有手填地址就直接重下；没有就弹输入框让用户填。
        if (config.customImageUrl.isNotEmpty) {
          _run(() => bg.applyCustomImageUrl(config.customImageUrl), '图片拉取失败，检查链接是否可直连');
        } else {
          unawaited(_inputCustomImageUrl());
        }
      case 5:
        final currentVideo = config.networkVideoUrl ?? '';
        if (currentVideo.isNotEmpty) {
          unawaited(bg.reloadBackgroundVideo());
        } else if (config.customVideoUrl.isNotEmpty) {
          _run(() => bg.applyCustomVideoUrl(config.customVideoUrl), '视频地址不可用');
        } else {
          // 内置公开源经常挂；失败时给一条确定能播的示例，
          // 让用户能区分「播放链路坏了」和「接口挂了」。
          _run(
            () => bg.getRandomNetworkVideo().then((ok) async {
              if (ok) return true;
              await bg.setVideoSourceIndex(BackgroundVideoSources.indexOfId('sample'));
              return bg.getRandomNetworkVideo();
            }),
            '获取动态壁纸失败，可换「示例视频」自检或填自己的接口',
          );
        }
      case 6:
        _run(bg.pickLocalImage, '没有选择图片');
      case 7:
        _run(bg.pickLocalVideo, '没有选择视频');
      default:
        bg.setNetworkImage(config.networkImageUrl ?? '');
        if (config.currentBoxImageBase64.isEmpty) {
          _run(() => bg.getRandomImage(), '获取壁纸失败，换个图源再试');
        }
    }
  }

  /// 自动换壁纸的下一次时间说明。
  ///
  /// 时间基准是持久化的 `lastSwitchAt`：熄屏期间错过的轮换会在下次进入应用时
  /// 由后台任务补跑，所以这里的「下次」是真实调度时间，不是页面内的定时器时间。
  String _autoSwitchSummary(BackgroundConfigModel config) {
    final last = config.lastSwitchAt;
    if (last == null) return '下次进入应用时自动换一张';
    final next = last.add(Duration(hours: config.autoSwitchIntervalHours.clamp(1, 24)));
    final now = DateTime.now();
    if (!next.isAfter(now)) return '已到期，进入应用后自动换一张';
    final remaining = next.difference(now);
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes % 60;
    return hours > 0 ? '下次约 $hours 小时 $minutes 分钟后' : '下次约 $minutes 分钟后';
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(backgroundControllerProvider);
    final bg = ref.read(backgroundControllerProvider.notifier);
    final tvTheme = context.tvTheme;

    final int mode = _modeOf(config.source, config);
    final bool isOnline = mode == 3;
    final bool isCustomImage = mode == 4;
    final bool isOnlineVideo = mode == 5;
    final bool isLocalImage = mode == 6;
    final bool isLocalVideo = mode == 7;

    final intervalIndex = _intervalHours.indexOf(config.autoSwitchIntervalHours);
    final gradientIndex = BackgroundPresets.gradientIndexOf(config.gradientColors);
    final videoTagNames = BackgroundVideoSources.tagNames(config.videoSourceIndex);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CurrentWallpaper(config: config),

        TvSettingsOptionTile(
          title: '背景模式',
          subtitle: '主题色 / 纯色 / 渐变 / 在线壁纸 / 自定义链接 / 动态壁纸 / 本机图片 / 本机视频',
          icon: Icons.wallpaper_rounded,
          options: _modeLabels,
          index: mode,
          onChanged: (index) => _applyMode(index, config, bg),
        ),

        // —— 纯色：取色板 + 自定义色值 ——
        if (mode == 1) ...[
          Padding(
            padding: EdgeInsets.fromLTRB(16.sp, 8.sp, 16.sp, 0),
            child: Text(
              '选择颜色',
              style: AppTextStyles.t16W600.copyWith(color: tvTheme.primaryTextColor),
            ),
          ),
          _ColorGrid(
            colors: BackgroundPresets.solidColors,
            selected: config.solidColor,
            onSelected: bg.setSolid,
          ),
          _ActionButton(
            label: '输入颜色值',
            icon: Icons.colorize_rounded,
            secondary: true,
            onTap: _inputSolidColor,
          ),
        ],

        // —— 渐变 ——
        if (mode == 2)
          TvSettingsOptionTile(
            title: '渐变配色',
            icon: Icons.gradient_rounded,
            options: BackgroundPresets.gradients.map((e) => e.name).toList(growable: false),
            index: gradientIndex,
            onChanged: (index) => bg.setGradient(BackgroundPresets.gradients[index].colors),
          ),

        // —— 在线壁纸 ——
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
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: _busy ? '获取中…' : '换一张',
                  icon: Icons.refresh_rounded,
                  onTap: _busy ? null : () => _run(() => bg.getRandomImage(), '获取壁纸失败，换个图源再试'),
                ),
              ),
              // 翻回上一张靠的是 [BackgroundConfigModel.recentImageUrls]。
              if (config.recentImageUrls.length > 1)
                Expanded(
                  child: _ActionButton(
                    label: '上一张',
                    icon: Icons.undo_rounded,
                    secondary: true,
                    onTap: _busy ? null : _restorePrevious,
                  ),
                ),
            ],
          ),
        ],

        // —— 自定义在线图片链接（iTab「使用在线图片链接」）——
        if (isCustomImage) ...[
          _ValueRow(
            label: '图片链接',
            value: config.customImageUrl.isEmpty ? '未填写' : config.customImageUrl,
            icon: Icons.link_rounded,
          ),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: '填写链接',
                  icon: Icons.edit_rounded,
                  onTap: _inputCustomImageUrl,
                ),
              ),
              Expanded(
                child: _ActionButton(
                  label: _busy ? '应用中…' : '应用',
                  icon: Icons.check_rounded,
                  secondary: true,
                  onTap: _busy || config.customImageUrl.isEmpty
                      ? null
                      : () => _run(
                          () => bg.applyCustomImageUrl(config.customImageUrl),
                          '图片拉取失败，检查链接是否可直连',
                        ),
                ),
              ),
            ],
          ),
        ],

        // —— 在线动态壁纸（iTab「视频」页签）——
        if (isOnlineVideo) ...[
          TvSettingsOptionTile(
            title: '动态壁纸源',
            icon: Icons.video_library_outlined,
            options: BackgroundVideoSources.names,
            index: config.videoSourceIndex,
            onChanged: (index) => unawaited(bg.setVideoSourceIndex(index)),
          ),
          if (BackgroundVideoSources.at(config.videoSourceIndex).id == BackgroundVideoSources.customId) ...[
            _ValueRow(
              label: '接口地址',
              value: config.customVideoApiUrl.isEmpty ? '未填写' : config.customVideoApiUrl,
              icon: Icons.link_rounded,
            ),
            _ActionButton(
              label: '填写接口地址并测试',
              icon: Icons.settings_ethernet_rounded,
              secondary: true,
              onTap: _inputCustomVideoApi,
            ),
          ],
          if (videoTagNames.isNotEmpty)
            TvSettingsOptionTile(
              title: '分类',
              icon: Icons.category_outlined,
              options: videoTagNames,
              index: config.videoTagIndex.clamp(0, videoTagNames.length - 1),
              onChanged: (index) => unawaited(bg.setVideoTagIndex(index)),
            ),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: _busy ? '获取中…' : '换一条',
                  icon: Icons.refresh_rounded,
                  onTap: _busy ? null : () => _run(() => bg.getRandomNetworkVideo(), '获取动态壁纸失败，换个图源再试'),
                ),
              ),
              Expanded(
                child: _ActionButton(
                  label: '填写视频链接',
                  icon: Icons.edit_rounded,
                  secondary: true,
                  onTap: _inputCustomVideoUrl,
                ),
              ),
            ],
          ),
          if ((config.networkVideoUrl ?? '').isNotEmpty)
            _ValueRow(label: '当前视频', value: config.networkVideoUrl!, icon: Icons.movie_outlined),
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

        // 自动换壁纸只对在线图片源有意义：本机图片/视频是单份文件，
        // 在线动态壁纸按条更换由「换一条」控制，没有可轮换的图源表。
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
          if (config.autoSwitch)
            Padding(
              padding: EdgeInsets.fromLTRB(16.sp, 6.sp, 16.sp, 0),
              child: Text(
                _autoSwitchSummary(config),
                style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
              ),
            ),
        ],

        if (widget.showPreviewButton && (isOnline || isCustomImage || isLocalImage))
          _ActionButton(
            label: '全屏欣赏',
            icon: Icons.fullscreen_rounded,
            secondary: true,
            onTap: () => context.push(AppRoutes.kWallpaperPreview),
          ),

        if (isOnline || isCustomImage || isLocalImage)
          _ActionButton(
            label: _busy ? '处理中…' : '下载壁纸',
            icon: Icons.download_rounded,
            secondary: true,
            onTap: _busy ? null : _saveWallpaper,
          ),

        Padding(
          padding: EdgeInsets.fromLTRB(16.sp, 10.sp, 16.sp, 0),
          child: Text(
            '提示：在线壁纸与动态壁纸来自第三方接口，个别图源可能失效或变慢 —— 换一个图源即可；'
            '动态壁纸的内置公开源不稳定时，可在「动态壁纸源 → 自定义接口」里填自己的接口'
            '（支持 {page} / {tag} / {random} 占位符，响应里有 url 和 cover 即可）。'
            '自动换壁纸由「设置 → 后台任务」统一调度，熄屏期间错过的会在下次进入应用时补上。',
            style: AppTextStyles.t14W500.copyWith(color: tvTheme.secondaryTextColor),
          ),
        ),
      ],
    );
  }
}

/// 纯色取色板。
///
/// 遥控器上用「一行可换的选项条」选十几号颜色体验很差，所以做成网格：
/// 方向键在网格里走动，确认键选中（iTab 的纯色页签也是网格卡片）。
class _ColorGrid extends StatelessWidget {
  const _ColorGrid({required this.colors, required this.selected, required this.onSelected});

  final List<Color> colors;
  final Color selected;
  final ValueChanged<Color> onSelected;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final selectedIndex = BackgroundPresets.closestSolidIndex(selected);
    final hasSelection = selected.toARGB32() == BackgroundPresets.solidColors[selectedIndex].toARGB32();

    return Padding(
      padding: EdgeInsets.fromLTRB(16.sp, 8.sp, 16.sp, 8.sp),
      child: Wrap(
        spacing: 10.sp,
        runSpacing: 10.sp,
        children: [
          for (final (index, color) in colors.indexed)
            DpadFocusable(
              effects: [DpadScaleEffect(scale: 1.12)],
              onSelect: () => onSelected(color),
              builder: (context, state, child) {
                final isSelected = hasSelection && index == selectedIndex;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  width: 56.sp,
                  height: 56.sp,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(12.sp),
                    border: Border.all(
                      color: state.focused
                          ? tvTheme.focusColor
                          : (isSelected ? tvTheme.focusColor.withValues(alpha: 0.6) : Colors.white24),
                      width: state.focused ? 4.sp : 2.sp,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check_rounded,
                          size: 24.sp,
                          color: ThemeData.estimateBrightnessForColor(color) == Brightness.dark
                              ? Colors.white
                              : Colors.black87,
                        )
                      : null,
                );
              },
              child: const SizedBox.shrink(),
            ),
        ],
      ),
    );
  }
}

/// 「标签 + 值」一行，用来回显手填的链接 / 当前地址。
class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.sp, 6.sp, 16.sp, 6.sp),
      child: Row(
        children: [
          Icon(icon, size: 22.sp, color: tvTheme.secondaryTextColor),
          SizedBox(width: 10.sp),
          Text('$label：', style: AppTextStyles.t16W500.copyWith(color: tvTheme.secondaryTextColor)),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.t14W500.copyWith(color: tvTheme.primaryTextColor),
            ),
          ),
        ],
      ),
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
            child: _thumbnail(image, isVideo, tvTheme),
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

  /// 视频背景没有可用的静态缩略图时用图标占位；在线视频有封面就显示封面。
  Widget _thumbnail(ImageProvider<Object>? image, bool isVideo, TvThemeData tvTheme) {
    if (isVideo) {
      final cover = config.networkVideoCover;
      if (cover != null && cover.isNotEmpty) {
        return Image.network(
          cover,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _videoPlaceholder(tvTheme),
        );
      }
      return _videoPlaceholder(tvTheme);
    }
    if (image != null) return Image(image: image, fit: BoxFit.cover);
    // 纯色 / 渐变模式没有图片，用实际颜色给个色块。
    if (config.source == BackgroundSource.color) return ColoredBox(color: config.solidColor);
    if (config.source == BackgroundSource.gradient) {
      return DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(colors: config.gradientColors)));
    }
    return Icon(Icons.image_outlined, size: 32.sp, color: tvTheme.secondaryTextColor);
  }

  Widget _videoPlaceholder(TvThemeData tvTheme) {
    return Center(child: Icon(Icons.movie_rounded, size: 32.sp, color: tvTheme.secondaryTextColor));
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
        return '纯色 · #${config.solidColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
      case BackgroundSource.gradient:
        return '渐变底色 · ${config.gradientColors.length} 色';
      case BackgroundSource.localImage:
        return '本机图片 · ${tail(config.localImagePath)}';
      case BackgroundSource.assetImage:
        return '内置图片 · ${tail(config.assetImagePath)}';
      case BackgroundSource.localVideo:
        return '本机视频 · ${tail(config.localVideoPath)}';
      case BackgroundSource.assetVideo:
        return '内置视频 · ${tail(config.assetVideoPath)}';
      case BackgroundSource.networkVideo:
        if (config.customVideoUrl.isNotEmpty && config.customVideoUrl == config.networkVideoUrl) {
          return '自定义视频链接';
        }
        final source = BackgroundVideoSources.at(config.videoSourceIndex);
        final tags = BackgroundVideoSources.tagNames(config.videoSourceIndex);
        final tag = tags.isEmpty ? '' : ' · ${tags[config.videoTagIndex.clamp(0, tags.length - 1)]}';
        return '在线动态壁纸 · ${source.name}$tag';
      case BackgroundSource.networkImage:
        if (config.customImageUrl.isNotEmpty && config.customImageUrl == config.networkImageUrl) {
          return '自定义图片链接';
        }
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
