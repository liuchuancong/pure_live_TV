import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

class VideoSettingsSectionPage extends ConsumerWidget {
  const VideoSettingsSectionPage({super.key});

  static final _fitNames = [i18n('ui_default_fit'), i18n('ui_crop_to_center'), i18n('ui_stretch_to_fill'), i18n('ui_fit_height'), i18n('ui_fit_width'), i18n('ui_scale_down_to_fit')];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: i18n('ui_aspect_ratio'),
          subtitle: i18n('ui_how_the_video_fits_the_screen'),
          icon: Remix.aspect_ratio_line,
          options: _fitNames,
          index: playerState.videoFitIndex.clamp(0, _fitNames.length - 1),
          onChanged: (i) => player.updateSettings(playerState.copyWith(videoFitIndex: i)),
        ),
        TvSettingsSwitchTile(
          title: i18n('ui_hardware_decoding'),
          subtitle: i18n('ui_use_hardware_decoding_to_lower_cpu_usage'),
          // Same icon the desktop app uses for this switch.
          icon: Remix.speed_up_line,
          value: playerState.enableCodec,
          onChanged: (v) => player.updateSettings(playerState.copyWith(enableCodec: v)),
        ),
        // Sub-pages the desktop video page hosts, in its order: viewer metrics,
        // picture-in-picture danmaku, the danmaku font and the block list. The
        // danmaku appearance page is TV-only, so it leads this block.
        TvSettingsNavTile(
          title: i18n('danmaku_settings'),
          subtitle: i18n('ui_show_danmaku_inside_live_rooms'),
          icon: Remix.chat_settings_line,
          onTap: () => context.push(AppRoutes.kSettingsDanmaku),
        ),
        TvSettingsNavTile(
          title: i18n('audience_metric_settings'),
          subtitle: i18n('audience_metric_settings_desc'),
          icon: Icons.groups_2_rounded,
          onTap: () => context.push(AppRoutes.kSettingsAudience),
        ),
        TvSettingsNavTile(
          title: i18n('pip_danmaku'),
          subtitle: i18n('pip_danmaku_desc'),
          icon: Remix.picture_in_picture_2_line,
          onTap: () => context.push(AppRoutes.kSettingsPipDanmaku),
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
