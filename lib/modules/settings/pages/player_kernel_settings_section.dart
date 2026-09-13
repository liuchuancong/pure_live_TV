import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/widgets/tv_settings_switch_tile.dart';
import 'package:pure_live/modules/settings/tv_settings_option_tile.dart';
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
          title: '播放内核',
          subtitle: '切换后重新进入直播间生效',
          icon: Icons.play_circle_outline_rounded,
          options: engineKeys.map((k) => engineNames[k] ?? k).toList(),
          index: engineKeys.indexOf(playerState.videoPlayerKey).clamp(0, engineKeys.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(videoPlayerKey: engineKeys[i])),
        ),
        TvSettingsOptionTile(
          title: '偏好清晰度',
          subtitle: '进入直播间优先选择的清晰度',
          icon: Icons.hd_rounded,
          options: PlayerConsts.resolutions,
          index: PlayerConsts.resolutions
              .indexOf(playerState.preferResolution)
              .clamp(0, PlayerConsts.resolutions.length - 1),
          onChanged: (i) => player.changePreferResolution(PlayerConsts.resolutions[i]),
        ),
        TvSettingsOptionTile(
          title: '备用清晰度',
          subtitle: '蜂窝网络下优先选择的清晰度',
          icon: Icons.signal_cellular_alt_rounded,
          options: PlayerConsts.resolutions,
          index: PlayerConsts.resolutions
              .indexOf(playerState.preferResolutionCellular)
              .clamp(0, PlayerConsts.resolutions.length - 1),
          onChanged: (i) => player.changePreferResolutionCellular(PlayerConsts.resolutions[i]),
        ),
        TvSettingsSwitchTile(
          title: '仅播放音频',
          subtitle: '不渲染视频画面，只听声音',
          icon: Icons.headphones_rounded,
          value: playerState.audioOnly,
          onChanged: (v) => player.updateSettings(playerState.copyWith(audioOnly: v)),
        ),
        TvSettingsOptionTile(
          title: '重置 MPV 设置',
          subtitle: '恢复 MPV 播放器全部高级设置为默认值',
          icon: Icons.restart_alt_rounded,
          options: const ['重置'],
          index: 0,
          onChanged: (_) => player.resetMpvPlayerSettings(),
        ),
      ],
    );
  }
}
