import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// One settings destination: its go_router path, translation keys and icon.
typedef SettingsEntry = ({String path, String titleKey, String? subtitleKey, IconData icon});

/// A titled group of entries — the "big group, small rows" layout.
typedef SettingsGroup = ({String titleKey, List<SettingsEntry> entries});

/// The settings catalog.
///
/// Grouping and order follow the desktop settings page
/// (`pure_live/lib/modules/settings/settings_page.dart`): theme, IPTV, refresh,
/// video, player kernel, network proxy, local user, general, data, backup.
/// Sections that only exist here are placed in the group they belong to.
final List<SettingsGroup> settingsCatalog = <SettingsGroup>[
  (
    titleKey: 'theme_settings',
    entries: <SettingsEntry>[
      (
        path: '/settings/theme',
        titleKey: 'theme_customization',
        subtitleKey: 'theme_customization_desc',
        icon: Remix.palette_line,
      ),
    ],
  ),
  (
    titleKey: 'iptv_settings',
    entries: <SettingsEntry>[
      (
        path: '/settings/iptv',
        titleKey: 'iptv_settings',
        subtitleKey: 'manage_iptv_sources',
        icon: Remix.tv_line,
      ),
    ],
  ),
  (
    titleKey: 'refresh_settings',
    entries: <SettingsEntry>[
      (
        path: '/settings/refresh',
        titleKey: 'refresh_settings',
        subtitleKey: 'refresh_settings_subtitle',
        icon: Remix.refresh_line,
      ),
    ],
  ),
  (
    titleKey: 'video_settings',
    entries: <SettingsEntry>[
      (path: '/settings/video', titleKey: 'video', subtitleKey: 'video_desc', icon: Remix.film_line),
      (
        path: '/settings/danmaku',
        titleKey: 'danmaku_settings',
        subtitleKey: 'danmaku_settings_desc',
        icon: Icons.subtitles_rounded,
      ),
      (path: '/settings/shield', titleKey: 'block_list', subtitleKey: 'block_list_desc', icon: Icons.block_rounded),
      (
        path: '/settings/decoder',
        titleKey: 'ui_decoder_settings',
        subtitleKey: 'ui_decoder_settings_desc',
        icon: Icons.memory_rounded,
      ),
      (
        path: '/settings/renderer',
        titleKey: 'ui_renderer_settings',
        subtitleKey: 'ui_renderer_settings_desc',
        icon: Icons.graphic_eq_rounded,
      ),
      (
        path: '/settings/audio_output',
        titleKey: 'ui_audio_output',
        subtitleKey: 'ui_audio_output_desc',
        icon: Icons.surround_sound_rounded,
      ),
    ],
  ),
  (
    titleKey: 'player_kernel_settings',
    entries: <SettingsEntry>[
      (
        path: '/settings/player_kernel',
        titleKey: 'player_kernel',
        subtitleKey: 'player_kernel_desc',
        icon: Remix.cpu_line,
      ),
    ],
  ),
  (
    titleKey: 'network_proxy_settings',
    entries: <SettingsEntry>[
      (
        path: '/settings/proxy',
        titleKey: 'custom_network_proxy',
        subtitleKey: 'custom_network_proxy_desc',
        icon: Remix.global_line,
      ),
    ],
  ),
  (
    titleKey: 'local_interaction_settings',
    entries: <SettingsEntry>[
      (
        path: '/settings/account',
        titleKey: 'bilibili_login',
        subtitleKey: 'ui_account_desc',
        icon: Icons.account_circle_outlined,
      ),
      (
        path: '/settings/tags',
        titleKey: 'tag_management',
        subtitleKey: 'tag_management_subtitle',
        icon: Icons.sell_outlined,
      ),
      (
        path: '/settings/audience',
        titleKey: 'audience_metric_settings',
        subtitleKey: 'audience_metric_settings_desc',
        icon: Icons.insights_rounded,
      ),
    ],
  ),
  (
    titleKey: 'general_settings',
    entries: <SettingsEntry>[
      (path: '/settings/general', titleKey: 'general', subtitleKey: 'general_desc', icon: Remix.settings_4_line),
      (
        path: '/settings/navigation',
        titleKey: 'navigation_display_settings',
        subtitleKey: 'navigation_display_settings_desc',
        icon: Remix.menu_line,
      ),
      (
        path: '/settings/platform',
        titleKey: 'platform_settings',
        subtitleKey: 'platform_settings_desc',
        icon: Remix.apps_2_line,
      ),
      (
        path: '/settings/page',
        titleKey: 'page_settings',
        subtitleKey: 'page_settings_subtitle',
        icon: Icons.list_alt_rounded,
      ),
      (
        path: '/settings/font',
        titleKey: 'ui_font_settings',
        subtitleKey: 'ui_font_settings_desc',
        icon: Icons.text_fields_rounded,
      ),
      (
        path: '/settings/fonts',
        titleKey: 'font_family',
        subtitleKey: 'font_family_desc',
        icon: Icons.font_download_outlined,
      ),
    ],
  ),
  (
    titleKey: 'data_manage',
    entries: <SettingsEntry>[
      (
        path: '/settings/cache',
        titleKey: 'cache_and_data',
        subtitleKey: 'cache_and_data_desc',
        icon: Remix.database_2_line,
      ),
    ],
  ),
  (
    titleKey: 'backup_manage',
    entries: <SettingsEntry>[
      (
        path: '/settings/backup',
        titleKey: 'backup_recover',
        subtitleKey: 'backup_recover_desc',
        icon: Remix.cloud_line,
      ),
      (
        path: '/settings/backups',
        titleKey: 'local_backup',
        subtitleKey: 'create_backup_subtitle',
        icon: Icons.folder_copy_outlined,
      ),
      (path: '/settings/webdav', titleKey: 'webdav', subtitleKey: 'backup_to_webdav', icon: Icons.cloud_outlined),
    ],
  ),
  (
    titleKey: 'about',
    entries: <SettingsEntry>[
      (
        path: '/settings/about',
        titleKey: 'ui_pure_live_tv',
        subtitleKey: 'check_update',
        icon: Icons.info_outline_rounded,
      ),
    ],
  ),
];

