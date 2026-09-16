import 'package:pure_live/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';


class AudioOutputSettingsSectionPage extends ConsumerWidget {
  const AudioOutputSettingsSectionPage({super.key});

  /// Common audio output drivers offered by the settings UI.
  static final Map<String, String> _drivers = {
    'auto': i18n('ui_auto'),
    'null': i18n('ui_null_no_audio_output'),
    'pulse': 'PulseAudio（Linux）',
    'alsa': i18n('ui_alsa_linux_only'),
    'jack': i18n('ui_jack_linux_macos_low_latency'),
    'directsound': i18n('ui_directsound_windows_only'),
    'wasapi': i18n('ui_wasapi_windows_only'),
    'coreaudio': i18n('ui_coreaudio_macos_only'),
    'opensles': i18n('ui_opensl_es_android_only'),
    'audiotrack': i18n('ui_audiotrack_android_only'),
    'aaudio': i18n('ui_aaudio_android_only'),
    'sdl': i18n('ui_sdl_cross_platform'),
    'openal': i18n('ui_openal_cross_platform'),
    'pcm': i18n('ui_pcm_cross_platform'),
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
          title: i18n('audio_output_driver'),
          subtitle: i18n('ui_mpv_audio_output'),
          icon: Icons.surround_sound_rounded,
          options: keys.map((k) => _drivers[k]!).toList(),
          index: keys.indexOf(playerState.audioOutputDriver).clamp(0, keys.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(audioOutputDriver: keys[i])),
        ),
      ],
    );
  }
}
