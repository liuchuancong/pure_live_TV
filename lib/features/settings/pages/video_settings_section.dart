import 'dart:async';

import 'package:pure_live/player/global_player_service.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/index.dart';

/// Video settings, grouped in the mobile page's order
/// (`pure_live/lib/modules/settings/pages/video_settings_page.dart:81-290`):
/// 音频设置 → 画质设置 → 播放行为设置 → 弹幕设置.
///
/// Rows that only mean something on a phone or a desktop are deliberately
/// absent: cellular quality, background play, ASMR, PiP/window, "fullscreen by
/// default" and "keep the screen on" (a TV's playback page *is* the fullscreen
/// page and the screen is always kept awake while a room is open).
class VideoSettingsSectionPage extends ConsumerWidget {
  const VideoSettingsSectionPage({super.key});

  static final _fitNames = [i18n('ui_default_fit'), i18n('ui_crop_to_center'), i18n('ui_stretch_to_fill'), i18n('ui_fit_height'), i18n('ui_fit_width'), i18n('ui_scale_down_to_fit')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    final List<String> resolutions = PlayerConsts.resolutions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 音频设置
        TvSettingsGroupTitle(title: i18n('audio_settings')),
        TvSettingsCard(
          children: [
            // 全局静音 is honoured by the player core (`live_room_volume_manager`).
            TvSettingsSwitchTile(
              title: i18n('global_mute'),
              subtitle: i18n('global_mute_subtitle'),
              icon: Remix.volume_mute_line,
              value: ref.watch(volumeSettingsControllerProvider).globalVolumeMute,
              onChanged: (v) => ref.read(volumeSettingsControllerProvider.notifier).setGlobalVolumeMute(v),
            ),
            // TV-only: the mobile app toggles audio-only from the player controls,
            // so this row lives in the audio group instead of between the kernel
            // rows (where it broke the mobile row order).
            TvSettingsSwitchTile(
              title: i18n('ui_audio_only'),
              subtitle: i18n('ui_audio_only_no_video_rendering'),
              icon: Remix.headphone_line,
              value: playerState.audioOnly,
              onChanged: (v) {
                player.updateSettings(playerState.copyWith(audioOnly: v));
                _applyAudioOnly(v);
              },
            ),
          ],
        ),
        SizedBox(height: 20.sp),
        // 画质设置
        TvSettingsGroupTitle(title: i18n('video_quality_settings')),
        TvSettingsCard(
          children: [
            TvSettingsOptionTile(
              title: i18n('ui_aspect_ratio'),
              subtitle: i18n('ui_how_the_video_fits_the_screen'),
              icon: Remix.aspect_ratio_line,
              options: _fitNames,
              index: playerState.videoFitIndex.clamp(0, _fitNames.length - 1),
              onChanged: (i) => player.updateSettings(playerState.copyWith(videoFitIndex: i)),
            ),
            TvSettingsOptionTile(
              title: i18n('prefer_resolution'),
              subtitle: i18n('prefer_resolution_subtitle'),
              icon: Remix.hd_line,
              options: resolutions,
              index: PlayerConsts.resolutionKeys
                  .indexOf(PlayerConsts.normalizeResolutionKey(playerState.preferResolution))
                  .clamp(0, resolutions.length - 1),
              onChanged: (i) => player.changePreferResolution(PlayerConsts.resolutionKeys[i]),
            ),
          ],
        ),
        SizedBox(height: 20.sp),
        // 播放行为设置
        TvSettingsGroupTitle(title: i18n('playback_behavior_settings')),
        TvSettingsCard(
          children: [
            TvSettingsNavTile(
              title: i18n('audience_metric_settings'),
              subtitle: i18n('audience_metric_settings_desc'),
              icon: Icons.groups_2_rounded,
              onTap: () => context.push(AppRoutes.kSettingsAudience),
            ),
          ],
        ),
        SizedBox(height: 20.sp),
        // 弹幕设置
        TvSettingsGroupTitle(title: i18n('danmaku_settings')),
        TvSettingsCard(
          children: [
            TvSettingsNavTile(
              title: i18n('danmaku_settings'),
              subtitle: i18n('ui_show_danmaku_inside_live_rooms'),
              icon: Remix.chat_settings_line,
              onTap: () => context.push(AppRoutes.kSettingsDanmaku),
            ),
            TvSettingsNavTile(
              title: i18n('change_danmaku_font_family'),
              icon: Remix.font_size,
              onTap: () => context.push(AppRoutes.kSettingsFontFamily),
            ),
            TvSettingsNavTile(
              title: i18n('danmaku_filter'),
              icon: Remix.filter_2_line,
              onTap: () => context.push(AppRoutes.kSettingsDanmuShield),
            ),
          ],
        ),
      ],
    );
  }

  /// Pushes 仅播放音频 into the running player instead of only storing it.
  void _applyAudioOnly(bool value) {
    final service = GlobalPlayerService.instance;
    if (!service.initialized) return;
    unawaited(service.playerManager.setAudioOnly(value));
  }
}
