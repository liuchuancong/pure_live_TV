import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/shared/widgets/tv_settings_switch_tile.dart';

class GeneralSettingsSectionPage extends ConsumerWidget {
  const GeneralSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appSettingsControllerProvider);
    final app = ref.read(appSettingsControllerProvider.notifier);
    final exitState = ref.watch(exitSettingsControllerProvider);
    final exit = ref.read(exitSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: '关注自动刷新',
          subtitle: '关注页自动刷新间隔',
          icon: Icons.refresh_rounded,
          options: _refreshLabels,
          index: _refreshIndex(appState.autoRefreshTime),
          onChanged: (i) => app.update(appState.copyWith(autoRefreshTime: _refreshMinutes(i))),
        ),
        TvSettingsSwitchTile(
          title: '密集收藏布局',
          subtitle: '关注页使用更紧凑的卡片布局',
          icon: Icons.view_comfy_rounded,
          value: appState.enableDenseFavorites,
          onChanged: (v) => app.update(appState.copyWith(enableDenseFavorites: v)),
        ),
        TvSettingsSwitchTile(
          title: '后台播放',
          subtitle: '退出直播间后继续播放声音',
          icon: Icons.surround_sound_rounded,
          value: appState.enableBackgroundPlay,
          onChanged: (v) => app.update(appState.copyWith(enableBackgroundPlay: v)),
        ),
        TvSettingsSwitchTile(
          title: '屏幕常亮',
          subtitle: '观看时屏幕不会自动熄灭',
          icon: Icons.brightness_medium_rounded,
          value: appState.enableScreenKeepOn,
          onChanged: (v) => app.update(appState.copyWith(enableScreenKeepOn: v)),
        ),
        TvSettingsSwitchTile(
          title: '自动检查更新',
          subtitle: '启动时检查新版本',
          icon: Icons.system_update_rounded,
          value: appState.enableAutoCheckUpdate,
          onChanged: (v) => app.update(appState.copyWith(enableAutoCheckUpdate: v)),
        ),
        TvSettingsSwitchTile(
          title: '默认全屏',
          subtitle: '进入直播间时默认全屏播放',
          icon: Icons.fullscreen_rounded,
          value: appState.enableFullScreenDefault,
          onChanged: (v) => app.update(appState.copyWith(enableFullScreenDefault: v)),
        ),
        TvSettingsSwitchTile(
          title: '退出不询问',
          subtitle: '按返回键直接退出应用，不再弹出确认',
          icon: Icons.logout_rounded,
          value: exitState.dontAskExit,
          onChanged: (v) => exit.setDontAskExit(v),
        ),
        TvSettingsOptionTile(
          title: '自动关机倒计时',
          subtitle: '无操作一段时间后自动关闭应用',
          icon: Icons.timer_outlined,
          options: const ['关闭', '30 分钟', '60 分钟', '90 分钟', '120 分钟'],
          index: _shutDownIndex(exitState),
          onChanged: (i) => exit.updateConfig(_shutDownConfig(exitState, i)),
        ),
      ],
    );
  }

  static const _refreshLabels = ['关闭', '1 分钟', '3 分钟', '5 分钟', '10 分钟', '30 分钟'];

  static int _refreshIndex(int minutes) {
    return switch (minutes) {
      0 => 0,
      1 => 1,
      3 => 2,
      5 => 3,
      10 => 4,
      30 => 5,
      _ => 2,
    };
  }

  static int _refreshMinutes(int index) {
    return switch (index) {
      0 => 0,
      1 => 1,
      2 => 3,
      3 => 5,
      4 => 10,
      5 => 30,
      _ => 3,
    };
  }

  static int _shutDownIndex(ExitSettingsModel exitState) {
    if (!exitState.enableAutoShutDownTime) return 0;
    return switch (exitState.autoShutDownTime) {
      30 => 1,
      60 => 2,
      90 => 3,
      _ => 4,
    };
  }

  static ExitSettingsModel _shutDownConfig(ExitSettingsModel exitState, int index) {
    final minutes = switch (index) {
      0 => 120,
      1 => 30,
      2 => 60,
      3 => 90,
      _ => 120,
    };
    return exitState.copyWith(enableAutoShutDownTime: index != 0, autoShutDownTime: minutes);
  }
}
