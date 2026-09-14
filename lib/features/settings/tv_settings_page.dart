import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/pages/about_settings_section.dart';
import 'package:pure_live/features/settings/pages/audio_output_settings_section.dart';
import 'package:pure_live/features/settings/pages/backup_settings_section.dart';
import 'package:pure_live/features/settings/pages/cache_settings_section.dart';
import 'package:pure_live/features/settings/pages/danmaku_settings_section.dart';
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

/// Settings shell: module menu on the left, routed section on the right.
///
/// Every section is its own page and is registered as a go_router sub-route
/// (/settings/general, /settings/theme, ...).
class TvSettingsShell extends StatelessWidget {
  const TvSettingsShell({super.key, required this.child});

  final Widget child;

  static const modules = <({String path, String title, IconData icon, Widget page})>[
    (path: '/settings/general', title: '通用设置', icon: Icons.tune_rounded, page: GeneralSettingsSectionPage()),
    (path: '/settings/theme', title: '主题外观', icon: Icons.palette_outlined, page: ThemeSettingsSectionPage()),
    (path: '/settings/player_kernel', title: '播放内核', icon: Icons.play_circle_outline_rounded, page: PlayerKernelSettingsSectionPage()),
    (path: '/settings/video', title: '视频设置', icon: Icons.video_settings_outlined, page: VideoSettingsSectionPage()),
    (path: '/settings/decoder', title: '解码设置', icon: Icons.memory_rounded, page: DecoderSettingsSectionPage()),
    (path: '/settings/renderer', title: '渲染设置', icon: Icons.graphic_eq_rounded, page: RendererSettingsSectionPage()),
    (path: '/settings/audio_output', title: '音频输出', icon: Icons.surround_sound_rounded, page: AudioOutputSettingsSectionPage()),
    (path: '/settings/danmaku', title: '弹幕设置', icon: Icons.subtitles_rounded, page: DanmakuSettingsSectionPage()),
    (path: '/settings/platform', title: '平台设置', icon: Icons.devices_rounded, page: PlatformSettingsSectionPage()),
    (path: '/settings/page', title: '分页设置', icon: Icons.list_alt_rounded, page: PageSettingsSectionPage()),
    (path: '/settings/refresh', title: '刷新设置', icon: Icons.refresh_rounded, page: RefreshSettingsSectionPage()),
    (path: '/settings/font', title: '字体设置', icon: Icons.text_fields_rounded, page: FontSettingsSectionPage()),
    (path: '/settings/cache', title: '缓存管理', icon: Icons.cleaning_services_rounded, page: CacheSettingsSectionPage()),
    (path: '/settings/proxy', title: '网络代理', icon: Icons.vpn_key_rounded, page: ProxySettingsSectionPage()),
    (path: '/settings/backup', title: '备份与恢复', icon: Icons.backup_outlined, page: BackupSettingsSectionPage()),
    (path: '/settings/about', title: '关于', icon: Icons.info_outline_rounded, page: AboutSettingsSectionPage()),
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
                    '系统设置',
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
