import 'package:dpad/dpad.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/modules/settings/pages/refresh_settings.dart';
import 'package:pure_live/modules/settings/pages/theme_settings_page.dart';
import 'package:pure_live/modules/settings/pages/video_settings_page.dart';
import 'package:pure_live/modules/settings/pages/local_config_preveiw.dart';
import 'package:pure_live/modules/settings/pages/general_settings_page.dart';
import 'package:pure_live/modules/settings/pages/platform_settings_page.dart';
import 'package:pure_live/modules/settings/pages/navigation_settings_page.dart';
import 'package:pure_live/modules/settings/pages/cache_data_settings_page.dart';
import 'package:pure_live/modules/settings/pages/network_proxy_settings_page.dart';
import 'package:pure_live/modules/settings/pages/player_kernel_settings_page.dart';

class SettingsPage extends GetView<SettingsService> {
  const SettingsPage({super.key});

  BuildContext get context => Get.context!;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(i18n("settings_title"), style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                DpadFocusable(
                  effects: [
                    DpadScaleEffect(scale: 1.05),
                    DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                  ],
                  onSelect: () async => Get.to(() => LocalConfigPreviewPage()),
                  builder: (context, state, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: state.focused
                            ? theme.colorScheme.primary.withOpacity(0.12)
                            : theme.colorScheme.primaryContainer.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Remix.file_text_line,
                            size: 18,
                            color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            i18n("config_preview"),
                            style: TextStyle(
                              color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: DpadRegion(
              memoryKey: 'settings/main_menu',
              horizontalEdge: DpadEdgeBehavior.stop,
              verticalEdge: DpadEdgeBehavior.stop,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  context.buildGroupTitle(i18n("theme_settings")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.palette_line,
                      title: i18n("theme_customization"),
                      subtitle: i18n("theme_customization_desc"),
                      onTap: () async => Get.to(() => const ThemeSettingsPage()),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("iptv_settings")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.tv_line,
                      title: i18n("iptv_settings"),
                      subtitle: i18n("manage_iptv_sources"),
                      onTap: () async => Get.to(() => const IptvPage()),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("refresh_settings")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.refresh_line,
                      title: i18n("refresh_settings"),
                      subtitle: i18n("refresh_settings_subtitle"),
                      onTap: () async => Get.to(() => const RefreshSettingsPage()),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("video_settings")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.film_line,
                      title: i18n("video"),
                      subtitle: i18n("video_desc"),
                      onTap: () async => Get.to(() => const VideoSettingsPage()),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("player_kernel_settings")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.cpu_line,
                      title: i18n("player_kernel"),
                      subtitle: i18n("player_kernel_desc"),
                      onTap: () async => Get.to(() => const PlayerKernelSettingsPage()),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("network_proxy_settings")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.global_line,
                      title: i18n("custom_network_proxy"),
                      subtitle: i18n("custom_network_proxy_desc"),
                      onTap: () async => Get.to(() => const NetworkProxySettingsPage()),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("general_settings")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.settings_4_line,
                      title: i18n("general"),
                      subtitle: i18n("general_desc"),
                      onTap: () async => Get.to(() => const GeneralSettingsPage()),
                    ),
                    context.buildTile(
                      icon: Remix.menu_line,
                      title: i18n("navigation_display_settings"),
                      subtitle: i18n("navigation_display_settings_desc"),
                      onTap: () async => Get.to(() => const NavigationSettingsPage()),
                    ),
                    context.buildTile(
                      icon: Remix.apps_2_line,
                      title: i18n("platform_settings"),
                      subtitle: i18n("platform_settings_desc"),
                      onTap: () async => Get.to(() => const PlatformSettingsPage()),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("data_manage")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.database_2_line,
                      title: i18n("cache_and_data"),
                      subtitle: i18n("cache_and_data_desc"),
                      onTap: () async => Get.to(() => const CacheDataSettingsPage()),
                    ),
                  ]),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("backup_manage")),
                  context.buildModernCard([
                    context.buildTile(
                      icon: Remix.cloud_line,
                      title: i18n("backup_recover"),
                      subtitle: i18n("backup_recover_desc"),
                      onTap: () async => Get.to(() => const BackupPage()),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
