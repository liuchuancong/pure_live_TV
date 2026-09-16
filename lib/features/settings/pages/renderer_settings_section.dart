import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('video_output_driver')),
        TvSettingsCard(
          children: [
            TvSettingsOptionTile(
              title: i18n('video_output_driver'),
              // 自定义驱动与硬件加速 (kernel page) is what puts --vo on the mpv
              // command line; without it this choice is ignored. The fallback
              // keeps the row readable even if the translation entry is lost,
              // instead of printing the raw key.
              subtitle:
                  '${i18n('ui_mpv_video_output')} · '
                  '${i18nOr('ui_takes_effect_only_with_custom_player_output', i18n('custom_output_hwdec'))}',
              icon: Icons.graphic_eq_rounded,
              options: [for (final String key in keys) PlayerConsts.optionLabelFor(PlayerConsts.videoRenderersList, key, languageCode)],
              index: keys.indexOf(playerState.videoOutputDriver).clamp(0, keys.length - 1),
              onChanged: (i) => player.updateSettings(playerState.copyWith(videoOutputDriver: keys[i])),
            ),
          ],
        ),
        SizedBox(height: 24.sp),
      ],
    );
  }
}
