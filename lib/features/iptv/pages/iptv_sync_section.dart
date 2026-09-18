import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/features/iptv/services/iptv_sync_engine.dart';
import 'package:pure_live/shared/data/db_service.dart';
import 'package:pure_live/services/iptv_settings/iptv_settings_controller.dart';

/// IPTV auto-sync page: the global switch, the interval and the batch sync of
/// every source whose per-item auto-sync is on.
class IptvSyncSectionPage extends ConsumerStatefulWidget {
  const IptvSyncSectionPage({super.key});

  @override
  ConsumerState<IptvSyncSectionPage> createState() => _IptvSyncSectionPageState();
}

class _IptvSyncSectionPageState extends ConsumerState<IptvSyncSectionPage> {
  /// Interval choices offered by the desktop interval dialog.
  static const List<int> _intervalOptions = <int>[2, 6, 12, 24, 48, 72];

  String _status = '';
  bool _busy = false;

  IptvSettingsController get _settings => ref.read(iptvSettingsControllerProvider.notifier);

  Future<void> _syncAllProviders() async {
    if (_busy) return;
    final targets = (await DbService.to.db.getAllProviders())
        .where((provider) => provider.isAutoUpdate)
        .toList(growable: false);
    if (targets.isEmpty) {
      setState(() => _status = i18n('manage_page_empty_tip'));
      return;
    }
    setState(() => _busy = true);
    try {
      var failures = 0;
      for (final provider in targets) {
        final ok = await IptvSyncEngine.instance.syncPlaylist(provider, showTips: false);
        if (!ok) failures++;
      }
      if (mounted) setState(() => _status = i18n(failures == 0 ? 'manage_page_success' : 'manage_page_failed'));
    } catch (error) {
      debugPrint('IPTV batch sync failure: $error');
      if (mounted) setState(() => _status = i18n('manage_page_failed'));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _selectInterval(int hours) {
    _settings.setAutoSyncHoursInterval(hours);
    setState(() => _status = i18n('settings_saved'));
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;
    final settings = ref.watch(iptvSettingsControllerProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(child: RemoteSyncQrCard(width: 280)),
        SizedBox(height: 24.h),
        TvSettingsGroupTitle(title: i18n('auto_sync_settings')),
        TvSettingsCard(
          children: [
            TvSettingsSwitchTile(
              title: i18n('auto_sync_title'),
              subtitle: i18n('auto_sync_desc'),
              icon: Icons.sync_rounded,
              value: settings.isAutoSyncEnabled,
              onChanged: (value) => _settings.setAutoSyncEnabled(value),
            ),
            if (settings.isAutoSyncEnabled)
              TvSettingsMenuTile<int>(
                title: i18n('sync_interval_title'),
                subtitle: i18n(
                  'sync_interval_hours',
                  args: {'hour': '${settings.autoSyncHoursInterval}'},
                ),
                icon: Icons.schedule_rounded,
                value: settings.autoSyncHoursInterval,
                valueMap: {
                  for (final hours in _intervalOptions) hours: '$hours ${i18n('hours')}',
                },
                onChanged: _selectInterval,
              ),
            TvSettingsOptionTile(
              title: i18n('sync'),
              subtitle: i18n('iptv_sync_all_desc'),
              icon: Icons.cloud_sync_outlined,
              options: [i18n('sync')],
              index: 0,
              onChanged: _busy ? null : (_) => _syncAllProviders(),
            ),
          ],
        ),
        if (_status.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.w, top: 10.h),
            child: Text(_status, style: TextStyle(fontSize: 14.sp, color: theme.focusColor)),
          ),
      ],
    );
  }
}
