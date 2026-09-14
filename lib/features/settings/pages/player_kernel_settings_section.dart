import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/shared/widgets/tv_settings_switch_tile.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

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
          icon: Icons.play_circle_outline_rounded,
          options: engineKeys.map((k) => engineNames[k] ?? k).toList(),
          index: engineKeys.indexOf(playerState.videoPlayerKey).clamp(0, engineKeys.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(videoPlayerKey: engineKeys[i])),
        ),
        TvSettingsOptionTile(
          title: i18n('ui_preferred_quality'),
          subtitle: i18n('ui_preferred_quality_when_entering_a_room'),
          icon: Icons.hd_rounded,
          options: PlayerConsts.resolutions,
          index: PlayerConsts.resolutionKeys
              .indexOf(PlayerConsts.normalizeResolutionKey(playerState.preferResolution))
              .clamp(0, PlayerConsts.resolutionKeys.length - 1),
          onChanged: (i) => player.changePreferResolution(PlayerConsts.resolutionKeys[i]),
        ),
        TvSettingsOptionTile(
          title: i18n('ui_fallback_quality'),
          subtitle: i18n('ui_preferred_quality_on_cellular_networks'),
          icon: Icons.signal_cellular_alt_rounded,
          options: PlayerConsts.resolutions,
          index: PlayerConsts.resolutionKeys
              .indexOf(PlayerConsts.normalizeResolutionKey(playerState.preferResolutionCellular))
              .clamp(0, PlayerConsts.resolutionKeys.length - 1),
          onChanged: (i) => player.changePreferResolutionCellular(PlayerConsts.resolutionKeys[i]),
        ),
        TvSettingsSwitchTile(
          title: i18n('ui_audio_only'),
          subtitle: i18n('ui_audio_only_no_video_rendering'),
          icon: Icons.headphones_rounded,
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
      ],
    );
  }
}
