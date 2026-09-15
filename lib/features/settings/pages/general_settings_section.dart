import 'package:pure_live/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/services/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;

class GeneralSettingsSectionPage extends ConsumerWidget {
  const GeneralSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appSettingsControllerProvider);
    final app = ref.read(appSettingsControllerProvider.notifier);
    final exitState = ref.watch(exitSettingsControllerProvider);
    final exit = ref.read(exitSettingsControllerProvider.notifier);
    final themeState = ref.watch(themeSettingsControllerProvider);
    final theme = ref.read(themeSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: i18n('language'),
          subtitle: i18n('language'),
          icon: Remix.global_line,
          options: AppConsts.languages.keys.toList(growable: false),
          index: _languageIndex(themeState.languageName),
          onChanged: (i) {
            final languageName = AppConsts.languages.keys.elementAt(i);
            theme.changeLanguage(languageName);
            final locale = AppConsts.languages[languageName];
            if (locale != null) context.setLocale(Locale(locale.languageCode));
          },
        ),
        TvSettingsSwitchTile(
          title: i18n('ui_dense_favorites_layout'),
          subtitle: i18n('ui_use_a_denser_card_layout_on_the_favorites_page'),
          icon: Icons.view_comfy_rounded,
          value: appState.enableDenseFavorites,
          onChanged: (v) => app.update(appState.copyWith(enableDenseFavorites: v)),
        ),
        TvSettingsSwitchTile(
          title: i18n('enable_background_play'),
          subtitle: i18n('ui_keep_playing_audio_after_leaving_the_room'),
          icon: Remix.music_2_line,
          value: appState.enableBackgroundPlay,
          onChanged: (v) => app.update(appState.copyWith(enableBackgroundPlay: v)),
        ),
        TvSettingsSwitchTile(
          title: i18n('enable_screen_keep_on'),
          subtitle: i18n('ui_keep_the_screen_awake_while_watching'),
          icon: Remix.lightbulb_line,
          value: appState.enableScreenKeepOn,
          onChanged: (v) => app.update(appState.copyWith(enableScreenKeepOn: v)),
        ),
        TvSettingsSwitchTile(
          title: i18n('auto_check_update'),
          subtitle: i18n('ui_check_for_updates_on_startup'),
          icon: Remix.refresh_line,
          value: appState.enableAutoCheckUpdate,
          onChanged: (v) => app.update(appState.copyWith(enableAutoCheckUpdate: v)),
        ),
        TvSettingsSwitchTile(
          title: i18n('ui_fullscreen_by_default'),
          subtitle: i18n('ui_start_in_fullscreen_when_entering_a_room'),
          icon: Remix.fullscreen_line,
          value: appState.enableFullScreenDefault,
          onChanged: (v) => app.update(appState.copyWith(enableFullScreenDefault: v)),
        ),
        TvSettingsSwitchTile(
          title: i18n('ui_exit_without_confirmation'),
          subtitle: i18n('ui_back_key_exits_the_app_directly_without_confirma'),
          icon: Remix.error_warning_line,
          value: exitState.dontAskExit,
          onChanged: (v) => exit.setDontAskExit(v),
        ),
        TvSettingsOptionTile(
          title: i18n('ui_auto_shutdown_countdown'),
          subtitle: i18n('ui_close_the_app_after_a_period_of_inactivity'),
          icon: Remix.timer_line,
          options: [i18n('close'), i18n('ui_30_minutes'), i18n('ui_60_minutes'), i18n('ui_90_minutes'), i18n('ui_120_minutes')],
          index: _shutDownIndex(exitState),
          onChanged: (i) => exit.updateConfig(_shutDownConfig(exitState, i)),
        ),
      ],
    );
  }

  /// Index of the persisted language inside [AppConsts.languages].
  static int _languageIndex(String languageName) {
    final index = AppConsts.languages.keys.toList(growable: false).indexOf(languageName);
    return index < 0 ? 1 : index;
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
