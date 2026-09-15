import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_model.dart';
import 'package:pure_live/player/utils/player_consts.dart';

/// Picture-in-picture danmaku settings.
///
/// Mirrors the desktop app's `PipDanmakuSettingsPage` rows and order; the
/// colour row uses the named palette instead of a free colour picker, which a
/// remote cannot drive.
class PipDanmakuSettingsSectionPage extends ConsumerWidget {
  const PipDanmakuSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(danmakuSettingsControllerProvider);
    final controller = ref.read(danmakuSettingsControllerProvider.notifier);
    void update(DanmakuSettingsModel Function(DanmakuSettingsModel) change) => controller.updateSettings(change(state));

    final colorNames = PlayerConsts.themeColors.keys.toList(growable: false);
    final colors = PlayerConsts.themeColors.values.toList(growable: false);
    final int colorIndex = colors.indexWhere((c) => c.toARGB32() == state.pipDanmakuColor).clamp(0, colors.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsSwitchTile(
          title: i18n('pip_danmaku_enable'),
          icon: Icons.picture_in_picture_alt_rounded,
          value: state.enablePipDanmaku,
          onChanged: (v) => update((s) => s.copyWith(enablePipDanmaku: v)),
        ),
        if (state.enablePipDanmaku) ...[
          TvSettingsSwitchTile(
            title: i18n('danmaku_no_emoji'),
            icon: Icons.emoji_emotions_outlined,
            value: state.pipDanmakuNoEmojiMode,
            onChanged: (v) => update((s) => s.copyWith(pipDanmakuNoEmojiMode: v)),
          ),
          TvSettingsSwitchTile(
            title: i18n('pip_danmaku_auto_scale'),
            icon: Icons.fit_screen_rounded,
            value: state.pipDanmakuAutoScale,
            onChanged: (v) => update((s) => s.copyWith(pipDanmakuAutoScale: v)),
          ),
          TvSettingsSwitchTile(
            title: i18n('pip_danmaku_original_color'),
            icon: Icons.palette_outlined,
            value: state.pipDanmakuUseOriginalColor,
            onChanged: (v) => update((s) => s.copyWith(pipDanmakuUseOriginalColor: v)),
          ),
          if (!state.pipDanmakuUseOriginalColor)
            TvSettingsOptionTile(
              title: i18n('pip_danmaku_color'),
              icon: Icons.color_lens_outlined,
              options: colorNames,
              index: colorIndex,
              onChanged: (i) => update((s) => s.copyWith(pipDanmakuColor: colors[i].toARGB32())),
            ),
          TvSettingsSliderTile(
            title: i18n('font_size'),
            icon: Icons.format_size_rounded,
            value: state.pipDanmakuFontSize,
            min: 8,
            max: 40,
            displayValue: state.pipDanmakuFontSize.toStringAsFixed(0),
            onChanged: (v) => update((s) => s.copyWith(pipDanmakuFontSize: v)),
          ),
          TvSettingsSliderTile(
            title: i18n('font_weight'),
            icon: Icons.format_bold_rounded,
            value: state.pipDanmakuFontWeight.toDouble(),
            min: 300,
            max: 900,
            step: 100,
            displayValue: '${state.pipDanmakuFontWeight}',
            onChanged: (v) => update((s) => s.copyWith(pipDanmakuFontWeight: v.round())),
          ),
          TvSettingsSliderTile(
            title: i18n('speed'),
            icon: Icons.speed_rounded,
            value: state.pipDanmakuSpeed,
            min: 20,
            max: 200,
            step: 5,
            displayValue: state.pipDanmakuSpeed.toStringAsFixed(0),
            onChanged: (v) => update((s) => s.copyWith(pipDanmakuSpeed: v)),
          ),
          TvSettingsSliderTile(
            title: i18n('opacity'),
            icon: Icons.opacity_rounded,
            value: state.pipDanmakuOpacity,
            min: 0.1,
            max: 1.0,
            step: 0.05,
            displayValue: '${(state.pipDanmakuOpacity * 100).toStringAsFixed(0)}%',
            onChanged: (v) => update((s) => s.copyWith(pipDanmakuOpacity: v)),
          ),
          TvSettingsSliderTile(
            title: i18n('danmaku_area'),
            icon: Icons.vertical_align_top_rounded,
            value: state.pipDanmakuArea,
            min: 0.1,
            max: 1.0,
            step: 0.05,
            displayValue: '${(state.pipDanmakuArea * 100).toStringAsFixed(0)}%',
            onChanged: (v) => update((s) => s.copyWith(pipDanmakuArea: v)),
          ),
          TvSettingsSliderTile(
            title: i18n('pip_danmaku_max_visible'),
            icon: Icons.view_agenda_outlined,
            value: state.pipDanmakuMaxVisibleCount.toDouble(),
            min: 1,
            max: 20,
            displayValue: '${state.pipDanmakuMaxVisibleCount}',
            onChanged: (v) => update((s) => s.copyWith(pipDanmakuMaxVisibleCount: v.round())),
          ),
          TvSettingsSliderTile(
            title: i18n('pip_danmaku_interval'),
            icon: Icons.timer_outlined,
            value: state.pipDanmakuEmitInterval,
            min: 0.1,
            max: 2.0,
            step: 0.05,
            displayValue: '${state.pipDanmakuEmitInterval.toStringAsFixed(2)}s',
            onChanged: (v) => update((s) => s.copyWith(pipDanmakuEmitInterval: v)),
          ),
          TvSettingsSwitchTile(
            title: i18n('danmaku_auto_fps'),
            subtitle: i18n('pip_danmaku_fps_policy_desc'),
            icon: Icons.slow_motion_video_rounded,
            value: state.pipDanmakuAutoFps,
            onChanged: (v) => update((s) => s.copyWith(pipDanmakuAutoFps: v)),
          ),
          if (!state.pipDanmakuAutoFps)
            TvSettingsSliderTile(
              title: i18n('danmaku_fps'),
              icon: Icons.monitor_heart_outlined,
              value: state.pipDanmakuFps.toDouble(),
              min: 15,
              max: 120,
              step: 5,
              displayValue: '${state.pipDanmakuFps}',
              onChanged: (v) => update((s) => s.copyWith(pipDanmakuFps: v.round())),
            ),
        ],
        TvSettingsMenuTile<void>(
          title: i18n('pip_danmaku_reset'),
          icon: Icons.restart_alt_rounded,
          onTap: () async {
            final confirmed = await TvDialogUtils.showConfirm(
              context: context,
              title: i18n('pip_danmaku_reset'),
              message: i18n('pip_danmaku_reset_confirm'),
            );
            if (confirmed != true) return;
            update(
              (s) => s.copyWith(
                pipDanmakuAutoScale: true,
                pipDanmakuNoEmojiMode: false,
                pipDanmakuUseOriginalColor: true,
                pipDanmakuColor: 0xFFFFFFFF,
                pipDanmakuFontSize: 12.0,
                pipDanmakuFontWeight: 500,
                pipDanmakuSpeed: 90.0,
                pipDanmakuOpacity: 0.9,
                pipDanmakuArea: 0.5,
                pipDanmakuMaxVisibleCount: 6,
                pipDanmakuEmitInterval: 0.35,
                pipDanmakuFps: 30,
                pipDanmakuAutoFps: true,
              ),
            );
          },
        ),
      ],
    );
  }
}
