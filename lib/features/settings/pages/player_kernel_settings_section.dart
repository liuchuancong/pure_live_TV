import 'dart:async';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/services/player_settings/player_settings_controller.dart';

/// 播放器内核设置.
///
/// The rows, their order, the group headings and the labels follow the mobile
/// page (`pure_live/lib/modules/settings/pages/player_kernel_settings_page.dart`):
/// 核心内核设置 first, then — for the MPV kernel only — 兼容模式 (Android),
/// MPV 高级设置 (warning/official docs, reset, the driver sub-pages) and
/// 音频设置.
class PlayerKernelSettingsSectionPage extends ConsumerWidget {
  const PlayerKernelSettingsSectionPage({super.key});

  /// Where the reference page sends its 官方文档 link.
  static final Uri _mpvDocsUri = Uri.parse('https://mpv.io');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    final String languageCode = Localizations.localeOf(context).languageCode;
    // 内核名来自 PlayerConsts.names，和移动端同一个 i18n 源（原来这里写死了英文）。
    final List<String> engineKeys = PlayerConsts.engines.keys.toList(growable: false);
    // A key stored by another platform/build may no longer exist; fall back to
    // MPV both for the selected row and for the mpv-only section below.
    final String activeEngineKey = PlayerConsts.engines.containsKey(playerState.videoPlayerKey)
        ? playerState.videoPlayerKey
        : PlayerConsts.defaultKey;
    final bool isMpv = activeEngineKey == PlayerConsts.defaultKey;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('core_kernel_settings')),
        TvSettingsCard(
          children: [
            TvSettingsOptionTile(
              title: i18n('kernel_switch'),
              subtitle: i18n('kernel_switch_subtitle'),
              icon: Remix.toggle_line,
              options: [for (final String key in engineKeys) i18n(PlayerConsts.names[key] ?? key)],
              index: engineKeys.indexOf(activeEngineKey).clamp(0, engineKeys.length - 1),
              onChanged: (index) => _selectEngine(ref, engineKeys[index]),
            ),
            TvSettingsSwitchTile(
              title: i18n('enable_codec'),
              subtitle: i18n('gpu_decode'),
              icon: Remix.speed_up_line,
              value: playerState.enableCodec,
              onChanged: (v) => player.updateSettings(playerState.copyWith(enableCodec: v)),
            ),
            // 仅播放音频 is a TV row: the mobile app toggles audio-only from the
            // playback controls instead. It is wired into the native players
            // (`PlayerManager.setAudioOnly`), not just stored.
            TvSettingsSwitchTile(
              title: i18n('ui_audio_only'),
              subtitle: i18n('ui_audio_only_no_video_rendering'),
              icon: Remix.headphone_line,
              value: playerState.audioOnly,
              onChanged: (v) {
                player.updateSettings(playerState.copyWith(audioOnly: v));
                _applyAudioOnly(v);
              },
            ),
            TvSettingsSwitchTile(
              title: i18n('force_destroy_player'),
              subtitle: i18n('force_destroy_player_subtitle'),
              icon: Remix.shut_down_line,
              value: playerState.useHardStopOnExit,
              onChanged: (v) => player.updateSettings(playerState.copyWith(useHardStopOnExit: v)),
            ),
          ],
        ),
        // The reference page shows everything below only for the MPV kernel,
        // because these settings configure mpv itself.
        if (isMpv) ...[
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('mpv_advanced_settings')),
          TvSettingsCard(
            children: [
              if (Platform.isAndroid)
                TvSettingsSwitchTile(
                  title: i18n('compat_mode'),
                  subtitle: i18n('compat_mode_subtitle'),
                  icon: Remix.shield_check_line,
                  value: playerState.playerCompatMode,
                  onChanged: (v) => player.updateSettings(playerState.copyWith(playerCompatMode: v)),
                ),
              TvSettingsSwitchTile(
                title: i18n('custom_output_hwdec'),
                subtitle: i18n('ui_force_an_output_driver_instead_of_auto_negoti'),
                icon: Remix.equalizer_line,
                value: playerState.customPlayerOutput,
                onChanged: (v) => player.updateSettings(playerState.copyWith(customPlayerOutput: v)),
              ),
              // The reference row pairs the warning with an 官方文档 link and a
              // red reset button. A TV row is one focus stop, so the link gets
              // its own row (warning as its subtitle) and the reset its own.
              TvSettingsNavTile(
                title: i18n('mpv_official_docs'),
                subtitle: i18n('mpv_warning_text'),
                icon: Remix.book_open_line,
                onTap: () => launchUrl(_mpvDocsUri, mode: LaunchMode.externalApplication),
              ),
              TvSettingsNavTile(
                title: i18n('reset'),
                subtitle: i18n('ui_reset_all_mpv_advanced_settings_to_defaults'),
                icon: Remix.restart_line,
                onTap: player.resetMpvPlayerSettings,
              ),
              // Sub-page rows show the current choice, like the reference.
              TvSettingsNavTile(
                title: i18n('hardware_decoder'),
                subtitle: PlayerConsts.optionLabelFor(
                  PlayerConsts.hardwareDecodersList,
                  playerState.videoHardwareDecoder,
                  languageCode,
                  fallback: i18n('ui_software_decoding_only'),
                ),
                icon: Remix.cpu_line,
                onTap: () => context.push(AppRoutes.kSettingsDecoder),
              ),
              TvSettingsNavTile(
                title: i18n('video_output_driver'),
                subtitle: PlayerConsts.optionLabelFor(
                  PlayerConsts.videoRenderersList,
                  playerState.videoOutputDriver,
                  languageCode,
                ),
                icon: Remix.tv_line,
                onTap: () => context.push(AppRoutes.kSettingsRenderer),
              ),
            ],
          ),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('audio_settings')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(
                title: i18n('audio_output_driver'),
                subtitle: PlayerConsts.optionLabelFor(
                  PlayerConsts.audioOutputDriversList,
                  playerState.audioOutputDriver,
                  languageCode,
                ),
                icon: Remix.volume_up_line,
                onTap: () => context.push(AppRoutes.kSettingsAudioOutput),
              ),
            ],
          ),
        ],
        SizedBox(height: 24.sp),
      ],
    );
  }

  /// Stores the chosen kernel and moves the live player onto it.
  ///
  /// Writing `videoPlayerKey` alone only reaches the next player that is
  /// created from scratch — this app warms the media_kit kernel when the
  /// playback page boots, so without the switch the row had no visible effect.
  /// The reference page does the same (`switchEngine(..., isManual: true)`).
  void _selectEngine(WidgetRef ref, String key) {
    final controller = ref.read(playerSettingsControllerProvider.notifier);
    controller.updateSettings(ref.read(playerSettingsControllerProvider).copyWith(videoPlayerKey: key));

    final engine = PlayerConsts.engines[key];
    final service = GlobalPlayerService.instance;
    if (engine == null || !service.initialized) return;

    unawaited(
      service.playerManager.switchEngine(engine, isManual: true).catchError((Object error, StackTrace stackTrace) {
        debugPrint('Switch player kernel to $key failed: $error');
      }),
    );
  }

  /// Pushes 仅播放音频 into the running player instead of only storing it.
  void _applyAudioOnly(bool value) {
    final service = GlobalPlayerService.instance;
    if (!service.initialized) return;
    unawaited(service.playerManager.setAudioOnly(value));
  }
}
