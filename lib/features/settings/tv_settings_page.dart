import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/tv_scaffold.dart';
import 'package:pure_live/features/iptv/pages/iptv_manage_section.dart';
import 'package:pure_live/features/settings/pages/navigation_section.dart';
import 'package:pure_live/features/settings/pages/backup_manage_section.dart';
import 'package:pure_live/features/settings/pages/font_settings_section.dart';
import 'package:pure_live/features/settings/pages/page_settings_section.dart';
import 'package:pure_live/features/settings/pages/about_settings_section.dart';
import 'package:pure_live/features/settings/pages/cache_settings_section.dart';
import 'package:pure_live/features/settings/pages/danmaku_shield_section.dart';
import 'package:pure_live/features/settings/pages/proxy_settings_section.dart';
import 'package:pure_live/features/settings/pages/tag_management_section.dart';
import 'package:pure_live/features/settings/pages/theme_settings_section.dart';
import 'package:pure_live/features/settings/pages/video_settings_section.dart';
import 'package:pure_live/features/settings/pages/audience_metric_section.dart';
import 'package:pure_live/features/settings/pages/backup_settings_section.dart';
import 'package:pure_live/features/settings/pages/webdav_settings_section.dart';
import 'package:pure_live/features/settings/pages/account_settings_section.dart';
import 'package:pure_live/features/settings/pages/danmaku_settings_section.dart';
import 'package:pure_live/features/settings/pages/decoder_settings_section.dart';
import 'package:pure_live/features/settings/pages/general_settings_section.dart';
import 'package:pure_live/features/settings/pages/refresh_settings_section.dart';
import 'package:pure_live/features/settings/pages/platform_settings_section.dart';
import 'package:pure_live/features/settings/pages/renderer_settings_section.dart';
import 'package:pure_live/features/settings/pages/font_family_manager_section.dart';
import 'package:pure_live/features/settings/pages/audio_output_settings_section.dart';
import 'package:pure_live/features/settings/pages/player_kernel_settings_section.dart';

/// One settings destination: its go_router path, its translated label key and
/// the section widget shown on the right.
typedef SettingsModule = ({String path, String titleKey, IconData icon, Widget page});

/// Settings shell reached through go_router.
///
/// Every section is its own page and is registered as a nested sub-route
/// (`/settings/general`, `/settings/theme`, ...). Because this form owns the
/// whole screen it provides the scaffold, app bar and background; the embedded
/// form ([TvSettingsEmbedded]) inherits those from `HomePage` instead.
class TvSettingsShell extends StatelessWidget {
  const TvSettingsShell({super.key, required this.child});

  final Widget child;

  /// Labels stay as keys so switching the app language re-translates the menu
  /// instead of freezing the language active when this list was first read.
  static final List<SettingsModule> modules = <SettingsModule>[
    (path: '/settings/general', titleKey: 'general_settings', icon: Icons.tune_rounded, page: GeneralSettingsSectionPage()),
    (path: '/settings/theme', titleKey: 'ui_theme', icon: Icons.palette_outlined, page: ThemeSettingsSectionPage()),
    (path: '/settings/player_kernel', titleKey: 'ui_player_kernel', icon: Icons.play_circle_outline_rounded, page: PlayerKernelSettingsSectionPage()),
    (path: '/settings/video', titleKey: 'video_settings', icon: Icons.video_settings_outlined, page: VideoSettingsSectionPage()),
    (path: '/settings/decoder', titleKey: 'ui_decoder_settings', icon: Icons.memory_rounded, page: DecoderSettingsSectionPage()),
    (path: '/settings/renderer', titleKey: 'ui_renderer_settings', icon: Icons.graphic_eq_rounded, page: RendererSettingsSectionPage()),
    (path: '/settings/audio_output', titleKey: 'ui_audio_output', icon: Icons.surround_sound_rounded, page: AudioOutputSettingsSectionPage()),
    (path: '/settings/danmaku', titleKey: 'danmaku_settings', icon: Icons.subtitles_rounded, page: DanmakuSettingsSectionPage()),
    (path: '/settings/shield', titleKey: 'block_list', icon: Icons.block_rounded, page: DanmakuShieldSectionPage()),
    (path: '/settings/platform', titleKey: 'ui_platform_settings', icon: Icons.devices_rounded, page: PlatformSettingsSectionPage()),
    (path: '/settings/audience', titleKey: 'audience_metric_settings', icon: Icons.insights_rounded, page: AudienceMetricSectionPage()),
    (path: '/settings/tags', titleKey: 'tag_management', icon: Icons.sell_outlined, page: TagManagementSectionPage()),
    (path: '/settings/navigation', titleKey: 'navigation_settings', icon: Icons.view_sidebar_outlined, page: NavigationSectionPage()),
    (path: '/settings/page', titleKey: 'page_settings', icon: Icons.list_alt_rounded, page: PageSettingsSectionPage()),
    (path: '/settings/refresh', titleKey: 'refresh_settings', icon: Icons.refresh_rounded, page: RefreshSettingsSectionPage()),
    (path: '/settings/font', titleKey: 'ui_font_settings', icon: Icons.text_fields_rounded, page: FontSettingsSectionPage()),
    (path: '/settings/fonts', titleKey: 'font_family', icon: Icons.font_download_outlined, page: FontFamilyManagerSectionPage()),
    (path: '/settings/iptv', titleKey: 'iptv_manage', icon: Icons.live_tv_outlined, page: IptvManageSectionPage()),
    (path: '/settings/cache', titleKey: 'cache_management', icon: Icons.cleaning_services_rounded, page: CacheSettingsSectionPage()),
    (path: '/settings/proxy', titleKey: 'ui_network_proxy', icon: Icons.vpn_key_rounded, page: ProxySettingsSectionPage()),
    (path: '/settings/backup', titleKey: 'backup_recover', icon: Icons.backup_outlined, page: BackupSettingsSectionPage()),
    (path: '/settings/webdav', titleKey: 'webdav', icon: Icons.cloud_outlined, page: WebDavSettingsSectionPage()),
    (path: '/settings/backups', titleKey: 'local_backup', icon: Icons.folder_copy_outlined, page: BackupManageSectionPage()),
    (path: '/settings/account', titleKey: 'bilibili_login', icon: Icons.account_circle_outlined, page: AccountSettingsSectionPage()),
    (path: '/settings/about', titleKey: 'about', icon: Icons.info_outline_rounded, page: AboutSettingsSectionPage()),
  ];

