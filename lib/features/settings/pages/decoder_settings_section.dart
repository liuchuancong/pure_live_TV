import 'package:pure_live/shared/widgets/index.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';


class DecoderSettingsSectionPage extends ConsumerWidget {
  const DecoderSettingsSectionPage({super.key});

  /// Hardware decoders offered by the settings UI.
  ///
  /// Limited to the backends the running platform can actually use. The list
  /// used to offer every backend everywhere, so an Android TV box showed
  /// DirectX 11, VideoToolbox and VAAPI entries that can never take effect on
  /// it.
  static Map<String, String> get _decoders {
    final Map<String, String> common = {
      'auto': i18n('ui_use_any_available_decoder'),
      'auto-safe': i18n('ui_use_the_best_decoder'),
      'auto-copy': i18n('ui_use_the_best_decoder_with_copy_back_support'),
    };
    final Map<String, String> softwareOnly = {'no': i18n('ui_software_decoding_only')};

    if (Platform.isAndroid) {
      return {
        ...common,
        'mediacodec': 'MediaCodec（Android）',
        'mediacodec-copy': i18n('ui_mediacodec_android_no_passthrough'),
        ...softwareOnly,
      };
    }
    if (Platform.isIOS || Platform.isMacOS) {
      return {...common, 'videotoolbox': 'VideoToolbox（macOS / iOS）', ...softwareOnly};
    }
    if (Platform.isWindows) {
      return {
        ...common,
        'd3d11va': 'DirectX 11（Windows 8+）',
        'd3d11va-copy': i18n('ui_directx_11_no_passthrough'),
        'nvdec': i18n('ui_nvdec_nvidia_only'),
        ...softwareOnly,
      };
    }
    // Linux and anything else.
    return {...common, 'vaapi': 'VAAPI（Linux）', 'nvdec': i18n('ui_nvdec_nvidia_only'), ...softwareOnly};
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    final decoders = _decoders;
    final keys = decoders.keys.toList();

    // A decoder saved on another platform (or an older build) is not in this
    // list; show the first entry instead of crashing, and let the next change
    // write a value this platform supports.
    final int storedIndex = keys.indexOf(playerState.videoHardwareDecoder);
    final int safeIndex = storedIndex == -1 ? 0 : storedIndex;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: i18n('ui_hardware_decoder'),
          subtitle: i18n('ui_mpv_hardware_decoding_takes_effect_after_re_ente'),
          icon: Icons.memory_rounded,
          options: keys.map((k) => decoders[k]!).toList(),
          index: safeIndex,
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
