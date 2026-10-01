import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/modules/vod/controllers/music_player_controller.dart';

/// Music-mode settings (music's own section, separate from live/video):
/// the defaults the shared VOD engine boots with in music mode.
///
/// Values persist in the music module's Hive keys; the player controller
/// reads them on its first build of a session and music pages no longer
/// hard-code `audioOnly: true`, so the user's choice actually rules.
class MusicSettingsSectionPage extends ConsumerWidget {
  const MusicSettingsSectionPage({super.key});

  static const String _playModeKey = 'musicDefaultPlayMode';
  static const String _audioOnlyKey = 'musicDefaultAudioOnly';
  static const String _resumeKey = 'musicResumeOnOpen';
  static const String _bottomProgressKey = 'musicPlayerProgressBar';
  static const String _sleepFinishCurrentKey = 'musicSleepFinishCurrent';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedMode = MusicPlayMode.values.where((m) => m.name == HivePrefUtil.getString(_playModeKey)).firstOrNull;
    final modeIndex = switch (savedMode ?? MusicPlayMode.sequence) {
      MusicPlayMode.sequence => 0,
      MusicPlayMode.loopOne => 1,
      MusicPlayMode.random => 2,
      MusicPlayMode.orderStop => 3,
    };
    final audioOnly = HivePrefUtil.getString(_audioOnlyKey) != 'false';
    final resumeOnOpen = HivePrefUtil.getString(_resumeKey) == 'true';
    final bottomProgress = HivePrefUtil.getString(_bottomProgressKey) != 'false';
    final sleepMinutes = ref.watch(musicPlayerControllerProvider.select((s) => s.sleepMinutes));
    final sleepFinishCurrent = HivePrefUtil.getString(_sleepFinishCurrentKey) == 'true';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('music_playback_defaults')),
        TvSettingsCard(
          children: [
            TvSettingsOptionTile(
              title: i18n('music_default_play_mode'),
              subtitle: i18n('music_default_play_mode_desc'),
              icon: Remix.repeat_2_line,
              options: [
                i18n('music_mode_sequence'),
                i18n('music_mode_loop_one'),
                i18n('music_mode_random'),
                i18n('music_mode_order_stop'),
              ],
              index: modeIndex,
              onChanged: (index) {
                final mode = switch (index) {
                  1 => MusicPlayMode.loopOne,
                  2 => MusicPlayMode.random,
                  3 => MusicPlayMode.orderStop,
                  _ => MusicPlayMode.sequence,
                };
                HivePrefUtil.setString(_playModeKey, mode.name);
                // The bar's mode button is gone (space + stray presses): this
                // option is the only selector, so it re-rules the live queue
                // too, not just future sessions.
                ref.read(musicPlayerControllerProvider.notifier).setPlayMode(mode);
              },
            ),
            TvSettingsNavTile(
              title: i18n('music_sleep_timer'),
              subtitle: sleepMinutes > 0 ? '$sleepMinutes ${i18n('music_sleep_minutes_unit')}' : i18n('music_sleep_timer_desc'),
              icon: Remix.timer_2_line,
              trailing: sleepMinutes > 0
                  ? Text(
                      i18n('music_sleep_armed'),
                      style: AppTextStyles.t16.copyWith(color: context.tvTheme.focusColor),
                    )
                  : null,
              onTap: () => _showSleepTimerDialog(context, ref),
            ),
            TvSettingsSwitchTile(
              title: i18n('music_sleep_finish_current'),
              subtitle: i18n('music_sleep_finish_current_desc'),
              icon: Remix.skip_forward_line,
              value: sleepFinishCurrent,
              onChanged: (v) => HivePrefUtil.setString(_sleepFinishCurrentKey, v ? 'true' : 'false'),
            ),
            TvSettingsSwitchTile(
              title: i18n('music_default_audio_only'),
              subtitle: i18n('music_default_audio_only_desc'),
              icon: audioOnly ? Remix.headphone_line : Remix.film_line,
              value: audioOnly,
              onChanged: (v) => HivePrefUtil.setString(_audioOnlyKey, v ? 'true' : 'false'),
            ),
            TvSettingsSwitchTile(
              title: i18n('music_resume_on_open'),
              subtitle: i18n('music_resume_on_open_desc'),
              icon: Remix.play_circle_line,
              value: resumeOnOpen,
              onChanged: (v) => HivePrefUtil.setString(_resumeKey, v ? 'true' : 'false'),
            ),
            TvSettingsSwitchTile(
              title: i18n('music_bottom_progress'),
              subtitle: i18n('music_bottom_progress_desc'),
              icon: Icons.linear_scale_rounded,
              value: bottomProgress,
              onChanged: (v) => HivePrefUtil.setString(_bottomProgressKey, v ? 'true' : 'false'),
            ),
          ],
        ),
        SizedBox(height: 20.ts(context)),
      ],
    );
  }

  /// The sleep timer choices: a countdown length (or off). The "finish the
  /// current track" behaviour is the switch below, read when the countdown
  /// expires.
  void _showSleepTimerDialog(BuildContext context, WidgetRef ref) {
    final controller = ref.read(musicPlayerControllerProvider.notifier);

    TvDialogUtils.show<void>(
      context: context,
      builder: (_) => TvDialog(
        title: i18n('music_sleep_timer'),
        cancelText: i18n('cancel'),
        width: 480.ts(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final minutes in const <int>[15, 30, 45, 60, 90])
              TvDialogOptionTile(
                title: '$minutes ${i18n('music_sleep_minutes_unit')}',
                icon: Icon(Icons.bedtime_rounded, size: 26.ts(context), color: context.tvTheme.focusColor),
                showCheck: false,
                autofocus: minutes == 30,
                onTap: () {
                  Navigator.of(context).pop();
                  controller.setSleepTimer(minutes);
                },
              ),
            TvDialogOptionTile(
              title: i18n('music_sleep_off'),
              icon: Icon(Icons.close_rounded, size: 26.ts(context), color: Colors.redAccent),
              showCheck: false,
              onTap: () {
                Navigator.of(context).pop();
                controller.setSleepTimer(0);
              },
            ),
          ],
        ),
      ),
    );
  }
}
