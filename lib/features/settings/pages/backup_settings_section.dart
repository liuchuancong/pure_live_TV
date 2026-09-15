import 'dart:io';
import 'dart:async';
import 'package:path_provider/path_provider.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/services/log_settings/log_settings_controller.dart';

class BackupSettingsSectionPage extends ConsumerStatefulWidget {
  const BackupSettingsSectionPage({super.key});

  @override
  ConsumerState<BackupSettingsSectionPage> createState() => BackupSettingsSectionPageState();
}

class BackupSettingsSectionPageState extends ConsumerState<BackupSettingsSectionPage> {
  String _lastResult = '';

  Future<File> _backupFile(String name) async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}${Platform.pathSeparator}$name');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The desktop backup page lists the cloud destinations first; WebDAV is
        // the one this app implements.
        TvSettingsNavTile(
          title: i18n('webdav'),
          subtitle: i18n('backup_to_webdav'),
          icon: Remix.cloud_line,
          onTap: () => context.push(AppRoutes.kWebDavPage),
        ),
        TvSettingsOptionTile(
          title: i18n('ui_export_configuration_to_this_device'),
          subtitle: i18n('ui_export_all_settings_to_pure_live_backup_json_in'),
          icon: Remix.file_download_line,
          options: [i18n('ui_export')],
          index: 0,
          onChanged: (_) async {
            final backup = ref.read(backupControllerProvider.notifier);
            final ok = backup.backup(await _backupFile('pure_live_backup.json'));
            setState(() => _lastResult = ok ? i18n('ui_exported') : i18n('ui_export_failed'));
          },
        ),
        TvSettingsOptionTile(
          title: i18n('ui_import_configuration_from_this_device'),
          subtitle: i18n('ui_read_pure_live_backup_json_from_the_app_document'),
          icon: Remix.file_upload_line,
          options: [i18n('import_action')],
          index: 0,
          onChanged: (_) async {
            final backup = ref.read(backupControllerProvider.notifier);
            final file = await _backupFile('pure_live_backup.json');
            final ok = file.existsSync() && await backup.recover(file);
            setState(() => _lastResult = ok ? i18n('ui_imported') : i18n('ui_import_failed_or_file_not_found'));
          },
        ),
        if (_lastResult.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(left: 16.sp, top: 8.sp),
            child: Text(
              _lastResult,
              style: TextStyle(fontSize: 14.sp, color: context.tvTheme.focusColor),
            ),
          ),
        // Local backup files, as on the desktop page's local-backup group.
        TvSettingsNavTile(
          title: i18n('local_backup'),
          subtitle: i18n('create_backup_subtitle'),
          icon: Icons.folder_copy_outlined,
          onTap: () => context.push(AppRoutes.kSettingsLocalBackup),
        ),
        SizedBox(height: 12.h),
        const _LocalLogCard(),
      ],
    );
  }
}

/// Local log file switch.
///
/// The file is the only way to inspect a release build on a TV; the LAN remote
/// reads the same in-memory buffer while logging is enabled.
class _LocalLogCard extends ConsumerStatefulWidget {
  const _LocalLogCard();

  @override
  ConsumerState<_LocalLogCard> createState() => _LocalLogCardState();
}

class _LocalLogCardState extends ConsumerState<_LocalLogCard> {
  bool _applying = false;
  bool _failed = false;

  Future<void> _toggle(bool enabled) async {
    setState(() {
      _applying = true;
      _failed = false;
    });
    final ok = await ref.read(logSettingsControllerProvider.notifier).setLoggingEnabled(enabled);
    if (!mounted) return;
    setState(() {
      _applying = false;
      _failed = !ok;
    });
  }

  @override
  Widget build(BuildContext context) {
    final logState = ref.watch(logSettingsControllerProvider);

    return TvSettingsCard(
      children: [
        TvSettingsSwitchTile(
          title: i18n('enable_local_log'),
          subtitle: _failed
              ? i18n('local_log_apply_failed')
              : _applying
              ? i18n('local_log_applying')
              : i18n('enable_local_log_desc'),
          icon: Icons.description_outlined,
          value: logState.storedEnableLog,
          onChanged: _applying ? null : _toggle,
        ),
      ],
    );
  }
}
