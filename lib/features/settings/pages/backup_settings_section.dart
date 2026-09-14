import 'dart:io';
import 'dart:async';
import 'package:pure_live/exports/package_export.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';



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
        TvSettingsOptionTile(
          title: i18n('ui_export_configuration_to_this_device'),
          subtitle: i18n('ui_export_all_settings_to_pure_live_backup_json_in'),
          icon: Icons.upload_file_rounded,
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
          icon: Icons.download_rounded,
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
            child: Text(_lastResult, style: TextStyle(fontSize: 14.sp, color: context.tvTheme.focusColor)),
          ),
      ],
    );
  }
}
