import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/widgets/tv_settings_switch_tile.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

class RendererSettingsSectionPage extends ConsumerWidget {
  const RendererSettingsSectionPage({super.key});

  /// Video output drivers offered by the settings UI.
  static const Map<String, String> _drivers = {
    'auto': '自动选择',
    'gpu': 'GPU',
    'gpu-next': 'GPU Next',
    'sdl': 'SDL',
    'null': 'Null（不输出视频）',
    'mediacodec_embed': 'MediaCodec Embed（仅 Android）',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    final keys = _drivers.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: '视频输出驱动',
          subtitle: 'MPV 视频输出方式',
          icon: Icons.graphic_eq_rounded,
          options: keys.map((k) => _drivers[k]!).toList(),
          index: keys.indexOf(playerState.videoOutputDriver).clamp(0, keys.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(videoOutputDriver: keys[i])),
        ),
        TvSettingsSwitchTile(
          title: '自定义播放器输出',
          subtitle: '手动指定输出驱动，覆盖自动协商',
          icon: Icons.tune_rounded,
          value: playerState.customPlayerOutput,
          onChanged: (v) => player.updateSettings(playerState.copyWith(customPlayerOutput: v)),
        ),
      ],
    );
  }
}
