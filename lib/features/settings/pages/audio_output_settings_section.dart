import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

/// 音频输出驱动(--ao).
///
/// The option list is `PlayerConsts.audioOutputDriversList`, i.e. exactly the
/// list the mobile audio page renders
/// (`pure_live/lib/modules/settings/pages/audio_output_settings_page.dart`),
/// labels included — that is where PipeWire, OSS, WinMM, AudioUnit and libao
/// came back.
class AudioOutputSettingsSectionPage extends ConsumerWidget {
  const AudioOutputSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    final String languageCode = Localizations.localeOf(context).languageCode;
    final keys = [for (final item in PlayerConsts.audioOutputDriversList) item['key']!];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('audio_output_driver')),
        TvSettingsCard(
          children: [
            TvSettingsOptionTile(
              title: i18n('audio_output_driver'),
              // 自定义驱动与硬件加速 (kernel page) is what puts --ao on the mpv
              // command line; without it this choice is ignored. The fallback
              // keeps the row readable even if the translation entry is lost,
              // instead of printing the raw key.
              subtitle:
                  '${i18n('ui_mpv_audio_output')} · '
                  '${i18nOr('ui_takes_effect_only_with_custom_player_output', i18n('custom_output_hwdec'))}',
              icon: Icons.surround_sound_rounded,
              options: [
                for (final String key in keys)
                  PlayerConsts.optionLabelFor(PlayerConsts.audioOutputDriversList, key, languageCode),
              ],
              index: keys.indexOf(playerState.audioOutputDriver).clamp(0, keys.length - 1),
              onChanged: (i) => player.updateSettings(playerState.copyWith(audioOutputDriver: keys[i])),
            ),
          ],
        ),
        SizedBox(height: 24.sp),
      ],
    );
  }
}
