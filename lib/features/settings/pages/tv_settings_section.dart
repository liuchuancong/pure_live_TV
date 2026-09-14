import 'dart:async';

import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/services/display_mode/display_mode_service.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// TV 专属设置：屏幕/显示、睡眠省电，以及 TV 侧独有的功能入口。
///
/// 放在这里的都是「电视上才有意义」的开关；语言、更新检查这类通用项留在
/// 「通用设置」里，避免两处重复。
class TvSettingsSectionPage extends ConsumerWidget {
  const TvSettingsSectionPage({super.key});

  /// `AppSettingsModel.refreshRateMode` 的取值：'' 不干预 / 'auto' 系统默认 / 'high' 最高。
  static const List<String> _refreshRateValues = <String>['', 'auto', 'high'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appSettingsControllerProvider);
    final app = ref.read(appSettingsControllerProvider.notifier);

    final refreshIndex = _refreshRateValues.indexOf(appState.refreshRateMode.trim().toLowerCase());

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(text: i18nOr('ui_tv_display', '显示与屏幕')),
          TvSettingsCard(
            children: [
              TvSettingsSwitchTile(
                title: i18nOr('ui_tv_keep_screen_on', '屏幕常亮'),
                subtitle: i18nOr('ui_tv_keep_screen_on_desc', '观看时保持屏幕点亮，避免屏保打断'),
                icon: Icons.brightness_medium_rounded,
                value: appState.enableScreenKeepOn,
                onChanged: (v) => app.update(appState.copyWith(enableScreenKeepOn: v)),
              ),
              TvSettingsSwitchTile(
                title: i18nOr('ui_tv_fullscreen_default', '进入房间默认全屏'),
                subtitle: i18nOr('ui_tv_fullscreen_default_desc', '进入直播间时直接隐藏控制栏'),
                icon: Icons.fullscreen_rounded,
                value: appState.enableFullScreenDefault,
                onChanged: (v) => app.update(appState.copyWith(enableFullScreenDefault: v)),
              ),
              TvSettingsSwitchTile(
                title: i18nOr('ui_tv_splash_page', '显示启动页'),
                subtitle: i18nOr('ui_tv_splash_page_desc', '冷启动时展示启动画面'),
                icon: Icons.power_settings_new_rounded,
                value: appState.showSplashPage,
                onChanged: (v) => app.update(appState.copyWith(showSplashPage: v)),
              ),
              TvSettingsSwitchTile(
                title: i18nOr('ui_tv_rotate_screen', '允许旋转屏幕'),
                subtitle: i18nOr('ui_tv_rotate_screen_desc', '电视建议关闭，固定横屏更稳定'),
                icon: Icons.screen_rotation_rounded,
                value: appState.enableRotateScreen,
                onChanged: (v) => app.update(appState.copyWith(enableRotateScreen: v)),
              ),
              TvSettingsOptionTile(
                title: i18nOr('ui_tv_refresh_rate', '屏幕刷新率'),
                subtitle: i18nOr('ui_tv_refresh_rate_desc', '部分电视开启高刷后更流畅，也可能更费电'),
                icon: Icons.speed_rounded,
                options: [
                  i18nOr('ui_tv_refresh_none', '不干预'),
                  i18nOr('ui_tv_refresh_auto', '系统默认'),
                  i18nOr('ui_tv_refresh_high', '最高刷新率'),
                ],
                index: refreshIndex < 0 ? 0 : refreshIndex,
                onChanged: (index) {
                  final mode = _refreshRateValues[index];
                  app.update(appState.copyWith(refreshRateMode: mode));
                  unawaited(DisplayModeService.applyRefreshRateMode(mode));
                },
              ),
            ],
          ),
          _SectionLabel(text: i18nOr('ui_tv_sleep', '睡眠与省电')),
          TvSettingsCard(
            children: [
              TvSettingsSwitchTile(
                title: i18nOr('ui_tv_sleep_timer', '睡眠定时关闭'),
                subtitle: i18nOr('ui_tv_sleep_timer_desc', '到时后停止播放，适合睡前观看'),
                icon: Icons.bedtime_outlined,
                value: appState.enableAsmrSleepMode,
                onChanged: (v) => app.update(appState.copyWith(enableAsmrSleepMode: v)),
              ),
              if (appState.enableAsmrSleepMode)
                TvSettingsSliderTile(
                  title: i18nOr('ui_tv_sleep_minutes', '睡眠时长'),
                  icon: Icons.timer_outlined,
                  value: appState.asmrSleepMinutes.toDouble(),
                  min: 15,
                  max: 180,
                  step: 15,
                  displayValue: '${appState.asmrSleepMinutes} 分钟',
                  onChanged: (value) => app.update(appState.copyWith(asmrSleepMinutes: value.round())),
                ),
            ],
          ),
          _SectionLabel(text: i18nOr('ui_tv_shortcuts', 'TV 功能入口')),
          TvSettingsCard(
            children: [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 8.sp),
                child: Row(
                  children: [
                    Expanded(
                      child: TvButton(
                        title: i18nOr('ui_background_settings', '背景设置'),
                        icon: Icon(Icons.wallpaper_rounded, size: 22.sp),
                        size: TvButtonSize.medium,
                        onTap: () => context.go('${AppRoutes.kSettings}/wallpaper'),
                      ),
                    ),
                    SizedBox(width: 12.sp),
                    Expanded(
                      child: TvButton(
                        title: i18nOr('ui_lan_sync', '局域网同步'),
                        icon: Icon(Icons.lan_outlined, size: 22.sp),
                        size: TvButtonSize.medium,
                        isSecondary: true,
                        onTap: () => context.go('${AppRoutes.kSettings}/sync'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.sp, 12.sp, 16.sp, 0),
            child: Text(
              i18nOr(
                'ui_tv_settings_hint',
                '局域网同步可把关注、主题、弹幕屏蔽词、背景等设置同步到同一 Wi-Fi 下的手机或其他电视。',
              ),
              style: AppTextStyles.t14W500.copyWith(color: context.tvTheme.secondaryTextColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.sp, 8.sp, 16.sp, 6.sp),
      child: Text(
        text,
        style: AppTextStyles.t14W600.copyWith(color: context.tvTheme.secondaryTextColor),
      ),
    );
  }
}
