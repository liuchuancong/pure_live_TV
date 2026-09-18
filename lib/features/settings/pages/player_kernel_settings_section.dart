import 'dart:async';
import 'dart:io';

import 'package:url_launcher/url_launcher.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/services/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/app/router/app_router.dart';

/// 播放器内核设置.
///
/// Row-for-row the same as the mobile page
/// (`pure_live/lib/modules/settings/pages/player_kernel_settings_page.dart:31-155`):
///
/// 1. 核心内核设置 — 内核切换 → 网络代理设置 (hidden for the Exo kernel) →
///    开启硬解码 → [启用 RTX VSR, Windows only, not wanted here] → 播放器强制销毁
/// 2. MPV only — 兼容模式 (Android) → MPV 高级设置 heading → the warning/docs/reset
///    cluster → 自定义驱动与硬件加速 → 硬件解码器(--hwdec) → 视频输出驱动(--vo)
/// 3. 音频设置 — 音频输出驱动(--ao)
///
/// 仅播放音频 is deliberately *not* here: the mobile app toggles audio-only from
/// the player controls instead of the settings page, and a TV-only row in the
/// middle of this list broke the order. It lives on the video page's audio group.
class PlayerKernelSettingsSectionPage extends ConsumerWidget {
  const PlayerKernelSettingsSectionPage({super.key});

  /// Where the reference page sends its 官方文档 link.
  static final Uri _mpvDocsUri = Uri.parse('https://mpv.io');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerSettingsControllerProvider);
    final player = ref.read(playerSettingsControllerProvider.notifier);
    final String languageCode = Localizations.localeOf(context).languageCode;
    final List<String> engineKeys = PlayerConsts.engines.keys.toList(growable: false);
    // A key stored by another platform/build may no longer exist; fall back to
    // MPV both for the selected row and for the mpv-only section below.
    final String activeEngineKey = PlayerConsts.engines.containsKey(playerState.videoPlayerKey)
        ? playerState.videoPlayerKey
        : PlayerConsts.defaultKey;
    final bool isMpv = activeEngineKey == PlayerConsts.defaultKey;
    final bool isExo = activeEngineKey == 'exo';
    final bool proxyEnabled = SettingsService.to.proxyState.enableProxy;
    final bool customOutput = playerState.customPlayerOutput;

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
            // The reference hides this row for the Exo kernel, which has no
            // proxy support; everything but Exo keeps it in second position.
            if (!isExo)
              TvSettingsNavTile(
                title: i18n('network_proxy'),
                subtitle: i18n('network_proxy_subtitle'),
                icon: Remix.global_line,
                trailing: Text(
                  proxyEnabled ? i18n('enabled') : i18n('disabled'),
                  style: AppTextStyles.t16W600.copyWith(
                    color: proxyEnabled ? context.tvTheme.focusColor : context.tvTheme.secondaryTextColor,
                  ),
                ),
                onTap: () => const ProxySettingsRoute().push(context),
              ),
            TvSettingsSwitchTile(
              title: i18n('enable_codec'),
              subtitle: i18n('gpu_decode'),
              icon: Remix.speed_up_line,
              value: playerState.enableCodec,
              onChanged: (v) => player.updateSettings(playerState.copyWith(enableCodec: v)),
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
        // Everything below configures mpv itself, so the reference shows it only
        // for the MPV kernel.
        if (isMpv) ...[
          SizedBox(height: 20.sp),
          if (Platform.isAndroid)
            TvSettingsSwitchTile(
              title: i18n('compat_mode'),
              subtitle: i18n('compat_mode_subtitle'),
              icon: Remix.shield_check_line,
              value: playerState.playerCompatMode,
              onChanged: (v) => player.updateSettings(playerState.copyWith(playerCompatMode: v)),
            ),
          SizedBox(height: 8.sp),
          TvSettingsGroupTitle(title: i18n('mpv_advanced_settings')),
          // The reference clusters the warning, the official docs link and the
          // reset above the settings card. A TV row is one focus stop, so the
          // link (warning as its subtitle) and the reset are two rows in that
          // same position — both reference strings are rendered.
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
          SizedBox(height: 8.sp),
          TvSettingsCard(
            children: [
              TvSettingsSwitchTile(
                title: i18n('custom_output_hwdec'),
                icon: Remix.equalizer_line,
                value: customOutput,
                onChanged: (v) => player.updateSettings(playerState.copyWith(customPlayerOutput: v)),
              ),
              // The three driver rows keep position even while the switch above
              // is off; they state that precondition in their own subtitles.
              TvSettingsNavTile(
                title: i18n('hardware_decoder'),
                subtitle: PlayerConsts.optionLabelFor(
                  PlayerConsts.hardwareDecodersList,
                  playerState.videoHardwareDecoder,
                  languageCode,
                  fallback: i18n('ui_software_decoding_only'),
                ),
                icon: Remix.cpu_line,
                onTap: () => const DecoderSettingsRoute().push(context),
              ),
              TvSettingsNavTile(
                title: i18n('video_output_driver'),
                subtitle: PlayerConsts.optionLabelFor(
                  PlayerConsts.videoRenderersList,
                  playerState.videoOutputDriver,
                  languageCode,
                ),
                icon: Remix.tv_line,
                onTap: () => const RendererSettingsRoute().push(context),
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
                onTap: () => const AudioOutputSettingsRoute().push(context),
              ),
            ],
          ),
        ],
        SizedBox(height: 24.sp),
      ],
    );
  }

  /// Stores the chosen kernel and switches the player onto it now.
  ///
  /// The switch hard-disposes the player that is running ([PlayerManager.switchEngine]),
  /// which is what actually releases the native kernel — including when the same
  /// kernel is picked again, which therefore doubles as a player reset.
  ///
  /// `resumeCurrentSource: false` because the manager still remembers the last
  /// room after the player page was left; re-opening it here would start playing
  /// that room behind the settings screen. The next room opens on the new
  /// kernel.
  void _selectEngine(WidgetRef ref, String key) {
    final controller = ref.read(playerSettingsControllerProvider.notifier);
    controller.updateSettings(ref.read(playerSettingsControllerProvider).copyWith(videoPlayerKey: key));

    final engine = PlayerConsts.engines[key];
    final service = GlobalPlayerService.instance;
    if (engine == null || !service.initialized) return;

    unawaited(
      service.playerManager
          .switchEngine(engine, isManual: true, resumeCurrentSource: false)
          .catchError((Object error, StackTrace stackTrace) {
            debugPrint('Switch player kernel to $key failed: $error');
          }),
    );
  }
}
