
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/modules/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

class AudioOutputSettingsSectionPage extends ConsumerWidget {
  const AudioOutputSettingsSectionPage({super.key});

  /// 与 pure_live PlayerConsts.audioOutputDriversList 对齐的常用子集
  static const Map<String, String> _drivers = {
    'auto': '自动选择',
    'null': 'Null（不输出音频）',
    'pulse': 'PulseAudio（Linux）',
    'alsa': 'ALSA（仅 Linux）',
    'jack': 'JACK（Linux / macOS，低延迟）',
    'directsound': 'DirectSound（仅 Windows）',
    'wasapi': 'WASAPI（仅 Windows）',
    'coreaudio': 'CoreAudio（仅 macOS）',
    'opensles': 'OpenSL ES（仅 Android）',
    'audiotrack': 'AudioTrack（仅 Android）',
    'aaudio': 'AAudio（仅 Android）',
    'sdl': 'SDL（跨平台）',
    'openal': 'OpenAL（跨平台）',
    'pcm': 'PCM（跨平台）',
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
          title: '音频输出驱动',
          subtitle: 'MPV 音频输出方式',
          icon: Icons.surround_sound_rounded,
          options: keys.map((k) => _drivers[k]!).toList(),
          index: keys.indexOf(playerState.audioOutputDriver).clamp(0, keys.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(audioOutputDriver: keys[i])),
        ),
      ],
    );
  }
}
