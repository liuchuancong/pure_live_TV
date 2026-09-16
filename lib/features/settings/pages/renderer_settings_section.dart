import 'package:pure_live/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

class RendererSettingsSectionPage extends ConsumerWidget {
  const RendererSettingsSectionPage({super.key});

  /// Video output drivers offered by the settings UI.
  static final Map<String, String> _drivers = {
    'auto': i18n('ui_auto'),
    'gpu': 'GPU',
    'gpu-next': 'GPU Next',
    'sdl': 'SDL',
    'null': i18n('ui_null_no_video_output'),
    'mediacodec_embed': i18n('ui_mediacodec_embed_android_only'),
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
          title: i18n('video_output_driver'),
          subtitle: i18n('ui_mpv_video_output'),
          icon: Icons.graphic_eq_rounded,
          options: keys.map((k) => _drivers[k]!).toList(),
          index: keys.indexOf(playerState.videoOutputDriver).clamp(0, keys.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(videoOutputDriver: keys[i])),
        ),
        TvSettingsSwitchTile(
          title: i18n('ui_custom_player_output'),
          subtitle: i18n('ui_force_an_output_driver_instead_of_auto_negotiati'),
          icon: Icons.tune_rounded,
          value: playerState.customPlayerOutput,
          onChanged: (v) => player.updateSettings(playerState.copyWith(customPlayerOutput: v)),
        ),
      ],
    );
  }
}
