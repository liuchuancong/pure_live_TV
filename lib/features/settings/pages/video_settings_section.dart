import 'dart:async';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:pure_live/app/router/app_router.dart';

/// Video settings in newBV's settings shape: a left menu of groups over a
/// right content pane (播放设置 / 界面设置 / 弹幕设置). The rows sync newBV's
/// settings pages: what a video opens at (quality/speed/detail-first), where
/// the mode lands (startup section, top tabs), and the player surface toggles.
///
/// quality and line are *not* settings here: on a TV both are switched from the
/// fullscreen control bar while watching (`VideoControllerPanel`), which is also
/// where aspect ratio lives. The mobile page's cellular quality, background play,
/// ASMR, PiP/window, "fullscreen by default" and "keep the screen on" rows are
/// absent for the same reason: they describe a phone or a desktop.
class VideoSettingsSectionPage extends ConsumerStatefulWidget {
  const VideoSettingsSectionPage({super.key});

  @override
  ConsumerState<VideoSettingsSectionPage> createState() => _VideoSettingsSectionPageState();
}

class _VideoSettingsSectionPageState extends ConsumerState<VideoSettingsSectionPage> {
  int _group = 0;

  static const _groups = ['video_settings_playback', 'video_settings_interface', 'video_settings_danmaku'];

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------- the left group menu
        SizedBox(
          width: 300.sp,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, labelKey) in _groups.indexed)
                TvFocusable(
                  key: ValueKey('video_settings_group_$index'),
                  autofocus: index == 0,
                  onTap: () => setState(() => _group = index),
                  builder: (context, focused, _) => AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 18.sp),
                    decoration: BoxDecoration(
                      // The active group reads as newBV's left menu item: a
                      // filled dark pill while selected, the tinted card on
                      // focus.
                      color: _group == index
                          ? tvTheme.focusedCardColor
                          : focused
                          ? tvTheme.focusedCardColor.withValues(alpha: 0.7)
                          : tvTheme.cardColor,
                      borderRadius: BorderRadius.circular(20.sp),
                      border: Border.all(
                        color: focused ? tvTheme.focusColor : Colors.transparent,
                        width: 2.sp,
                      ),
                    ),
                    child: Text(
                      i18n(labelKey),
                      style: AppTextStyles.t20.copyWith(fontWeight: FontWeight.w600, 
                        color: _group == index ? tvTheme.primaryTextColor : tvTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 32.sp),
        // ------------------------------------------- the right content pane
        Expanded(
          child: switch (_group) {
            0 => const _PlaybackSettingsGroup(),
            1 => const _InterfaceSettingsGroup(),
            _ => const _DanmakuSettingsGroup(),
          },
        ),
      ],
    );
  }
}

