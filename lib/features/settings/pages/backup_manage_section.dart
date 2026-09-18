import 'dart:io';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';


/// Local backup management: create timestamped backups in the app documents
/// directory and restore or delete any of them.
class BackupManageSectionPage extends ConsumerStatefulWidget {
  const BackupManageSectionPage({super.key});

  @override
  ConsumerState<BackupManageSectionPage> createState() => BackupManageSectionPageState();
}

class BackupManageSectionPageState extends ConsumerState<BackupManageSectionPage> {
  static const _maxEntries = 20;

  final List<File> _files = [];
  String _result = '';
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refresh());
  }

  Future<Directory> _directory() => ref.read(backupControllerProvider.notifier).resolveBackupDirectory();

  Future<void> _refresh() async {
    final dir = await _directory();
    final files = <File>[];
    if (dir.existsSync()) {
      for (final entity in dir.listSync()) {
        if (entity is! File) continue;
        final name = entity.uri.pathSegments.last.toLowerCase();
        // `.txt` is the format now (the mobile app's); `.json` keeps an older TV backup
        // restorable, and both of this app's name prefixes are listed.
        if (!BackupController.isBackupFileName(name)) continue;
        files.add(entity);
      }
    }
    files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
    if (!mounted) return;
    setState(() {
      _files
        ..clear()
        ..addAll(files.take(_maxEntries));
    });
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (error) {
      if (mounted) setState(() => _result = '$error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createBackup() async {
    await _run(() async {
      final dir = await _directory();
      final file = File('${dir.path}${Platform.pathSeparator}${_buildName(DateTime.now())}');
      final ok = ref.read(backupControllerProvider.notifier).backup(file);
      await _refresh();
      if (mounted) setState(() => _result = ok ? i18n('save_success') : i18n('ui_export_failed'));
    });
  }

  Future<void> _restore(File file) async {
    await _run(() async {
      final ok = await ref.read(backupControllerProvider.notifier).recover(file);
      if (mounted) setState(() => _result = ok ? i18n('ui_imported') : i18n('ui_import_failed_or_file_not_found'));
    });
  }

  Future<void> _delete(File file) async {
    await _run(() async {
      if (file.existsSync()) file.deleteSync();
      await _refresh();
      if (mounted) setState(() => _result = i18n('delete_success'));
    });
  }

  static String _buildName(DateTime time) => BackupController.backupFileName(time);

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

  @override
  Widget build(BuildContext context) {
    final theme = context.tvTheme;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // local backup
          TvSettingsGroupTitle(title: i18n('local_backup')),
          TvSettingsCard(
            children: [
              TvSettingsOptionTile(
                title: i18n('create_backup'),
                subtitle: i18n('create_backup_subtitle'),
                icon: Icons.save_as_outlined,
                options: [i18n('create_backup')],
                index: 0,
                onChanged: (_) => _createBackup(),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          if (_files.isEmpty)
            TvSettingsCard(
              children: [
                TvSettingsOptionTile(
                  title: i18n('local_backup'),
                  subtitle: i18n('backup_settings'),
                  icon: Icons.folder_outlined,
                  options: [i18n('ui_refresh')],
                  index: 0,
                  onChanged: (_) => _refresh(),
                ),
              ],
            )
          else
            TvSettingsCard(
              children: [
                for (final file in _files) ...[
                  TvSettingsOptionTile(
                    title: _describe(file),
                    icon: Icons.restore_rounded,
                    options: [i18n('recover_backup')],
                    index: 0,
                    onChanged: (_) => _restore(file),
                  ),
                  TvSettingsOptionTile(
                    title: '${file.uri.pathSegments.last}  ${i18n('delete')}',
                    icon: Icons.delete_outline_rounded,
                    options: [i18n('delete')],
                    index: 0,
                    onChanged: (_) => _delete(file),
                  ),
                ],
              ],
            ),
          if (_result.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 10.h),
              child: Text(_result, style: TextStyle(fontSize: 14.sp, color: theme.focusColor)),
            ),
          if (_busy)
            Padding(
              padding: EdgeInsets.only(left: 16.w, top: 10.h),
              child: Text(i18n('ui_exporting'), style: TextStyle(fontSize: 14.sp, color: theme.primaryTextColor)),
            ),
        ],
      ),
    );
  }
}
