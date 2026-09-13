import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/widgets/tv_settings_switch_tile.dart';
import 'package:pure_live/modules/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

class VideoSettingsSectionPage extends ConsumerWidget {
  const VideoSettingsSectionPage({super.key});

  static const _fitNames = ['默认(适配)', '裁剪居中', '拉伸填满', '适配高度', '适配宽度', '缩小适配'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: '画面比例',
          subtitle: '视频在屏幕中的适配方式',
          icon: Icons.aspect_ratio_rounded,
          options: _fitNames,
          index: playerState.videoFitIndex.clamp(0, _fitNames.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(videoFitIndex: i)),
        ),
        TvSettingsSwitchTile(
          title: '硬件解码',
          subtitle: '使用硬件解码降低 CPU 占用',
          icon: Icons.memory_rounded,
          value: playerState.enableCodec,
          onChanged: (v) => player.updateSettings(playerState.copyWith(enableCodec: v)),
        ),
      ],
    );
  }
}
