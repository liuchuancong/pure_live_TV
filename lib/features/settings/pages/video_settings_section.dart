import 'dart:async';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:pure_live/app/router/app_router.dart';

/// Video settings in newBV's settings shape: a left menu of groups over a
/// right content pane (播放设置 / 弹幕设置). The groups hold the same rows the
/// mobile page ordered top-to-bottom — audio → playback behavior, then danmaku.
///
/// quality and line are *not* settings here: on a TV both are switched from the
/// fullscreen control bar while watching (`VideoControllerPanel`), which is also
/// where aspect ratio lives. The mobile page's cellular quality, background play,
/// ASMR, PiP/window, "fullscreen by default" and "keep the screen on" rows are
/// absent for the same reason: they describe a phone or a desktop.
class VideoSettingsSectionPage extends ConsumerStatefulWidget {
  const VideoSettingsSectionPage({super.key});

  @override
  ConsumerState<VideoSettingsSectionPage> createState() => _VideoSettingsSectionPageState();
}

class _VideoSettingsSectionPageState extends ConsumerState<VideoSettingsSectionPage> {
  int _group = 0;

  static const _groups = ['video_settings_playback', 'video_settings_danmaku'];

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------- the left group menu
        SizedBox(
          width: 300.sp,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, labelKey) in _groups.indexed)
                TvFocusable(
                  key: ValueKey('video_settings_group_$index'),
                  autofocus: index == 0,
                  onTap: () => setState(() => _group = index),
                  builder: (context, focused, _) => AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    curve: Curves.easeOutCubic,
                    padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 18.sp),
                    decoration: BoxDecoration(
                      // The active group reads as newBV's left menu item: a
                      // filled dark pill while selected, the tinted card on
                      // focus.
                      color: _group == index
                          ? tvTheme.focusedCardColor
                          : focused
                          ? tvTheme.focusedCardColor.withValues(alpha: 0.7)
                          : tvTheme.cardColor,
                      borderRadius: BorderRadius.circular(20.sp),
                      border: Border.all(
                        color: focused ? tvTheme.focusColor : Colors.transparent,
                        width: 2.sp,
                      ),
                    ),
                    child: Text(
                      i18n(labelKey),
                      style: AppTextStyles.t20W600.copyWith(
                        color: _group == index ? tvTheme.primaryTextColor : tvTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 32.sp),
        // ------------------------------------------- the right content pane
        Expanded(
          child: switch (_group) {
            0 => const _PlaybackSettingsGroup(),
            _ => const _DanmakuSettingsGroup(),
          },
        ),
      ],
    );
  }
}

/// The playback group: audio and playback-behavior rows.
class _PlaybackSettingsGroup extends ConsumerWidget {
  const _PlaybackSettingsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    // The mute state picks this row's icon: slashed speaker when muted, regular
    // speaker once sound is on.
    final bool globalMute = ref.watch(volumeSettingsControllerProvider).globalVolumeMute;

    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 4.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('audio_settings')),
          TvSettingsCard(
            children: [
              // global mute is honoured by the player core (`live_room_volume_manager`).
              TvSettingsSwitchTile(
                title: i18n('global_mute'),
                subtitle: i18n('global_mute_subtitle'),
                icon: globalMute ? Remix.volume_mute_line : Remix.volume_up_line,
                value: globalMute,
                onChanged: (v) => ref.read(volumeSettingsControllerProvider.notifier).setGlobalVolumeMute(v),
              ),
              // TV-only: the mobile app toggles audio-only from the player
              // controls, so this row lives in the audio group.
              TvSettingsSwitchTile(
                title: i18n('ui_audio_only'),
                subtitle: i18n('ui_audio_only_no_video_rendering'),
                icon: playerState.audioOnly ? Remix.headphone_line : Remix.volume_up_line,
                value: playerState.audioOnly,
                onChanged: (v) {
                  player.updateSettings(playerState.copyWith(audioOnly: v));
                  VideoSettingsSectionPageState.applyAudioOnly(v);
                },
              ),
            ],
          ),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('playback_behavior_settings')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(
                title: i18n('audience_metric_settings'),
                subtitle: i18n('audience_metric_settings_desc'),
                icon: Icons.groups_2_rounded,
                onTap: () => const AudienceSettingsRoute().push(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The danmaku group: the three danmaku destinations.
class _DanmakuSettingsGroup extends ConsumerWidget {
  const _DanmakuSettingsGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(top: 4.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('danmaku_settings')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(
                title: i18n('danmaku_settings'),
                subtitle: i18n('ui_show_danmaku_inside_live_rooms'),
                icon: Remix.chat_settings_line,
                onTap: () => const DanmakuSettingsRoute().push(context),
              ),
              TvSettingsNavTile(
                title: i18n('change_danmaku_font_family'),
                icon: Remix.font_size,
                // Danmaku mode: the selection writes danmakuFontFamilyName and
                // the flame engine picks it up live, instead of the old path
                // that silently changed the whole app font.
                onTap: () => const FontFamilyDanmakuRoute().push(context),
              ),
              TvSettingsNavTile(
                title: i18n('danmaku_filter'),
                icon: Remix.filter_2_line,
                onTap: () => const DanmuShieldRoute().push(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class VideoSettingsSectionPageState {
  /// Pushes audio only into the running player instead of only storing it.
  static void applyAudioOnly(bool value) {
    final service = GlobalPlayerService.instance;
    if (!service.initialized) return;
    unawaited(service.livePlayer?.setAudioOnly(value));
  }
}
