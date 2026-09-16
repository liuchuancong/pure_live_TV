import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

/// 视频输出驱动(--vo).
///
/// The option list is `PlayerConsts.videoRenderersList`, i.e. exactly the list
/// the mobile renderer page renders
/// (`pure_live/lib/modules/settings/pages/renderer_settings.dart`), labels
/// included (`VA-API（仅 Linux）`, `CACA（macOS / Linux）`, ...). The Windows,
/// Linux and macOS drivers are kept because the app's own platform contract
/// (`PlayerConsts.videoOutputDrivers` / `mpvVideoOutputDriversForPlatform`)
/// accepts them on every platform but iOS.
class RendererSettingsSectionPage extends ConsumerWidget {
  const RendererSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    final String languageCode = Localizations.localeOf(context).languageCode;
    final keys = [for (final item in PlayerConsts.videoRenderersList) item['key']!];
    final String currentKey = keys[keys.indexOf(playerState.videoOutputDriver).clamp(0, keys.length - 1)];

    // The options ARE the page (the mobile renderer page is a bare list too); it
    // used to be one row named after the page that opened a selection dialog.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('video_output_driver')),
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
                title: PlayerConsts.optionLabelFor(PlayerConsts.videoRenderersList, key, languageCode),
                icon: key == currentKey ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                trailing: key == currentKey
                    ? Icon(Icons.check_rounded, size: 26.sp, color: context.tvTheme.focusColor)
                    : const SizedBox.shrink(),
                onTap: () => player.updateSettings(playerState.copyWith(videoOutputDriver: key)),
              ),
          ],
        ),
        SizedBox(height: 24.sp),
      ],
    );
  }
}
