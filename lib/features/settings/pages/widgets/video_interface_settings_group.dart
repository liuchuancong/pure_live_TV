import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/package_export.dart';

/// toggles. Theme and text size live in the app-wide settings; this group
/// carries only what is video-specific.
class VideoInterfaceSettingsGroup extends ConsumerWidget {
  const VideoInterfaceSettingsGroup({super.key});

  /// The section labels in [VideoSection.values] order — the rail shows them
  /// in newBV's order, the setting stores the section index.
  static const _sections = [
    'video_tab_home',
    'video_tab_region',
    'video_tab_pgc',
    'video_tab_search',
    'video_personal',
  ];
  static const _homeTabs = ['video_dynamics', 'video_tab_recommend', 'video_tab_popular'];
  static const _personalTabs = [
    'video_personal_follow',
    'video_personal_toview',
    'video_personal_fav',
    'video_personal_history',
    'video_personal_bangumi',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoSettingsControllerProvider);
    final video = ref.read(videoSettingsControllerProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 4.ts(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('video_settings_interface')),
          TvSettingsCard(
            children: [
              TvSettingsOptionTile(
                title: i18n('video_startup_page'),
                subtitle: i18n('video_startup_page_sub'),
                icon: Icons.rocket_launch_outlined,
                options: [for (final key in _sections) i18n(key)],
                index: state.startSection.clamp(0, _sections.length - 1),
                onChanged: (i) => video.updateSettings(state.copyWith(startSection: i)),
              ),
              TvSettingsOptionTile(
                title: i18n('video_home_default_tab'),
                icon: Icons.home_outlined,
                options: [for (final key in _homeTabs) i18n(key)],
                index: state.homeTabIndex.clamp(0, _homeTabs.length - 1),
                onChanged: (i) => video.updateSettings(state.copyWith(homeTabIndex: i)),
              ),
              TvSettingsOptionTile(
                title: i18n('video_personal_default_tab'),
                icon: Icons.person_outline_rounded,
                options: [for (final key in _personalTabs) i18n(key)],
                index: state.personalTabIndex.clamp(0, _personalTabs.length - 1),
                onChanged: (i) => video.updateSettings(state.copyWith(personalTabIndex: i)),
              ),
            ],
          ),
          SizedBox(height: 20.ts(context)),
          TvSettingsGroupTitle(title: i18n('video_player_surface')),
          TvSettingsCard(
            children: [
              TvSettingsSwitchTile(
                title: i18n('video_show_detail_first'),
                subtitle: i18n('video_show_detail_first_sub'),
                icon: Icons.info_outline_rounded,
                value: state.showVideoDetail,
                onChanged: (v) => video.updateSettings(state.copyWith(showVideoDetail: v)),
              ),
              TvSettingsSwitchTile(
                title: i18n('video_persistent_progress'),
                subtitle: i18n('video_persistent_progress_sub'),
                icon: Icons.align_vertical_bottom_rounded,
                value: state.persistentProgress,
                onChanged: (v) => video.updateSettings(state.copyWith(persistentProgress: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
