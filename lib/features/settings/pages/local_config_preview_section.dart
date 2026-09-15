import 'dart:convert';

import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';

/// Read-only preview of the local configuration.
///
/// Mirrors the desktop app's `LocalConfigPreviewPage`: it shows what a backup
/// would contain before anything leaves the device. Nothing here is focusable
/// because there is nothing to operate; the text is selectable instead.
class LocalConfigPreviewSectionPage extends ConsumerStatefulWidget {
  const LocalConfigPreviewSectionPage({super.key});

  @override
  ConsumerState<LocalConfigPreviewSectionPage> createState() => _LocalConfigPreviewSectionPageState();
}

class _LocalConfigPreviewSectionPageState extends ConsumerState<LocalConfigPreviewSectionPage> {
  String _json = '';
  String _error = '';
  int _sectionCount = 0;
  int _version = 0;

  @override
  void initState() {
    super.initState();
    try {
      final data = ref.read(backupControllerProvider.notifier).exportAllSettings();
      _sectionCount = BackupController.countConfigSections(data);
      _version = (data['backupVersion'] as num?)?.toInt() ?? 0;
      _json = const JsonEncoder.withIndent('  ').convert(data);
    } catch (error) {
      _error = error.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    if (_error.isNotEmpty) {
      return Text(_error, style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${i18n('backup_version')} v$_version   ·   ${i18n('backup_settings')} $_sectionCount',
          style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor),
        ),
        SizedBox(height: 12.sp),
        // Bordered rather than rounded: the TV pages mark regions with a border.
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            border: Border.all(color: tvTheme.secondaryTextColor.withValues(alpha: 0.3)),
          ),
          child: SelectableText(
            _json,
            style: AppTextStyles.t16W500.copyWith(color: tvTheme.primaryTextColor, height: 1.5),
          ),
        ),
      ],
    );
  }
}
