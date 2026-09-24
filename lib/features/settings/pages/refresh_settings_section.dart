import 'package:pure_live/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/refresh_config/refresh_config_controller.dart';

/// auto-refresh, in the mobile page's shape: one group, the interval hidden while
/// auto refresh is off, then the concurrency.
class RefreshSettingsSectionPage extends ConsumerWidget {
  const RefreshSettingsSectionPage({super.key});

  /// The reference's intervals (5–360 minutes).
  static const List<int> _intervalChoices = <int>[5, 10, 15, 20, 30, 45, 60, 90, 120, 180, 240, 360];

  static const List<int> _concurrencyChoices = <int>[1, 2, 3, 4, 6, 8];

  /// The stored interval is always offered.
  ///
  /// It used to be mapped through a five-entry table, so a value migrated from
  /// the mobile app (60, say) was displayed as 30 min while still storing 60 -
  /// the row showed something other than what the app used.
  static List<int> _intervalsFor(int stored) {
    if (_intervalChoices.contains(stored)) return _intervalChoices;
    return <int>[..._intervalChoices, stored]..sort();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final refreshState = ref.watch(refreshConfigControllerProvider);
    final refresh = ref.read(refreshConfigControllerProvider.notifier);
    final List<int> intervals = _intervalsFor(refreshState.autoRefreshInterval);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('home_cache_group')),
        TvSettingsCard(
          children: [
            TvSettingsSwitchTile(
              title: i18n('home_keep_alive'),
              subtitle: i18n('home_keep_alive_desc'),
              icon: Icons.cached_rounded,
              value: refreshState.homeKeepAlive,
              onChanged: (v) => refresh.updateSettings(refreshState.copyWith(homeKeepAlive: v)),
            ),
          ],
        ),
        SizedBox(height: 20.sp),
        TvSettingsGroupTitle(title: i18n('auto_refresh_settings')),
        TvSettingsCard(
          children: [
            TvSettingsSwitchTile(
              title: i18n('auto_refresh_follow'),
              subtitle: i18n('ui_refresh_the_online_status_of_favorites_periodica'),
              icon: refreshState.autoRefreshFavorite ? Icons.sync_rounded : Icons.sync_disabled_rounded,
              value: refreshState.autoRefreshFavorite,
              onChanged: (v) => refresh.updateSettings(refreshState.copyWith(autoRefreshFavorite: v)),
            ),
            // Hidden while the feature is off, exactly as on the mobile page.
            if (refreshState.autoRefreshFavorite)
              TvSettingsOptionTile(
                title: i18n('auto_refresh_interval'),
                subtitle: i18n('ui_auto_refresh_interval'),
                icon: Remix.time_line,
                options: [for (final int minutes in intervals) '$minutes ${i18n('minutes')}'],
                index: intervals.indexOf(refreshState.autoRefreshInterval).clamp(0, intervals.length - 1),
                onChanged: (i) => refresh.updateSettings(refreshState.copyWith(autoRefreshInterval: intervals[i])),
              ),
            TvSettingsOptionTile(
              title: i18n('max_concurrent_refresh'),
              subtitle: i18n('ui_concurrent_refresh_requests_too_many_may_trigger'),
              icon: Remix.server_line,
              options: [
                for (final int value in _concurrencyChoices)
                  value == 4 ? '$value · ${i18n('recommended')}' : '$value',
              ],
              index: _concurrencyChoices.indexOf(refreshState.maxConcurrentRefresh).clamp(0, _concurrencyChoices.length - 1),
              onChanged: (i) =>
                  refresh.updateSettings(refreshState.copyWith(maxConcurrentRefresh: _concurrencyChoices[i])),
            ),
          ],
        ),
      ],
    );
  }
}
