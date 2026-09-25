import 'dart:io';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/app/router/web_router.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/services/log_settings/log_settings_controller.dart';

/// Backup and restore, in the mobile page's grouping.
///
/// cloud backup → WebDAV and device sync, local backup → create and restore, backup settings →
/// the backup directory, log management → the local log. The mobile Firebase row is
/// absent by design.
class BackupSettingsSectionPage extends ConsumerStatefulWidget {
  const BackupSettingsSectionPage({super.key});

  @override
  ConsumerState<BackupSettingsSectionPage> createState() => BackupSettingsSectionPageState();
}

class BackupSettingsSectionPageState extends ConsumerState<BackupSettingsSectionPage> {
  String _result = '';
  bool _busy = false;
  bool _logApplying = false;
  bool _logFailed = false;

  /// `setLoggingEnabled` reports whether the log sink could actually be opened;
  /// swallowing that bool made a failed enable look like a successful one.
  Future<void> _toggleLog(bool enabled) async {
    setState(() {
      _logApplying = true;
      _logFailed = false;
    });
    final ok = await ref.read(logSettingsControllerProvider.notifier).setLoggingEnabled(enabled);
    if (!mounted) return;
    setState(() {
      _logApplying = false;
      _logFailed = !ok;
    });
  }

  /// Writes a timestamped backup into the resolved directory (the configured
  /// backup directory, or the app documents directory when none was chosen).
  ///
  /// `.txt`, named `purelive_<date>.txt` — the mobile app's own backup file.
  Future<void> _createBackup() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _result = i18n('ui_loading');
    });
    final notifier = ref.read(backupControllerProvider.notifier);
    final directory = await notifier.resolveBackupDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}${BackupController.backupFileName(DateTime.now())}');
    final ok = notifier.backup(file);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = ok ? '${i18n('ui_exported')}: ${file.path}' : i18n('ui_export_failed');
    });
  }

  @override
  Widget build(BuildContext context) {
    final logState = ref.watch(logSettingsControllerProvider);
    final theme = context.tvTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // cloud backup — device sync is the cloud path now that WebDAV is gone.
        TvSettingsGroupTitle(title: i18n('cloud_backup')),
        TvSettingsCard(
          children: [
            TvSettingsNavTile(
              title: i18n('remote_sync'),
              subtitle: i18n('remote_sync_subtitle'),
              icon: Icons.devices_other_rounded,
              onTap: () => const DeviceSyncRoute().push(context),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // local backup: create, then restore/delete through a file picker dialog
        TvSettingsGroupTitle(title: i18n('local_backup')),
        TvSettingsCard(
          children: [
            TvSettingsOptionTile(
              title: i18n('create_backup'),
              subtitle: i18n('create_backup_subtitle'),
              icon: Remix.save_3_line,
              options: [i18n('create_backup')],
              index: 0,
              onChanged: (_) => _createBackup(),
            ),
            // Restore and delete live in the backup list: one row
            // per file, its tap opens the restore/delete menu.
            TvSettingsNavTile(
              title: i18n('local_backup'),
              subtitle: i18nOr('backup_manage_subtitle', '备份列表 · 恢复或删除'),
              icon: Icons.folder_outlined,
              onTap: () => const LocalBackupRoute().push(context),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // The same files, without a file system to reach: the phone page downloads
        // a backup and uploads one back, which is the only way in for a file that
        // never landed in this device's backup folder.
        TvSettingsGroupTitle(title: i18n('backup_browser_title')),
        Center(child: RemoteSyncQrCard(width: 280, route: WebRemoteRouter.sync)),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Text(
            i18n('backup_browser_hint'),
            style: TextStyle(fontSize: 14.sp, color: theme.secondaryTextColor),
          ),
        ),
        SizedBox(height: 16.h),
        // log management
        TvSettingsGroupTitle(title: i18n('log_manage')),
        TvSettingsCard(
          children: [
            TvSettingsSwitchTile(
              title: i18n('enable_local_log'),
              subtitle: _logFailed
                  ? i18n('local_log_apply_failed')
                  : _logApplying
                  ? i18n('local_log_applying')
                  : i18n('enable_local_log_desc'),
icon: logState.storedEnableLog ? Icons.receipt_long_outlined : Icons.description_outlined,
              value: logState.storedEnableLog,
              onChanged: _logApplying ? null : _toggleLog,
            ),
            TvSettingsOptionTile(
              title: i18n('view_logs_in_browser'),
              subtitle: i18n('open_log_dir_desc'),
              icon: Remix.global_line,
              options: [i18n('ui_show')],
              index: 0,
              onChanged: (_) => const LogViewerRoute().push(context),
            ),
          ],
        ),
        if (_result.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.sp, top: 10.sp),
            child: Text(_result, style: AppTextStyles.t16W500.copyWith(color: theme.focusColor)),
          ),
      ],
    );
  }
}
