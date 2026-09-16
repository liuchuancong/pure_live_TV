import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/remote/models/server_state.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/services/log_settings/log_settings_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Backup and restore, in the mobile page's grouping.
///
/// 云端备份 → WebDAV and device sync, 本地备份 → create and restore, 备份设置 →
/// the backup directory, 日志管理 → the local log. The mobile Firebase row is
/// deliberately absent.
class BackupSettingsSectionPage extends ConsumerStatefulWidget {
  const BackupSettingsSectionPage({super.key});

  @override
  ConsumerState<BackupSettingsSectionPage> createState() => BackupSettingsSectionPageState();
}

class BackupSettingsSectionPageState extends ConsumerState<BackupSettingsSectionPage> {
  static const String _prefix = 'pure_live_backup';

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

  String get _directoryLabel {
    final configured = ref.read(backupControllerProvider.notifier).backupDirectory;
    return configured.isEmpty ? i18n('please_set_backup_directory') : configured;
  }

  /// Writes a timestamped backup into the resolved directory (the configured
  /// 备份目录, or the app documents directory when none was chosen).
  Future<void> _createBackup() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _result = i18n('ui_loading');
    });
    final notifier = ref.read(backupControllerProvider.notifier);
    final directory = await notifier.resolveBackupDirectory();
    final stamp = _stamp(DateTime.now());
    final file = File('${directory.path}${Platform.pathSeparator}${_prefix}_$stamp.json');
    final ok = notifier.backup(file);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _result = ok ? '${i18n('ui_exported')}: ${file.path}' : i18n('ui_export_failed');
    });
  }

  Future<void> _chooseDirectory() async {
    final String? path = await FilePicker.getDirectoryPath();
    if (path == null || path.isEmpty) return;
    await ref.read(backupControllerProvider.notifier).setBackupDirectory(path);
    if (!mounted) return;
    setState(() => _result = '${i18n('backup_directory')}: $path');
  }

  /// The log is served by the LAN remote; a TV has no browser, so the row shows
  /// the address to open on a phone or a PC.
  Future<void> _showLogUrl() async {
    final notifier = ref.read(tvRemoteReceiverProvider.notifier);
    ServerState? server = ref.read(tvRemoteReceiverProvider).value;
    if (server?.isRunning != true) {
      await notifier.startServer();
      if (!mounted) return;
      server = ref.read(tvRemoteReceiverProvider).value;
    }
    if (!mounted) return;
    final url = server?.serverUrl ?? '';
    setState(() {
      _result = url.isEmpty
          ? (server?.error ?? i18n('remote_service_unavailable'))
          : '${i18n('view_logs_in_browser')}: $url/api/log/download';
    });
  }

  static String _stamp(DateTime time) {
    String two(int value) => value.toString().padLeft(2, '0');
    return '${time.year}${two(time.month)}${two(time.day)}_${two(time.hour)}${two(time.minute)}${two(time.second)}';
  }

  @override
  Widget build(BuildContext context) {
    final ServerState? server = ref.watch(tvRemoteReceiverProvider).value;
    final logState = ref.watch(logSettingsControllerProvider);
    final theme = context.tvTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 云端备份
        TvSettingsGroupTitle(title: i18n('cloud_backup')),
        TvSettingsCard(
          children: [
            TvSettingsNavTile(
              title: i18n('webdav'),
              subtitle: i18n('backup_to_webdav'),
              icon: Remix.cloud_line,
              onTap: () => context.push(AppRoutes.kWebDavPage),
            ),
            TvSettingsNavTile(
              title: i18n('remote_sync'),
              subtitle: server?.isRunning == true ? server!.serverUrl : i18n('remote_sync_subtitle'),
              icon: Icons.devices_other_rounded,
              onTap: () => context.push(AppRoutes.kSettingsDeviceSync),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // 本地备份
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
            TvSettingsNavTile(
              title: i18n('recover_backup'),
              subtitle: i18n('recover_backup_subtitle'),
              icon: Remix.history_line,
              onTap: () => context.push(AppRoutes.kSettingsLocalBackup),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // 备份设置
        TvSettingsGroupTitle(title: i18n('backup_settings')),
        TvSettingsCard(
          children: [
            TvSettingsOptionTile(
              title: i18n('backup_directory'),
              subtitle: _directoryLabel,
              icon: Remix.folder_open_line,
              options: [i18n('ui_choose')],
              index: 0,
              onChanged: (_) => _chooseDirectory(),
            ),
          ],
        ),
        SizedBox(height: 16.h),
        // 日志管理
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
              icon: Icons.description_outlined,
              value: logState.storedEnableLog,
              onChanged: _logApplying ? null : _toggleLog,
            ),
            TvSettingsOptionTile(
              title: i18n('view_logs_in_browser'),
              subtitle: i18n('open_log_dir_desc'),
              icon: Remix.global_line,
              options: [i18n('ui_show')],
              index: 0,
              onChanged: (_) => _showLogUrl(),
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
