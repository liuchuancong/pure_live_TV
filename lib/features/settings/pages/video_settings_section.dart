import 'dart:async';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:pure_live/app/router/app_router.dart';

/// Video settings, grouped in the mobile page's order
/// (`pure_live/lib/modules/settings/pages/video_settings_page.dart:81-290`):
/// audio settings → playback behavior → danmaku settings.
///
/// quality and line are *not* settings here: on a TV both are switched from the
/// fullscreen control bar while watching (`VideoControllerPanel`), which is also
/// where aspect ratio lives. The mobile page's cellular quality, background play,
/// ASMR, PiP/window, "fullscreen by default" and "keep the screen on" rows are
/// absent for the same reason: they describe a phone or a desktop.
class VideoSettingsSectionPage extends ConsumerWidget {
  const VideoSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // audio settings
        TvSettingsGroupTitle(title: i18n('audio_settings')),
        TvSettingsCard(
          children: [
            // global mute is honoured by the player core (`live_room_volume_manager`).
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
        // playback behavior
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
        SizedBox(height: 20.sp),
        // danmaku settings
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
    );
  }

  /// Pushes audio only into the running player instead of only storing it.
  void _applyAudioOnly(bool value) {
    final service = GlobalPlayerService.instance;
    if (!service.initialized) return;
    unawaited(service.playerManager.setAudioOnly(value));
  }
}
