
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/widgets/tv_settings_switch_tile.dart';
import 'package:package_info_plus/package_info_plus.dart';

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
          title: '纯粹直播 TV',
          subtitle: '当前版本 $_version',
          icon: Icons.info_outline_rounded,
          options: const ['检查更新'],
          index: 0,
          onChanged: (_) {},
        ),
        TvSettingsSwitchTile(
          title: '使用 GitHub 直连更新',
          subtitle: '不经过镜像加速，直连 GitHub 检查更新',
          icon: Icons.cloud_outlined,
          value: appState.useGitHubOriginForUpdates,
          onChanged: (v) => app.update(appState.copyWith(useGitHubOriginForUpdates: v)),
        ),
      ],
    );
  }
}
