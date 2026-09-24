import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_model.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';
import 'package:pure_live/app/router/app_router.dart';

/// Danmaku appearance and filtering settings for the main player.
class DanmakuSettingsSectionPage extends ConsumerWidget {
  const DanmakuSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(danmakuSettingsControllerProvider);
    final controller = ref.read(danmakuSettingsControllerProvider.notifier);
    void update(DanmakuSettingsModel Function(DanmakuSettingsModel) change) => controller.updateSettings(change(state));

    // The single switch mirrors the legacy hideDanmaku flag so older backups
    // keep working.
    final enabled = state.enableDanmakuDisplay && !state.hideDanmaku;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('danmaku_templates')),
          TvSettingsCard(
            children: [
              TvSettingsSwitchTile(
                title: i18n('settings_danmaku_open'),
                subtitle: i18n('ui_show_danmaku_inside_live_rooms'),
                icon: Icons.subtitles_rounded,
                value: enabled,
                onChanged: (v) => update((s) => s.copyWith(enableDanmakuDisplay: v, hideDanmaku: !v)),
              ),
              TvSettingsNavTile(
                title: i18n('change_danmaku_font_family'),
                subtitle: state.danmakuFontFamilyName == 'Default'
                    ? i18n('font_default_subtitle')
                    : state.danmakuFontFamilyName,
                icon: Remix.font_size,
                onTap: () => const FontFamilyDanmakuRoute().push(context),
              ),
              TvSettingsSliderTile(
                title: i18n('danmaku_font_size'),
                icon: Icons.format_size_rounded,
                value: state.danmakuFontSize,
                min: 8,
                max: 40,
                displayValue: state.danmakuFontSize.toStringAsFixed(0),
                onChanged: (v) => update((s) => s.copyWith(danmakuFontSize: v)),
              ),
              TvSettingsSliderTile(
                title: i18n('danmaku_speed'),
                icon: Icons.speed_rounded,
                // px/s, the unit the engine's baseSpeed is in — the old 10-300 slider and
                // the panel's 4-32 "level" list disagreed with it (and with each other),
                // which is why moving the row barely changed what was on screen.
                value: state.danmakuSpeed,
                min: DanmakuSettingsModel.minSpeed,
                max: DanmakuSettingsModel.maxSpeed,
                step: 10,
                displayValue: '${state.danmakuSpeed.toStringAsFixed(0)} px/s',
                onChanged: (v) => update((s) => s.copyWith(danmakuSpeed: v)),
              ),
              TvSettingsSliderTile(
                title: i18n('danmaku_opacity'),
                icon: Icons.opacity_rounded,
                value: state.danmakuOpacity,
                min: 0.1,
                max: 1.0,
                step: 0.05,
                displayValue: '${(state.danmakuOpacity * 100).toStringAsFixed(0)}%',
                onChanged: (v) => update((s) => s.copyWith(danmakuOpacity: v)),
              ),
              TvSettingsSliderTile(
                title: i18n('danmaku_font_weight'),
                icon: Icons.format_bold_rounded,
                value: state.danmakuFontWeight.toDouble(),
                min: 300,
                max: 900,
                step: 100,
                displayValue: '${state.danmakuFontWeight}',
                onChanged: (v) => update((s) => s.copyWith(danmakuFontWeight: v.round())),
              ),
              TvSettingsSwitchTile(
                title: i18n('danmaku_stroke'),
                subtitle: i18n('danmaku_stroke_width'),
  icon: state.enableDanmakuStroke ? Icons.border_color_rounded : Icons.border_color_outlined,
                value: state.enableDanmakuStroke,
                onChanged: (v) => update((s) => s.copyWith(enableDanmakuStroke: v)),
              ),
              if (state.enableDanmakuStroke)
                TvSettingsSliderTile(
                  title: i18n('danmaku_stroke_width'),
                  icon: Icons.line_weight_rounded,
                  value: state.danmakuFontBorder,
                  min: 0,
                  max: 8,
                  step: 0.5,
                  displayValue: state.danmakuFontBorder.toStringAsFixed(1),
                  onChanged: (v) => update((s) => s.copyWith(danmakuFontBorder: v)),
                ),
              TvSettingsSliderTile(
                title: i18n('danmaku_area'),
                icon: Icons.vertical_align_top_rounded,
                value: state.danmakuArea,
                min: DanmakuSettingsModel.minArea,
                max: DanmakuSettingsModel.maxArea,
                step: 0.05,
                displayValue: '${(state.danmakuArea * 100).toStringAsFixed(0)}%',
                onChanged: (v) => update((s) => s.copyWith(danmakuArea: v)),
              ),
              // top/bottom inset are pixel insets in the engine (`topAreaDistance` /
              // `bottomAreaDistance`), not ratios: the page used to hand 0.0-0.8 to a
              // field measured in pixels, so the slider rendered as "no change".
              TvSettingsSliderTile(
                title: i18nOr('danmaku_area_top', '顶部距离'),
                icon: Icons.vertical_align_center_rounded,
                value: state.danmakuTopArea,
                min: DanmakuSettingsModel.minDistance,
                max: DanmakuSettingsModel.maxDistance,
                step: 10,
                displayValue: '${state.danmakuTopArea.toStringAsFixed(0)} px',
                onChanged: (v) => update((s) => s.copyWith(danmakuTopArea: v)),
              ),
              TvSettingsSliderTile(
                title: i18n('danmaku_area_bottom'),
                icon: Icons.vertical_align_bottom_rounded,
                value: state.danmakuBottomArea,
                min: DanmakuSettingsModel.minDistance,
                max: DanmakuSettingsModel.maxDistance,
                step: 10,
                displayValue: '${state.danmakuBottomArea.toStringAsFixed(0)} px',
                onChanged: (v) => update((s) => s.copyWith(danmakuBottomArea: v)),
              ),
              TvSettingsSwitchTile(
                title: i18n('danmaku_no_emoji'),
  icon: state.noEmojiMode ? Icons.emoji_emotions_rounded : Icons.emoji_emotions_outlined,
                value: state.noEmojiMode,
                onChanged: (v) => update((s) => s.copyWith(noEmojiMode: v)),
              ),
              TvSettingsSwitchTile(
                title: i18n('danmaku_auto_fps'),
                subtitle: i18n('danmaku_fps_policy_desc'),
                icon: Icons.slow_motion_video_rounded,
                value: state.danmakuAutoFps,
                onChanged: (v) => update((s) => s.copyWith(danmakuAutoFps: v)),
              ),
              if (!state.danmakuAutoFps)
                TvSettingsSliderTile(
                  title: i18n('danmaku_fps'),
                  icon: Icons.monitor_heart_outlined,
                  value: state.danmakuFps.toDouble(),
                  // The engine clamps to 30-240, so offering 15 here would be a slider
                  // position that never arrives.
                  min: 30,
                  max: 240,
                  step: 10,
                  displayValue: '${state.danmakuFps}',
                  onChanged: (v) => update((s) => s.copyWith(danmakuFps: v.round())),
                ),
            ],
          ),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('danmaku_repeat_filter')),
          TvSettingsCard(
            children: [
              TvSettingsSwitchTile(
                title: i18n('collapse_repeated_danmaku'),
                subtitle: i18n('collapse_repeated_danmaku_desc'),
  icon: state.collapseRepeatedDanmaku ? Icons.filter_alt_rounded : Icons.filter_alt_outlined,
                value: state.collapseRepeatedDanmaku,
                onChanged: (v) => update((s) => s.copyWith(collapseRepeatedDanmaku: v)),
              ),
              if (state.collapseRepeatedDanmaku)
                TvSettingsSliderTile(
                  title: i18n('repeated_danmaku_window'),
                  icon: Icons.timer_outlined,
                  value: state.repeatedDanmakuWindowSeconds.toDouble(),
                  min: 1,
                  max: 15,
                  displayValue: '${state.repeatedDanmakuWindowSeconds}s',
                  onChanged: (v) => update((s) => s.copyWith(repeatedDanmakuWindowSeconds: v.round())),
                ),
              TvSettingsSwitchTile(
                title: i18n('danmaku_similarity_filter_enable'),
                subtitle: i18n('danmaku_similarity_filter_desc'),
                icon: Icons.compare_arrows_rounded,
                value: state.enableDanmakuSimilarityFilter,
                onChanged: (v) => update((s) => s.copyWith(enableDanmakuSimilarityFilter: v)),
              ),
              if (state.enableDanmakuSimilarityFilter) ...[
                TvSettingsSliderTile(
                  title: i18n('danmaku_similarity_threshold'),
                  subtitle: i18n('danmaku_similarity_threshold_desc'),
                  icon: Icons.tune_rounded,
                  value: state.danmakuSimilarityThreshold.toDouble(),
                  min: 50,
                  max: 100,
                  step: 5,
                  displayValue: '${state.danmakuSimilarityThreshold}',
                  onChanged: (v) => update((s) => s.copyWith(danmakuSimilarityThreshold: v.round())),
                ),
                TvSettingsSliderTile(
                  title: i18n('danmaku_similarity_cache_duration'),
                  subtitle: i18n('danmaku_similarity_cache_duration_desc'),
                  icon: Icons.timer_outlined,
                  value: state.danmakuSimilarityCacheDuration.toDouble(),
                  min: 1,
                  max: 10,
                  displayValue: '${state.danmakuSimilarityCacheDuration}s',
                  onChanged: (v) => update((s) => s.copyWith(danmakuSimilarityCacheDuration: v.round())),
                ),
                TvSettingsSliderTile(
                  title: i18n('danmaku_similarity_max_cache_size'),
                  subtitle: i18n('danmaku_similarity_max_cache_size_desc'),
                  icon: Icons.storage_rounded,
                  value: state.danmakuSimilarityMaxCacheSize.toDouble(),
                  min: 20,
                  max: 300,
                  step: 10,
                  displayValue: '${state.danmakuSimilarityMaxCacheSize}',
                  onChanged: (v) => update((s) => s.copyWith(danmakuSimilarityMaxCacheSize: v.round())),
                ),
              ],
            ],
          ),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('danmaku_screen_interaction')),
          TvSettingsCard(
            children: [
              TvSettingsSwitchTile(
                title: i18n('danmaku_filter_bot'),
                icon: Icons.smart_toy_outlined,
                value: state.filterDouyuSuspectedAutomatedMessages,
                onChanged: (v) => update((s) => s.copyWith(filterDouyuSuspectedAutomatedMessages: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
