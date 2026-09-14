import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/widgets/tv_settings_switch_tile.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

class DecoderSettingsSectionPage extends ConsumerWidget {
  DecoderSettingsSectionPage({super.key});

  /// Common hardware decoders offered by the settings UI.
  static final Map<String, String> _decoders = {
    'auto': i18n('ui_use_any_available_decoder'),
    'auto-safe': i18n('ui_use_the_best_decoder'),
    'auto-copy': i18n('ui_use_the_best_decoder_with_copy_back_support'),
    'd3d11va': 'DirectX 11（Windows 8+）',
    'd3d11va-copy': i18n('ui_directx_11_no_passthrough'),
    'mediacodec': 'MediaCodec（Android）',
    'mediacodec-copy': i18n('ui_mediacodec_android_no_passthrough'),
    'videotoolbox': 'VideoToolbox（macOS / iOS）',
    'vaapi': 'VAAPI（Linux）',
    'nvdec': i18n('ui_nvdec_nvidia_only'),
    'no': i18n('ui_software_decoding_only'),
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
          title: i18n('ui_hardware_decoder'),
          subtitle: i18n('ui_mpv_hardware_decoding_takes_effect_after_re_ente'),
          icon: Icons.memory_rounded,
          options: keys.map((k) => _decoders[k]!).toList(),
          index: keys.indexOf(playerState.videoHardwareDecoder).clamp(0, keys.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(videoHardwareDecoder: keys[i])),
        ),
        TvSettingsSwitchTile(
          title: i18n('compat_mode'),
          subtitle: i18n('ui_enable_when_hardware_decoding_misbehaves_on_some'),
          icon: Icons.build_rounded,
          value: playerState.playerCompatMode,
          onChanged: (v) => player.updateSettings(playerState.copyWith(playerCompatMode: v)),
        ),
        TvSettingsSwitchTile(
          title: i18n('ui_force_stop_on_exit'),
          subtitle: i18n('ui_terminate_the_player_process_when_leaving_the_ro'),
          icon: Icons.power_settings_new_rounded,
          value: playerState.useHardStopOnExit,
          onChanged: (v) => player.updateSettings(playerState.copyWith(useHardStopOnExit: v)),
        ),
      ],
    );
  }
}
