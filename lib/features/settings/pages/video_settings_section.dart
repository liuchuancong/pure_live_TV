import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/widgets/tv_settings_switch_tile.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

class VideoSettingsSectionPage extends ConsumerWidget {
  VideoSettingsSectionPage({super.key});

  static final _fitNames = [i18n('ui_default_fit'), i18n('ui_crop_to_center'), i18n('ui_stretch_to_fill'), i18n('ui_fit_height'), i18n('ui_fit_width'), i18n('ui_scale_down_to_fit')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: i18n('ui_aspect_ratio'),
          subtitle: i18n('ui_how_the_video_fits_the_screen'),
          icon: Icons.aspect_ratio_rounded,
          options: _fitNames,
          index: playerState.videoFitIndex.clamp(0, _fitNames.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(videoFitIndex: i)),
        ),
        TvSettingsSwitchTile(
          title: i18n('ui_hardware_decoding'),
          subtitle: i18n('ui_use_hardware_decoding_to_lower_cpu_usage'),
          icon: Icons.memory_rounded,
          value: playerState.enableCodec,
          onChanged: (v) => player.updateSettings(playerState.copyWith(enableCodec: v)),
        ),
      ],
    );
  }
}
