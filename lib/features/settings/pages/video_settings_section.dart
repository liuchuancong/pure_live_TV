import 'dart:async';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:pure_live/features/settings/pages/widgets/video_danmaku_settings_group.dart';
import 'package:pure_live/features/settings/pages/widgets/video_playback_settings_group.dart';
import 'package:pure_live/features/settings/pages/widgets/video_interface_settings_group.dart';

/// Video settings in newBV's settings shape: a left menu of groups over a
/// settings pages: what a video opens at (quality/speed/detail-first), where
/// the mode lands (startup section, top tabs), and the player surface toggles.
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

  static const _groups = ['video_settings_playback', 'video_settings_interface', 'video_settings_danmaku'];

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---------------------------------------------- the left group menu
        SizedBox(
          width: 300.ts(context),
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
                    padding: EdgeInsets.symmetric(horizontal: 24.ts(context), vertical: 18.ts(context)),
                    decoration: BoxDecoration(
                      // The active group reads as newBV's left menu item: a
                      // filled dark pill while selected, the tinted card on
                      // focus.
                      color: _group == index
                          ? tvTheme.focusedCardColor
                          : focused
                          ? tvTheme.focusedCardColor.withValues(alpha: 0.7)
                          : tvTheme.cardColor,
                      borderRadius: BorderRadius.circular(20.ts(context)),
                      border: Border.all(
                        color: focused ? tvTheme.focusColor : Colors.transparent,
                        width: 2.ts(context),
                      ),
                    ),
                    child: Text(
                      i18n(labelKey),
                      style: AppTextStyles.t20.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _group == index ? tvTheme.primaryTextColor : tvTheme.secondaryTextColor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(width: 32.ts(context)),
        // ------------------------------------------- the right content pane
        Expanded(
          child: switch (_group) {
            0 => const VideoPlaybackSettingsGroup(),
            1 => const VideoInterfaceSettingsGroup(),
            _ => const VideoDanmakuSettingsGroup(),
          },
        ),
      ],
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
