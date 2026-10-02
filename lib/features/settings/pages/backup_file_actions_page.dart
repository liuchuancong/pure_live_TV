import 'package:pure_live/exports/package_export.dart';

/// What a backup file can be used for.
enum BackupFileAction { restore, delete }

/// Restore or delete one local backup file.
///
/// The two-item menu was a dialog. It is a page now so that the whole local
/// backup flow is one kind of surface: pick a file, pick an action, pick the
/// modules — no modal that can be dismissed by a stray back press while the
/// d-pad is somewhere else.
class BackupFileActionsPage extends StatelessWidget {
  const BackupFileActionsPage({super.key, required this.fileName, required this.description});

  /// Shown as the page title.
  final String fileName;

  /// Size and timestamp of the file, under the title.
  final String description;

  @override
  Widget build(BuildContext context) {
    return TvPageScaffold(
      title: fileName,
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: 24.ts(context), vertical: 8.ts(context)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(left: 8.ts(context), bottom: 12.ts(context)),
              child: Text(
                description,
                style: AppTextStyles.t18.copyWith(
                  fontWeight: FontWeight.w300,
                  color: context.tvTheme.secondaryTextColor,
                ),
              ),
            ),
            TvSettingsCard(
              children: [
                TvSettingsRow(
                  title: i18n('recover_backup'),
                  subtitle: i18n('recover_backup_subtitle'),
                  icon: Remix.file_upload_line,
                  autofocus: true,
                  onSelect: () => Navigator.of(context).pop(BackupFileAction.restore),
                ),
                TvSettingsRow(
                  title: i18n('delete'),
                  subtitle: i18nOr('delete_backup_subtitle', 'Pick a local backup file and delete it'),
                  icon: Remix.delete_bin_line,
                  onSelect: () => Navigator.of(context).pop(BackupFileAction.delete),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Opens [BackupFileActionsPage]; null when the user simply left the page.
Future<BackupFileAction?> showBackupFileActions(
  BuildContext context, {
  required String fileName,
  required String description,
}) {
  return Navigator.of(context, rootNavigator: true).push<BackupFileAction>(
    MaterialPageRoute<BackupFileAction>(
      builder: (_) => BackupFileActionsPage(fileName: fileName, description: description),
    ),
  );
}
