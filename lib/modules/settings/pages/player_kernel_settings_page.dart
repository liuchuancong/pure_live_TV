import 'dart:io';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/tv_dialog/tv_dialog.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:pure_live/tv_dialog/tv_menu_dialog.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/player/models/player_engine.dart';
import 'package:pure_live/common/style/app_text_styles.dart';

class PlayerKernelSettingsPage extends GetView<SettingsService> {
  const PlayerKernelSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return TvScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              i18n("player_kernel_settings"),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: DpadRegion(
              memoryKey: 'settings/player_kernel',
              horizontalEdge: DpadEdgeBehavior.stop,
              verticalEdge: DpadEdgeBehavior.stop,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  context.buildGroupTitle(i18n("core_kernel_settings")),
                  context.buildModernCard([
                    Obx(() {
                      String activeKey = SettingsService.to.player.videoPlayerKey.v;
                      String activeI18nKey =
                          PlayerConsts.names[activeKey] ?? PlayerConsts.names[PlayerConsts.defaultKey]!;

                      return context.buildMenuTile<String>(
                        icon: Remix.toggle_line,
                        title: i18n("kernel_switch"),
                        subtitle: i18n("kernel_switch_subtitle"),
                        value: activeKey,
                        valueMap: PlayerConsts.names,
                        onChanged: (newValue) {
                          SettingsService.to.player.videoPlayerKey.v = newValue;
                        },
                        onTap: () async => showVideoSetDialog(),
                      );
                    }),
                    Obx(() {
                      String activeKey = SettingsService.to.player.videoPlayerKey.v;
                      if (PlayerConsts.engines[activeKey] == PlayerEngine.exo) {
                        return const SizedBox.shrink();
                      }

                      return context.buildTile(
                        icon: Remix.global_line,
                        title: i18n("network_proxy"),
                        subtitle: i18n("network_proxy_subtitle"),
                        onTap: () async => showProxySettingsDialog(),
                        trailing: Text(
                          SettingsService.to.proxy.enableProxy.v ? i18n("enabled") : i18n("disabled"),
                          style: AppTextStyles.t13.copyWith(
                            color: SettingsService.to.proxy.enableProxy.v ? theme.colorScheme.primary : theme.hintColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }),
                    context.buildSwitchTile(
                      icon: Remix.music_2_line,
                      title: i18n('audio_only_mode'),
                      subtitle: i18n("audio_only_mode_subtitle"),
                      value: SettingsService.to.player.audioOnly,
                    ),
                    context.buildSwitchTile(
                      icon: Remix.speed_up_line,
                      title: i18n('enable_codec'),
                      subtitle: i18n("gpu_decode"),
                      value: SettingsService.to.player.enableCodec,
                    ),
                    context.buildSwitchTile(
                      icon: Remix.shut_down_line,
                      title: i18n('force_destroy_player'),
                      subtitle: i18n('force_destroy_player_subtitle'),
                      value: SettingsService.to.player.useHardStopOnExit,
                    ),
                  ]),
                  Obx(() {
                    String activeKey = SettingsService.to.player.videoPlayerKey.v;
                    if (PlayerConsts.engines[activeKey] != PlayerEngine.mediaKit) {
                      return const SizedBox.shrink();
                    }
                    return _buildMpvSettings(context);
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMpvSettings(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(padding: EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 12), child: Divider()),
        if (Platform.isAndroid) ...[
          context.buildSwitchTile(
            icon: Remix.shield_check_line,
            title: i18n('compat_mode'),
            subtitle: i18n('compat_mode_subtitle'),
            value: SettingsService.to.player.playerCompatMode,
          ),
          const SizedBox(height: 12),
        ],
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 5, 12, 12),
          child: Row(
            children: [
              Icon(Remix.equalizer_line, size: 18, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                i18n("mpv_advanced_settings"),
                style: AppTextStyles.t16Bold.copyWith(color: theme.colorScheme.primary),
              ),
            ],
          ),
        ),
        DpadRegion(
          horizontalEdge: DpadEdgeBehavior.stop,
          verticalEdge: DpadEdgeBehavior.stop,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    i18n("mpv_warning_text"),
                    style: AppTextStyles.t12.copyWith(color: theme.hintColor.withOpacity(0.65)),
                  ),
                ),
                const SizedBox(width: 16),
                DpadFocusable(
                  effects: [
                    DpadScaleEffect(scale: 1.05),
                    DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                  ],
                  onSelect: () => launchUrlString("https://mpv.io"),
                  builder: (c, s, ch) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: s.focused
                          ? theme.colorScheme.primary.withOpacity(0.12)
                          : theme.colorScheme.primaryContainer.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      i18n("mpv_official_docs"),
                      style: AppTextStyles.t12.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w600),
                    ),
                  ),
                  child: const SizedBox.shrink(),
                ),
                const SizedBox(width: 12),
                DpadFocusable(
                  effects: [
                    DpadScaleEffect(scale: 1.05),
                    DpadGlowEffect(color: Colors.red.withOpacity(0.3)),
                  ],
                  onSelect: () => SettingsService.to.player.resetMpvPlayerSettings(),
                  builder: (c, s, ch) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: s.focused ? Colors.red.withOpacity(0.12) : Colors.red.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Remix.refresh_line, size: 14, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          i18n("reset"),
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        context.buildModernCard([
          context.buildSwitchTile(
            icon: Remix.code_box_line,
            title: i18n("custom_output_hwdec"),
            value: SettingsService.to.player.customPlayerOutput,
          ),
          Obx(
            () => context.buildMenuTile<String>(
              title: i18n("video_output_driver"),
              icon: Remix.movie_line,
              value: SettingsService.to.player.videoOutputDriver.v,
              valueMap: PlayerConsts.videoOutputDrivers,
              onChanged: (e) => SettingsService.to.player.videoOutputDriver.v = e,
            ),
          ),
          Obx(
            () => context.buildMenuTile<String>(
              title: i18n("audio_output_driver"),
              icon: Remix.volume_up_line,
              value: SettingsService.to.player.audioOutputDriver.v,
              valueMap: PlayerConsts.audioOutputDrivers,
              onChanged: (e) => SettingsService.to.player.audioOutputDriver.v = e,
            ),
          ),
          Obx(
            () => context.buildMenuTile(
              title: i18n("hardware_decoder"),
              icon: Remix.cpu_line,
              value: SettingsService.to.player.videoHardwareDecoder.v,
              valueMap: PlayerConsts.hardwareDecoder,
              onChanged: (e) => SettingsService.to.player.videoHardwareDecoder.v = e,
            ),
          ),
        ]),
      ],
    );
  }

  void showVideoSetDialog() async {
    final List<TvMenuItem> menuItems = PlayerConsts.names.entries.map((e) {
      return TvMenuItem(title: i18n(e.value), value: e.key);
    }).toList();
    final selected = await Get.dialog(
      TvMenuDialog(
        title: i18n('kernel_switch'),
        items: menuItems,
        selectedValue: SettingsService.to.player.videoPlayerKey.v,
      ),
    );
    if (selected != null) {
      SettingsService.to.player.videoPlayerKey.v = selected;
    }
  }

  void showProxySettingsDialog() {
    final hostController = TextEditingController(text: SettingsService.to.proxy.proxyHost.v);
    final portController = TextEditingController(text: SettingsService.to.proxy.proxyPort.v.toString());
    final theme = Theme.of(Get.context!);

    showDialog(
      context: Get.context!,
      builder: (context) => TvDialog(
        title: i18n("proxy_settings"),
        child: SizedBox(
          width: 500,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(
                () => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    context.buildSwitchTile(
                      icon: Remix.shield_keyhole_line,
                      title: i18n("enable_player_proxy"),
                      value: SettingsService.to.proxy.enableProxy,
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: hostController,
                      enabled: SettingsService.to.proxy.enableProxy.v,
                      decoration: InputDecoration(
                        labelText: i18n("proxy_host"),
                        prefixIcon: const Icon(Remix.global_line, size: 20),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      onChanged: (value) => SettingsService.to.proxy.proxyHost.v = value,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: portController,
                      enabled: SettingsService.to.proxy.enableProxy.v,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: i18n("proxy_port"),
                        prefixIcon: const Icon(Remix.links_line, size: 20),
                        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                      ),
                      onChanged: (value) {
                        int? port = int.tryParse(value);
                        if (port != null) SettingsService.to.proxy.proxyPort.v = port;
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              DpadRegion(
                horizontalEdge: DpadEdgeBehavior.stop,
                verticalEdge: DpadEdgeBehavior.stop,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    DpadFocusable(
                      effects: const [DpadScaleEffect(scale: 1.05)],
                      onSelect: () => Navigator.pop(context),
                      builder: (c, s, ch) => ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: s.focused ? theme.colorScheme.primary : theme.colorScheme.primaryContainer,
                          foregroundColor: s.focused
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onPrimaryContainer,
                        ),
                        onPressed: null,
                        child: Text(i18n("confirm")),
                      ),
                      child: const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
