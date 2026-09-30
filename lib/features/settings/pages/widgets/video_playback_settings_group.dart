import 'package:pure_live/services/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/features/settings/pages/video_settings_section.dart';
/// The playback group: audio and playback-behavior rows.
class VideoPlaybackSettingsGroup extends ConsumerWidget {
  const VideoPlaybackSettingsGroup({super.key});

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

String _qualityLabel(int qn) {
  if (qn <= 0) return i18n('video_quality_auto');
  final label = BilibiliMusicApi.qualityLabel(qn);
  return label.isEmpty ? '$qn' : label;
}