/// Catalog entry owning [location], or null when nothing matches.
///
/// Matches whole path segments so `/settings/fonts` cannot be attributed to
/// the `/settings/font` entry.
SettingsEntry? settingsEntryForLocation(String location) {
  for (final SettingsGroup group in settingsCatalog) {
    for (final SettingsEntry entry in group.entries) {
      if (location == entry.path || location.startsWith('${entry.path}/')) {
        return entry;
      }
    }
  }
  return null;
}

/// Grouped settings list: a heading per group, focusable rows inside a card.
class SettingsCatalogView extends StatelessWidget {
  const SettingsCatalogView({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 12.sp),
      children: [
        for (final SettingsGroup group in settingsCatalog) ...[
          TvSettingsGroupTitle(title: i18n(group.titleKey)),
          TvSettingsCard(
            children: [
              for (final SettingsEntry entry in group.entries)
                TvSettingsNavTile(
                  title: i18n(entry.titleKey),
                  subtitle: entry.subtitleKey == null ? null : i18n(entry.subtitleKey!),
                  icon: entry.icon,
                  onTap: () => context.push(entry.path),
                ),
            ],
          ),
          SizedBox(height: 20.sp),
        ],
        SizedBox(height: 24.sp),
      ],
    );
  }
}

/// `/settings` reached directly: the catalog as its own page.
class TvSettingsRoutePage extends StatelessWidget {
  const TvSettingsRoutePage({super.key});

  @override
  Widget build(BuildContext context) {
    return TvScaffold(title: i18n('settings_title'), child: const SettingsCatalogView());
  }
}

/// The catalog rendered inside the home side menu's content pane.
///
/// The home page already supplies the scaffold and the side menu, so a row
/// selection pushes its section as a full-screen page with a back button.
class TvSettingsEmbedded extends StatelessWidget {
  const TvSettingsEmbedded({super.key});

  @override
  Widget build(BuildContext context) => const SettingsCatalogView();
}

/// Wraps one settings section route with a title, a back button and scrolling.
///
/// Sections are pushed as `/settings/<module>`, so they are full-screen pages
/// rather than content sitting next to a module column the d-pad could not
/// leave.
class SettingsSectionScaffold extends StatelessWidget {
  const SettingsSectionScaffold({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final SettingsEntry? entry = settingsEntryForLocation(location);

    return TvScaffold(
      title: entry == null ? i18n('ui_settings') : i18n(entry.titleKey),
      child: SingleChildScrollView(padding: EdgeInsets.all(16.sp), child: child),
    );
  }
}
