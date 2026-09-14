import 'dart:io';
import 'dart:async';
import 'package:pure_live/core/exports/package_export.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_live/modules/settings/tv_settings_option_tile.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:pure_live/services/back_up/backup_controller.dart';



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
          title: '导出配置到本机',
          subtitle: '将全部设置导出到应用文档目录 pure_live_backup.json',
          icon: Icons.upload_file_rounded,
          options: const ['导出'],
          index: 0,
          onChanged: (_) async {
            final backup = ref.read(backupControllerProvider.notifier);
            final ok = backup.backup(await _backupFile('pure_live_backup.json'));
            setState(() => _lastResult = ok ? '导出成功' : '导出失败');
          },
        ),
        TvSettingsOptionTile(
          title: '从本机导入配置',
          subtitle: '读取应用文档目录 pure_live_backup.json 并恢复',
          icon: Icons.download_rounded,
          options: const ['导入'],
          index: 0,
          onChanged: (_) async {
            final backup = ref.read(backupControllerProvider.notifier);
            final file = await _backupFile('pure_live_backup.json');
            final ok = file.existsSync() && await backup.recover(file);
            setState(() => _lastResult = ok ? '导入成功' : '导入失败或文件不存在');
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
