import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/index.dart';

/// Video settings.
///
/// Only rows that mean something on a TV live here: the video fit, the preferred
/// quality, the viewer metrics and the danmaku group (appearance, font, block
/// list). The mobile/desktop app's cellular fallback quality, background play,
/// "fullscreen by default" and "keep the screen on" switches are deliberately
/// absent: a TV has no cellular link, the playback page *is* the fullscreen
/// page, and the screen is always kept awake while a room is open.
class VideoSettingsSectionPage extends ConsumerWidget {
  const VideoSettingsSectionPage({super.key});

  static final _fitNames = [i18n('ui_default_fit'), i18n('ui_crop_to_center'), i18n('ui_stretch_to_fill'), i18n('ui_fit_height'), i18n('ui_fit_width'), i18n('ui_scale_down_to_fit')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    final List<String> resolutions = PlayerConsts.resolutions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Quality
        TvSettingsOptionTile(
          title: i18n('ui_aspect_ratio'),
          subtitle: i18n('ui_how_the_video_fits_the_screen'),
          icon: Remix.aspect_ratio_line,
          options: _fitNames,
          index: playerState.videoFitIndex.clamp(0, _fitNames.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(videoFitIndex: i)),
        ),
        TvSettingsOptionTile(
          title: i18n('prefer_resolution'),
          subtitle: i18n('prefer_resolution_subtitle'),
          icon: Remix.hd_line,
          options: resolutions,
          index: PlayerConsts.resolutionKeys
              .indexOf(PlayerConsts.normalizeResolutionKey(playerState.preferResolution))
              .clamp(0, resolutions.length - 1),
          onChanged: (i) => player.changePreferResolution(PlayerConsts.resolutionKeys[i]),
        ),
        // Playback behaviour
        TvSettingsNavTile(
          title: i18n('audience_metric_settings'),
          subtitle: i18n('audience_metric_settings_desc'),
          icon: Icons.groups_2_rounded,
          onTap: () => context.push(AppRoutes.kSettingsAudience),
        ),
        // Danmaku
        TvSettingsNavTile(
          title: i18n('danmaku_settings'),
          subtitle: i18n('ui_show_danmaku_inside_live_rooms'),
          icon: Remix.chat_settings_line,
          onTap: () => context.push(AppRoutes.kSettingsDanmaku),
        ),
        TvSettingsNavTile(
          title: i18n('change_danmaku_font_family'),
          icon: Remix.font_size,
          onTap: () => context.push(AppRoutes.kSettingsFontFamily),
        ),
        TvSettingsNavTile(
          title: i18n('danmaku_filter'),
          icon: Remix.filter_2_line,
          onTap: () => context.push(AppRoutes.kSettingsDanmuShield),
        ),
      ],
    );
  }
}
