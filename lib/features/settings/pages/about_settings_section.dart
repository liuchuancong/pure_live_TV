import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/services/app_update/app_update_service.dart';
import 'package:pure_live/app/router/app_router.dart';

class AboutSettingsSectionPage extends ConsumerStatefulWidget {
  const AboutSettingsSectionPage({super.key});

  @override
  ConsumerState<AboutSettingsSectionPage> createState() => AboutSettingsSectionPageState();
}

class AboutSettingsSectionPageState extends ConsumerState<AboutSettingsSectionPage> {
  String _version = '';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) setState(() => _version = '${info.version}+${info.buildNumber}');
    });
  }

  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appSettingsControllerProvider);
    final app = ref.read(appSettingsControllerProvider.notifier);
    // new version found hint: the startup check has already run by the time this page
    // can be opened, so the badge is instant for a user with a pending update.
    final updateState = ref.watch(appUpdateControllerProvider);
    final String? newVersionHint =
        updateState.phase == AppUpdatePhase.available && updateState.latestVersion.isNotEmpty
        ? '${i18n('new_version_found')} v${updateState.latestVersion}'
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('about')),
        TvSettingsCard(
          children: [
            TvSettingsNavTile(
              title: i18nOr('online_update', 'Online update'),
              subtitle: <String>[
                ?newVersionHint,
                if (_version.isEmpty) i18n('current_version') else '${i18n('current_version')} v$_version',
              ].join(' · '),
              icon: Icons.system_update_alt_rounded,
              trailing: newVersionHint == null
                  ? null
                  : Text(i18n('new_version_found'), style: TextStyle(fontSize: 14.sp, color: context.tvTheme.focusColor)),
              onTap: () => const AppUpdateRoute().push(context),
            ),
          ],
        ),
        SizedBox(height: 20.sp),
        TvSettingsGroupTitle(title: i18n('project')),
        TvSettingsCard(
          children: [
            TvSettingsSwitchTile(
              title: i18n('ui_use_direct_github_updates'),
              subtitle: i18n('ui_check_updates_directly_on_github_without_a_mirro'),
              icon: Icons.cloud_outlined,
              value: appState.useGitHubOriginForUpdates,
              onChanged: (v) => app.update(appState.copyWith(useGitHubOriginForUpdates: v)),
            ),
          ],
        ),
      ],
    );
  }
}
