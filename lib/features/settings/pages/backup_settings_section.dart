import 'dart:async';
import 'dart:io';

import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/remote/models/server_state.dart';
import 'package:pure_live/features/remote/tv_remote_receiver.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/services/log_settings/log_settings_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Backup and restore, in the mobile page's grouping.
///
/// cloud backup → WebDAV and device sync, local backup → create and restore, backup settings →
/// the backup directory, log management → the local log. The mobile Firebase row is
/// deliberately absent.
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

  /// Lists the backup files of the default/configured directory, newest first.
  Future<List<File>> _listBackups() async {
    final directory = await ref.read(backupControllerProvider.notifier).resolveBackupDirectory();
    final files = <File>[];
    if (directory.existsSync()) {
      for (final entity in directory.listSync()) {
        if (entity is! File) continue;
        if (!BackupController.isBackupFileName(entity.uri.pathSegments.last.toLowerCase())) continue;
        files.add(entity);
      }
    }
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    return files;
  }

  static String _describe(File file) {
    final stat = file.statSync();
    final name = file.uri.pathSegments.last;
    final size = stat.size;
    final sizeText = size < 1024
        ? '$size B'
        : size < 1024 * 1024
        ? '${(size / 1024).toStringAsFixed(1)} KB'
        : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    final modified = stat.modified;
    String two(int value) => value.toString().padLeft(2, '0');
    final timeText =
        '${modified.year}-${two(modified.month)}-${two(modified.day)} ${two(modified.hour)}:${two(modified.minute)}';
    return '$name · $sizeText · $timeText';
  }

  /// One dialog per action: the user picks a backup file, the action runs on it.
  Future<void> _pickBackup({required bool restore}) async {
    if (_busy) return;
    final files = await _listBackups();
    if (!mounted) return;
    if (files.isEmpty) {
      setState(() => _result = i18nOr('backup_list_empty', 'No local backup found'));
      return;
    }
    final picked = await TvDialogUtils.showSelect<File>(
      context: context,
      title: restore ? i18n('recover_backup') : i18n('delete'),
      items: [for (final file in files) TvSelectItem(value: file, title: _describe(file))],
    );
    if (picked == null || !mounted) return;

    setState(() {
      _busy = true;
      _result = i18n('ui_loading');
    });
    if (restore) {
      final ok = await ref.read(backupControllerProvider.notifier).recover(picked);
      if (!mounted) return;
      setState(() {
        _busy = false;
        _result = ok ? i18n('recover_backup_success') : i18n('recover_backup_failed');
      });
    } else {
      try {
        if (picked.existsSync()) picked.deleteSync();
        if (!mounted) return;
        setState(() {
          _busy = false;
          _result = i18n('delete_success');
        });
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _result = '$error';
        });
      }
    }
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

  @override
  Widget build(BuildContext context) {
    final ServerState? server = ref.watch(tvRemoteReceiverProvider).value;
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
              subtitle: server?.isRunning == true ? server!.serverUrl : i18n('remote_sync_subtitle'),
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
            TvSettingsOptionTile(
              title: i18n('recover_backup'),
              subtitle: i18n('recover_backup_subtitle'),
              icon: Remix.file_upload_line,
              options: [i18n('ui_choose')],
              index: 0,
              onChanged: (_) => _pickBackup(restore: true),
            ),
            TvSettingsOptionTile(
              title: i18nOr('delete_backup', 'Delete backup'),
              subtitle: i18nOr('delete_backup_subtitle', 'Pick a local backup file and delete it'),
              icon: Remix.delete_bin_line,
              options: [i18n('ui_choose')],
              index: 0,
              onChanged: (_) => _pickBackup(restore: false),
            ),
          ],
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
