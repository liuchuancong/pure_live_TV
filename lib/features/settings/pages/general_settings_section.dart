import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// General settings, in the desktop app's order: update checking, the shutdown
/// countdown, then the exit prompt.
///
/// Language lives on the theme page. The desktop app's background play,
/// fullscreen and keep-screen-on switches are TV-irrelevant and do not exist
/// here (see the video page).
class GeneralSettingsSectionPage extends ConsumerWidget {
  const GeneralSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appSettingsControllerProvider);
    final app = ref.read(appSettingsControllerProvider.notifier);
    final exitState = ref.watch(exitSettingsControllerProvider);
    final exit = ref.read(exitSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('general')),
        TvSettingsCard(
          children: [
            TvSettingsSwitchTile(
              title: i18n('auto_check_update'),
              subtitle: i18n('ui_check_for_updates_on_startup'),
              icon: Remix.refresh_line,
              value: appState.enableAutoCheckUpdate,
              onChanged: (v) => app.update(appState.copyWith(enableAutoCheckUpdate: v)),
            ),
            TvSettingsOptionTile(
              title: i18n('enable_countdown_close'),
              subtitle: i18n('ui_close_the_app_after_a_period_of_inactivity'),
              icon: Remix.timer_line,
              options: [
                i18n('close'),
                i18n('ui_30_minutes'),
                i18n('ui_60_minutes'),
                i18n('ui_90_minutes'),
                i18n('ui_120_minutes'),
              ],
              index: _shutDownIndex(exitState),
              onChanged: (i) => exit.updateConfig(_shutDownConfig(exitState, i)),
            ),
            TvSettingsSwitchTile(
              title: i18n('ui_exit_without_confirmation'),
              subtitle: i18n('ui_back_key_exits_the_app_directly_without_confirma'),
              icon: Remix.error_warning_line,
              value: exitState.dontAskExit,
              onChanged: (v) => exit.setDontAskExit(v),
            ),
            // The old favourites-only dense-layout switch used to sit here; the
            // room-card column count on the theme page's grid-spacing page
            // replaced it and applies to every room-card grid.
          ],
        ),
      ],
    );
  }

  static int _shutDownIndex(ExitSettingsModel exitState) {
    if (!exitState.enableAutoShutDownTime) return 0;
    return switch (exitState.autoShutDownTime) {
      30 => 1,
      60 => 2,
      90 => 3,
      _ => 4,
    };
  }

  static ExitSettingsModel _shutDownConfig(ExitSettingsModel exitState, int index) {
    final minutes = switch (index) {
      0 => 120,
      1 => 30,
      2 => 60,
      3 => 90,
      _ => 120,
    };
    return exitState.copyWith(enableAutoShutDownTime: index != 0, autoShutDownTime: minutes);
  }
}
