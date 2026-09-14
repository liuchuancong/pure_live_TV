import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/pages/about_settings_section.dart';
import 'package:pure_live/features/settings/pages/account_settings_section.dart';
import 'package:pure_live/features/settings/pages/audience_metric_section.dart';
import 'package:pure_live/features/settings/pages/audio_output_settings_section.dart';
import 'package:pure_live/features/settings/pages/backup_manage_section.dart';
import 'package:pure_live/features/settings/pages/backup_settings_section.dart';
import 'package:pure_live/features/settings/pages/cache_settings_section.dart';
import 'package:pure_live/features/settings/pages/danmaku_settings_section.dart';
import 'package:pure_live/features/settings/pages/danmaku_shield_section.dart';
import 'package:pure_live/features/settings/pages/decoder_settings_section.dart';
import 'package:pure_live/features/settings/pages/font_settings_section.dart';
import 'package:pure_live/features/settings/pages/general_settings_section.dart';
import 'package:pure_live/features/settings/pages/page_settings_section.dart';
import 'package:pure_live/features/settings/pages/platform_settings_section.dart';
import 'package:pure_live/features/settings/pages/player_kernel_settings_section.dart';
import 'package:pure_live/features/settings/pages/proxy_settings_section.dart';
import 'package:pure_live/features/settings/pages/refresh_settings_section.dart';
import 'package:pure_live/features/settings/pages/renderer_settings_section.dart';
import 'package:pure_live/features/settings/pages/theme_settings_section.dart';
import 'package:pure_live/features/settings/pages/video_settings_section.dart';
import 'package:pure_live/features/settings/pages/webdav_settings_section.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// Settings shell: module menu on the left, routed section on the right.
///
/// Every section is its own page and is registered as a go_router sub-route
/// (/settings/general, /settings/theme, ...).
class TvSettingsShell extends StatelessWidget {
  TvSettingsShell({super.key, required this.child});

  final Widget child;

  static final modules = <({String path, String title, IconData icon, Widget page})>[
    (path: '/settings/general', title: i18n('general_settings'), icon: Icons.tune_rounded, page: GeneralSettingsSectionPage()),
    (path: '/settings/theme', title: i18n('ui_theme'), icon: Icons.palette_outlined, page: ThemeSettingsSectionPage()),
    (path: '/settings/player_kernel', title: i18n('ui_player_kernel'), icon: Icons.play_circle_outline_rounded, page: PlayerKernelSettingsSectionPage()),
    (path: '/settings/video', title: i18n('video_settings'), icon: Icons.video_settings_outlined, page: VideoSettingsSectionPage()),
    (path: '/settings/decoder', title: i18n('ui_decoder_settings'), icon: Icons.memory_rounded, page: DecoderSettingsSectionPage()),
    (path: '/settings/renderer', title: i18n('ui_renderer_settings'), icon: Icons.graphic_eq_rounded, page: RendererSettingsSectionPage()),
    (path: '/settings/audio_output', title: i18n('ui_audio_output'), icon: Icons.surround_sound_rounded, page: AudioOutputSettingsSectionPage()),
    (path: '/settings/danmaku', title: i18n('danmaku_settings'), icon: Icons.subtitles_rounded, page: DanmakuSettingsSectionPage()),
    (path: '/settings/shield', title: i18n('block_list'), icon: Icons.block_rounded, page: DanmakuShieldSectionPage()),
    (path: '/settings/platform', title: i18n('ui_platform_settings'), icon: Icons.devices_rounded, page: PlatformSettingsSectionPage()),
    (path: '/settings/audience', title: i18n('audience_metric_settings'), icon: Icons.insights_rounded, page: AudienceMetricSectionPage()),
    (path: '/settings/page', title: i18n('page_settings'), icon: Icons.list_alt_rounded, page: PageSettingsSectionPage()),
    (path: '/settings/refresh', title: i18n('refresh_settings'), icon: Icons.refresh_rounded, page: RefreshSettingsSectionPage()),
    (path: '/settings/font', title: i18n('ui_font_settings'), icon: Icons.text_fields_rounded, page: FontSettingsSectionPage()),
    (path: '/settings/cache', title: i18n('cache_management'), icon: Icons.cleaning_services_rounded, page: CacheSettingsSectionPage()),
    (path: '/settings/proxy', title: i18n('ui_network_proxy'), icon: Icons.vpn_key_rounded, page: ProxySettingsSectionPage()),
    (path: '/settings/backup', title: i18n('backup_recover'), icon: Icons.backup_outlined, page: BackupSettingsSectionPage()),
    (path: '/settings/webdav', title: i18n('webdav'), icon: Icons.cloud_outlined, page: WebDavSettingsSectionPage()),
    (path: '/settings/backups', title: i18n('local_backup'), icon: Icons.folder_copy_outlined, page: BackupManageSectionPage()),
    (path: '/settings/account', title: i18n('bilibili_login'), icon: Icons.account_circle_outlined, page: AccountSettingsSectionPage()),
    (path: '/settings/about', title: i18n('about'), icon: Icons.info_outline_rounded, page: AboutSettingsSectionPage()),
  ];

  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final location = GoRouterState.of(context).matchedLocation;
    final currentIndex = modules.indexWhere((m) => location.startsWith(m.path)).clamp(0, modules.length - 1);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DpadRegion(
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
                        for (final (index, module) in modules.indexed)
                          _SettingsMenuItem(
                            title: module.title,
                            icon: module.icon,
                            selected: index == currentIndex,
                            onSelect: () => context.go(module.path),
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
    return DpadFocusable(
      effects: [DpadScaleEffect(scale: 1.03), DpadGlowEffect(color: currentTvTheme.focusColor.withValues(alpha: 0.4))],
      onSelect: () => onSelect(),
      builder: (context, state, child) {
        final highlighted = selected || state.focused;
        return Container(
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
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