  /// Index of the module owning [location].
  ///
  /// Matches a whole path segment so `/settings/fonts` cannot be attributed to
  /// the `/settings/font` entry that happens to sit earlier in the list.
  static int indexForLocation(String location) {
    final int index = modules.indexWhere((m) => location == m.path || location.startsWith('${m.path}/'));
    return index < 0 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;

    return TvScaffold(
      title: i18n('ui_settings'),
      child: SettingsShellBody(
        selectedIndex: indexForLocation(location),
        onSelect: (int index) => context.go(modules[index].path),
        memoryKey: 'settings_menu_router',
        child: child,
      ),
    );
  }
}

/// Settings shell rendered inside the home side menu.
///
/// The home page owns the scaffold and the module list is swapped in place, so
/// this form keeps the selected module in local state instead of routing. It
/// used to render [TvSettingsShell] with an empty child, which produced a menu
/// whose every entry navigated to a route the app does not register and an
/// always-empty right pane — the settings tab could not be entered at all.
class TvSettingsEmbedded extends StatefulWidget {
  const TvSettingsEmbedded({super.key});

  @override
  State<TvSettingsEmbedded> createState() => _TvSettingsEmbeddedState();
}

class _TvSettingsEmbeddedState extends State<TvSettingsEmbedded> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return SettingsShellBody(
      selectedIndex: _selectedIndex,
      onSelect: (int index) {
        if (index == _selectedIndex) return;
        setState(() => _selectedIndex = index);
      },
      memoryKey: 'settings_menu_embedded',
      child: TvSettingsShell.modules[_selectedIndex].page,
    );
  }
}

/// Module menu on the left, section content on the right.
class SettingsShellBody extends StatelessWidget {
  const SettingsShellBody({
    super.key,
    required this.selectedIndex,
    required this.onSelect,
    required this.memoryKey,
    required this.child,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;
  final String memoryKey;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DpadRegion(
          memoryKey: memoryKey,
          child: Container(
            width: 240.sp,
            color: currentTvTheme.cardColor,
            padding: EdgeInsets.symmetric(vertical: 16.sp, horizontal: 8.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: 12.sp, bottom: 16.sp),
                  child: Text(
                    i18n('ui_settings'),
                    style: AppTextStyles.t24W600.copyWith(color: currentTvTheme.primaryTextColor),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final (index, module) in TvSettingsShell.modules.indexed)
                          _SettingsMenuItem(
                            title: i18n(module.titleKey),
                            icon: module.icon,
                            selected: index == selectedIndex,
                            onSelect: () => onSelect(index),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: DpadRegion(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.sp),
              child: child,
            ),
          ),
        ),
      ],
    );
  }
}

class _SettingsMenuItem extends StatelessWidget {
  const _SettingsMenuItem({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onSelect,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    // `DpadFocusable` rejects `effects` and `builder` together, so the focus
    // glow is applied around the builder's presentation instead.
    final List<DpadEffect> effects = [
      DpadScaleEffect(scale: 1.03),
      DpadGlowEffect(color: currentTvTheme.focusColor.withValues(alpha: 0.4), borderRadius: BorderRadius.circular(8)),
    ];
    return DpadFocusable(
      onSelect: () => onSelect(),
      builder: (context, state, child) {
        final highlighted = selected || state.focused;
        return DpadEffect.wrap(
          context,
          effects,
          state,
          Container(
            margin: EdgeInsets.only(bottom: 8.sp),
            padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 12.sp),
            decoration: BoxDecoration(
              color: highlighted ? currentTvTheme.focusColor.withValues(alpha: 0.2) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20.sp,
                  color: highlighted ? currentTvTheme.focusColor : currentTvTheme.secondaryTextColor,
                ),
                SizedBox(width: 10.sp),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: highlighted ? currentTvTheme.focusColor : currentTvTheme.primaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
