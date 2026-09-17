import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('about')),
        TvSettingsCard(
          children: [
            TvSettingsNavTile(
              title: i18nOr('online_update', 'Online update'),
              subtitle: _version.isEmpty ? i18n('current_version') : '${i18n('current_version')} v$_version',
              icon: Icons.system_update_alt_rounded,
              onTap: () => context.push(AppRoutes.kAppUpdate),
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
