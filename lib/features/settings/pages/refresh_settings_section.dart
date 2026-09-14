import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/tv_settings_switch_tile.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/refresh_config/refresh_config_controller.dart';

class RefreshSettingsSectionPage extends ConsumerWidget {
  const RefreshSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshState = ref.watch(refreshConfigControllerProvider);
    final refresh = ref.read(refreshConfigControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsSwitchTile(
          title: i18n('ui_auto_refresh_favorites_2'),
          subtitle: i18n('ui_refresh_the_online_status_of_favorites_periodica'),
          icon: Icons.refresh_rounded,
          value: refreshState.autoRefreshFavorite,
          onChanged: (v) => refresh.updateSettings(refreshState.copyWith(autoRefreshFavorite: v)),
        ),
        TvSettingsOptionTile(
          title: i18n('ui_refresh_interval'),
          subtitle: i18n('ui_auto_refresh_interval'),
          icon: Icons.timer_outlined,
          options: [i18n('ui_1_minute'), i18n('ui_2_minutes'), i18n('ui_5_minutes'), i18n('ui_10_minutes'), i18n('ui_30_minutes')],
          index: _intervalIndex(refreshState.autoRefreshInterval),
          onChanged: (i) => refresh.updateSettings(refreshState.copyWith(autoRefreshInterval: _intervalMinutes(i))),
        ),
        TvSettingsOptionTile(
          title: i18n('ui_max_concurrent_refreshes'),
          subtitle: i18n('ui_concurrent_refresh_requests_too_many_may_trigger'),
          icon: Icons.layers_rounded,
          options: const ['1', '2', '3', '4', '6', '8'],
          index: _concurrencyIndex(refreshState.maxConcurrentRefresh),
          onChanged: (i) => refresh.updateSettings(refreshState.copyWith(maxConcurrentRefresh: _concurrencyValue(i))),
        ),
      ],
    );
  }

  static int _intervalIndex(int minutes) => switch (minutes) {
    1 => 0,
    2 => 1,
    5 => 2,
    10 => 3,
    _ => 4,
  };
  static int _intervalMinutes(int index) => switch (index) {
    0 => 1,
    1 => 2,
    2 => 5,
    3 => 10,
    _ => 30,
  };
  static int _concurrencyIndex(int v) => switch (v) {
    1 => 0,
    2 => 1,
    3 => 2,
    4 => 3,
    6 => 4,
    _ => 5,
  };
  static int _concurrencyValue(int index) => switch (index) {
    0 => 1,
    1 => 2,
    2 => 3,
    3 => 4,
    4 => 6,
    _ => 8,
  };
}
