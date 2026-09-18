import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

/// audio output driver(--ao).
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
    final String currentKey = keys[keys.indexOf(playerState.audioOutputDriver).clamp(0, keys.length - 1)];

    // The options ARE the page (the mobile audio page is a bare list too); it
    // used to be one row named after the page that opened a selection dialog.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('audio_output_driver')),
        if (!playerState.customPlayerOutput)
          Padding(
            padding: EdgeInsets.only(left: 8.sp, bottom: 8.sp, right: 8.sp),
            child: Text(
              i18nOr('ui_takes_effect_only_with_custom_player_output', i18n('custom_output_hwdec')),
              style: AppTextStyles.t16W500.copyWith(color: context.tvTheme.secondaryTextColor),
            ),
          ),
        TvSettingsCard(
          children: [
            for (final String key in keys)
              TvSettingsNavTile(
                title: PlayerConsts.optionLabelFor(PlayerConsts.audioOutputDriversList, key, languageCode),
                icon: key == currentKey ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                trailing: key == currentKey
                    ? Icon(Icons.check_rounded, size: 26.sp, color: context.tvTheme.focusColor)
                    : const SizedBox.shrink(),
                onTap: () => player.updateSettings(playerState.copyWith(audioOutputDriver: key)),
              ),
          ],
        ),
        SizedBox(height: 24.sp),
      ],
    );
  }
}
