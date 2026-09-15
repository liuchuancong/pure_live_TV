import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/shared/dialog/tv_dialog.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/utils/version_util.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutSettingsSectionPage extends ConsumerStatefulWidget {
  const AboutSettingsSectionPage({super.key});

  @override
  ConsumerState<AboutSettingsSectionPage> createState() => AboutSettingsSectionPageState();
}

class AboutSettingsSectionPageState extends ConsumerState<AboutSettingsSectionPage> {
  String _version = '';
  String _status = '';
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
    });
  }

  Future<void> _checkUpdate() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _status = '';
    });
    try {
      final hasUpdate = await VersionUtil().checkUpdate();
      if (!mounted) return;
      setState(() {
        _status = hasUpdate
            ? '${i18n('latest_version')} ${VersionUtil.latestVersion}'
            : i18n('already_latest_version');
      });
      if (hasUpdate) await _showUpdateDialog();
    } catch (error) {
      if (mounted) setState(() => _status = '${i18n('check_update_failed')} · $error');
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _showUpdateDialog() async {
    final notes = VersionUtil.latestUpdateLog.trim();
    final bool canDownload = VersionUtil.downloadUrl.isNotEmpty;
    await showDialog<void>(
      context: context,
      // TvDialog instead of a Material AlertDialog so the dialog can actually
      // be driven with the remote: the confirm button takes focus on open and
      // Cancel/Download are reachable with the d-pad.
      builder: (dialogContext) => TvDialog(
        title: '${i18n('new_version_found')} ${VersionUtil.latestVersion}',
        confirmText: canDownload ? i18n('download') : null,
        cancelText: i18n('cancel'),
        onCancel: () => Navigator.of(dialogContext).pop(),
        onConfirm: () {
          Navigator.of(dialogContext).pop();
          final uri = Uri.tryParse(VersionUtil.downloadUrl);
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
        },
        child: SizedBox(
          width: 640.w,
          child: Text(notes.isEmpty ? i18n('latest_version') : '${i18n('update_log')}\n$notes'),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appSettingsControllerProvider);
    final app = ref.read(appSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: i18n('ui_pure_live_tv'),
          subtitle: _status.isEmpty ? '${i18n('current_version')} $_version' : _status,
          icon: Icons.info_outline_rounded,
          options: _checking ? [i18n('ui_loading')] : [i18n('check_update')],
          index: 0,
          onChanged: (_) => _checkUpdate(),
        ),
        TvSettingsSwitchTile(
          title: i18n('ui_use_direct_github_updates'),
          subtitle: i18n('ui_check_updates_directly_on_github_without_a_mirro'),
          icon: Icons.cloud_outlined,
          value: appState.useGitHubOriginForUpdates,
          onChanged: (v) => app.update(appState.copyWith(useGitHubOriginForUpdates: v)),
        ),
      ],
    );
  }
}
