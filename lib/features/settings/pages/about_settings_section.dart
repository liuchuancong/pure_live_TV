
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/shared/widgets/tv_settings_switch_tile.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

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
        TvSettingsOptionTile(
          title: i18n('ui_pure_live_tv'),
          subtitle: '当前版本 $_version',
          icon: Icons.info_outline_rounded,
          options: [i18n('check_update')],
          index: 0,
          onChanged: (_) {},
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
