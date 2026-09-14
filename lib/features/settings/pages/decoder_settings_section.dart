import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/widgets/tv_settings_switch_tile.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

class DecoderSettingsSectionPage extends ConsumerWidget {
  const DecoderSettingsSectionPage({super.key});

  /// Common hardware decoders offered by the settings UI.
  static const Map<String, String> _decoders = {
    'auto': '启用任意可用解码器',
    'auto-safe': '启用最佳解码器',
    'auto-copy': '启用带拷贝功能的最佳解码器',
    'd3d11va': 'DirectX 11（Windows 8+）',
    'd3d11va-copy': 'DirectX 11（非直通）',
    'mediacodec': 'MediaCodec（Android）',
    'mediacodec-copy': 'MediaCodec（Android，非直通）',
    'videotoolbox': 'VideoToolbox（macOS / iOS）',
    'vaapi': 'VAAPI（Linux）',
    'nvdec': 'NVDEC（仅 NVIDIA）',
    'no': '不使用硬解（纯软解）',
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    final keys = _decoders.keys.toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: '硬件解码器',
          subtitle: 'MPV 硬解方式，切换后重新进入直播间生效',
          icon: Icons.memory_rounded,
          options: keys.map((k) => _decoders[k]!).toList(),
          index: keys.indexOf(playerState.videoHardwareDecoder).clamp(0, keys.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(videoHardwareDecoder: keys[i])),
        ),
        TvSettingsSwitchTile(
          title: '兼容模式',
          subtitle: '部分平台硬解异常时可尝试开启',
          icon: Icons.build_rounded,
          value: playerState.playerCompatMode,
          onChanged: (v) => player.updateSettings(playerState.copyWith(playerCompatMode: v)),
        ),
        TvSettingsSwitchTile(
          title: '退出时强制停止',
          subtitle: '退出直播间时直接终止播放器进程',
          icon: Icons.power_settings_new_rounded,
          value: playerState.useHardStopOnExit,
          onChanged: (v) => player.updateSettings(playerState.copyWith(useHardStopOnExit: v)),
        ),
      ],
    );
  }
}
