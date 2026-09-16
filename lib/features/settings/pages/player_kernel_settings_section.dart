import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

class PlayerKernelSettingsSectionPage extends ConsumerWidget {
  const PlayerKernelSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    final engineKeys = PlayerConsts.engines.keys.toList();
    final engineNames = {'mpv': 'MPV (media_kit)', 'ijk': 'IJK (fijkplayer)', 'exo': 'Exo (better_player)'};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: i18n('ui_player_kernel'),
          subtitle: i18n('ui_takes_effect_after_re_entering_the_room'),
          icon: Remix.toggle_line,
          options: engineKeys.map((k) => engineNames[k] ?? k).toList(),
          index: engineKeys.indexOf(playerState.videoPlayerKey).clamp(0, engineKeys.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(videoPlayerKey: engineKeys[i])),
        ),
        // Desktop order inside the core-kernel group: the kernel switch, then
        // hardware decoding (the desktop keeps the quality rows on its video
        // page, which is where they live here too).
        TvSettingsSwitchTile(
          title: i18n('ui_hardware_decoding'),
          subtitle: i18n('ui_use_hardware_decoding_to_lower_cpu_usage'),
          icon: Remix.speed_up_line,
          value: playerState.enableCodec,
          onChanged: (v) => player.updateSettings(playerState.copyWith(enableCodec: v)),
        ),
        TvSettingsSwitchTile(
          title: i18n('ui_audio_only'),
          subtitle: i18n('ui_audio_only_no_video_rendering'),
          icon: Remix.headphone_line,
          value: playerState.audioOnly,
          onChanged: (v) => player.updateSettings(playerState.copyWith(audioOnly: v)),
        ),
        TvSettingsOptionTile(
          title: i18n('ui_reset_mpv_settings'),
          subtitle: i18n('ui_reset_all_mpv_advanced_settings_to_defaults'),
          icon: Icons.restart_alt_rounded,
          options: [i18n('reset')],
          index: 0,
          onChanged: (_) => player.resetMpvPlayerSettings(),
        ),
        // The desktop player-kernel page shows these three only for the MPV
        // kernel, because they configure mpv itself.
        if (playerState.videoPlayerKey == 'mpv') ...[
          TvSettingsNavTile(
            title: i18n('ui_decoder_settings'),
            subtitle: i18n('ui_decoder_settings_desc'),
            icon: Remix.cpu_line,
            onTap: () => context.push(AppRoutes.kSettingsDecoder),
          ),
          TvSettingsNavTile(
            title: i18n('ui_renderer_settings'),
            subtitle: i18n('ui_renderer_settings_desc'),
            icon: Remix.tv_line,
            onTap: () => context.push(AppRoutes.kSettingsRenderer),
          ),
          TvSettingsNavTile(
            title: i18n('ui_audio_output'),
            subtitle: i18n('ui_audio_output_desc'),
            icon: Remix.volume_up_line,
            onTap: () => context.push(AppRoutes.kSettingsAudioOutput),
          ),
        ],
      ],
    );
  }
}
