import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/modules/media/controllers/music_player_controller.dart';
import 'package:pure_live/modules/media/models/models.dart';

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedMode = MusicPlayMode.values
        .where((m) => m.name == HivePrefUtil.getString(_playModeKey))
        .firstOrNull;
    final modeIndex = switch (savedMode ?? MusicPlayMode.sequence) {
      MusicPlayMode.sequence => 0,
      MusicPlayMode.loopOne => 1,
      MusicPlayMode.random => 2,
    };
    final audioOnly = HivePrefUtil.getString(_audioOnlyKey) != 'false';
    final resumeOnOpen = HivePrefUtil.getString(_resumeKey) == 'true';
    final bottomProgress = HivePrefUtil.getString(_bottomProgressKey) != 'false';

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
              ],
              index: modeIndex,
              onChanged: (index) {
                final mode = switch (index) {
                  1 => MusicPlayMode.loopOne,
                  2 => MusicPlayMode.random,
                  _ => MusicPlayMode.sequence,
                };
                HivePrefUtil.setString(_playModeKey, mode.name);
                // The bar's mode button is gone (space + stray presses): this
                // option is the only selector, so it re-rules the live queue
                // too, not just future sessions.
                ref.read(musicPlayerControllerProvider.notifier).setPlayMode(mode);
              },
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
        SizedBox(height: 20.sp),
      ],
    );
  }
}
