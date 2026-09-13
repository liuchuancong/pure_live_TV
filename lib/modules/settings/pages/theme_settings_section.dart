import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/theme/tv_theme_controller.dart';
import 'package:pure_live/widgets/tv_settings_slider_tile.dart';
import 'package:pure_live/widgets/tv_settings_switch_tile.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class ThemeSettingsSectionPage extends ConsumerWidget {
  const ThemeSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tvThemeController = ref.read(tvThemeControllerProvider.notifier);
    final currentTheme = ref.watch(tvThemeControllerProvider);
    final themeState = ref.watch(themeSettingsControllerProvider);
    final theme = ref.read(themeSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: 8.sp, left: 16.sp),
          child: Text(
            'TV 主题',
            style: TextStyle(fontSize: 14.sp, color: context.tvTheme.secondaryTextColor),
          ),
        ),
        ...tvThemeController.themes.map(
          (t) => TvSettingsOptionTile(
            title: t.name,
            subtitle: currentTheme.id == t.id ? '当前主题' : null,
            icon: Icons.palette_outlined,
            options: const ['使用'],
            index: 0,
            onChanged: (_) => tvThemeController.switchTheme(t),
          ),
        ),
        SizedBox(height: 8.sp),
        TvSettingsSwitchTile(
          title: '动态主题色',
          subtitle: '根据封面自动取色',
          icon: Icons.colorize_rounded,
          value: themeState.enableDynamicTheme,
          onChanged: (v) => theme.updateSettings(themeState.copyWith(enableDynamicTheme: v)),
        ),
        TvSettingsSliderTile(
          title: '横向卡片间距',
          icon: Icons.swap_horiz_rounded,
          value: themeState.crossAxisSpacing,
          min: 0,
          max: 24,
          displayValue: themeState.crossAxisSpacing.toStringAsFixed(0),
          onChanged: (v) => theme.updateSettings(themeState.copyWith(crossAxisSpacing: v)),
        ),
        TvSettingsSliderTile(
          title: '纵向卡片间距',
          icon: Icons.swap_vert_rounded,
          value: themeState.mainAxisSpacing,
          min: 0,
          max: 24,
          displayValue: themeState.mainAxisSpacing.toStringAsFixed(0),
          onChanged: (v) => theme.updateSettings(themeState.copyWith(mainAxisSpacing: v)),
        ),
      ],
    );
  }
}