/// The playback group: audio and playback-behavior rows.
class _PlaybackSettingsGroup extends ConsumerWidget {
  const _PlaybackSettingsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    // The video mode's own preferences (default quality/speed).
    final state = ref.watch(videoSettingsControllerProvider);
    final video = ref.read(videoSettingsControllerProvider.notifier);
    // The mute state picks this row's icon: slashed speaker when muted, regular
    // speaker once sound is on.
    final bool globalMute = ref.watch(volumeSettingsControllerProvider).globalVolumeMute;

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 4.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('audio_settings')),
          TvSettingsCard(
            children: [
              // global mute is honoured by the player core (`live_room_volume_manager`).
              TvSettingsSwitchTile(
                title: i18n('global_mute'),
                subtitle: i18n('global_mute_subtitle'),
                icon: globalMute ? Remix.volume_mute_line : Remix.volume_up_line,
                value: globalMute,
                onChanged: (v) => ref.read(volumeSettingsControllerProvider.notifier).setGlobalVolumeMute(v),
              ),
              // TV-only: the mobile app toggles audio-only from the player
              // controls, so this row lives in the audio group.
              TvSettingsSwitchTile(
                title: i18n('ui_audio_only'),
                subtitle: i18n('ui_audio_only_no_video_rendering'),
                icon: playerState.audioOnly ? Remix.headphone_line : Remix.volume_up_line,
                value: playerState.audioOnly,
                onChanged: (v) {
                  player.updateSettings(playerState.copyWith(audioOnly: v));
                  VideoSettingsSectionPageState.applyAudioOnly(v);
                },
              ),
            ],
          ),
          SizedBox(height: 20.sp),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('video_default_playback_title')),
          TvSettingsCard(
            children: [
              // 默认清晰度 (newBV): the rendition the video player asks for on
              // open when the play-url answer ships it; 自动 keeps the server pick.
              TvSettingsOptionTile(
                title: i18n('video_default_quality'),
                subtitle: i18n('video_default_quality_sub'),
                icon: Icons.high_quality_outlined,
                options: [for (final qn in VideoSettingsController.qualityOptions) _qualityLabel(qn)],
                index: VideoSettingsController.qualityOptions
                    .indexOf(state.preferredQuality)
                    .clamp(0, VideoSettingsController.qualityOptions.length - 1),
                onChanged: (i) => video.updateSettings(
                  state.copyWith(preferredQuality: VideoSettingsController.qualityOptions[i]),
                ),
              ),
              TvSettingsOptionTile(
                title: i18n('video_default_speed'),
                subtitle: i18n('video_default_speed_sub'),
                icon: Icons.speed_rounded,
                options: [for (final v in VideoSettingsController.speedOptions) '$v x'],
                index: VideoSettingsController.speedOptions
                    .indexOf(state.defaultSpeed)
                    .clamp(0, VideoSettingsController.speedOptions.length - 1),
                onChanged: (i) => video.updateSettings(
                  state.copyWith(defaultSpeed: VideoSettingsController.speedOptions[i]),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('playback_behavior_settings')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(
                title: i18n('audience_metric_settings'),
                subtitle: i18n('audience_metric_settings_desc'),
                icon: Icons.groups_2_rounded,
                onTap: () => const AudienceSettingsRoute().push(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// newBV's 界面设置: what the video mode opens on and two player-surface
/// toggles. Theme and text size live in the app-wide settings; this group
/// carries only what is video-specific.
class _InterfaceSettingsGroup extends ConsumerWidget {
  const _InterfaceSettingsGroup();

  /// The section labels in [VideoSection.values] order — the rail shows them
  /// in newBV's order, the setting stores the section index.
  static const _sections = ['video_tab_home', 'video_tab_region', 'video_tab_pgc', 'video_tab_search', 'video_personal'];
  static const _homeTabs = ['video_dynamics', 'video_tab_recommend', 'video_tab_popular'];
  static const _personalTabs = [
    'video_personal_follow',
    'video_personal_fav',
    'video_personal_history',
    'video_personal_toview',
    'video_personal_bangumi',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoSettingsControllerProvider);
    final video = ref.read(videoSettingsControllerProvider.notifier);

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 4.sp),
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
          SizedBox(height: 20.sp),
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

/// 默认清晰度 label: 自动 for 0 (the server pick), the API name otherwise.
String _qualityLabel(int qn) {
  if (qn <= 0) return i18n('video_quality_auto');
  final label = BilibiliMusicApi.qualityLabel(qn);
  return label.isEmpty ? '$qn' : label;
}

/// The danmaku group: the three danmaku destinations.
class _DanmakuSettingsGroup extends ConsumerWidget {
  const _DanmakuSettingsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 4.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('danmaku_settings')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(
                title: i18n('danmaku_settings'),
                subtitle: i18n('ui_show_danmaku_inside_live_rooms'),
                icon: Remix.chat_settings_line,
                onTap: () => const DanmakuSettingsRoute().push(context),
              ),
              TvSettingsNavTile(
                title: i18n('change_danmaku_font_family'),
                icon: Remix.font_size,
                // Danmaku mode: the selection writes danmakuFontFamilyName and
                // the flame engine picks it up live, instead of the old path
                // that silently changed the whole app font.
                onTap: () => const FontFamilyDanmakuRoute().push(context),
              ),
              TvSettingsNavTile(
                title: i18n('danmaku_filter'),
                icon: Remix.filter_2_line,
                onTap: () => const DanmuShieldRoute().push(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VideoSettingsSectionPageState {
  /// Pushes audio only into the running player instead of only storing it.
  static void applyAudioOnly(bool value) {
    final service = GlobalPlayerService.instance;
    if (!service.initialized) return;
    unawaited(service.livePlayer?.setAudioOnly(value));
  }
}
