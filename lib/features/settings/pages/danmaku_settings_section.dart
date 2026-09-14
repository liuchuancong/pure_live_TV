import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/widgets/tv_settings_switch_tile.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';

class DanmakuSettingsSectionPage extends ConsumerWidget {
  const DanmakuSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final danmakuState = ref.watch(danmakuSettingsControllerProvider);
    final danmaku = ref.read(danmakuSettingsControllerProvider.notifier);
    // TV 上弹幕只保留一个总开关，同时同步 hideDanmaku 保持旧数据兼容
    final enabled = danmakuState.enableDanmakuDisplay && !danmakuState.hideDanmaku;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsSwitchTile(
          title: '弹幕开关',
          subtitle: '开启后在直播间显示弹幕',
          icon: Icons.subtitles_rounded,
          value: enabled,
          onChanged: (v) => danmaku.updateSettings(danmakuState.copyWith(enableDanmakuDisplay: v, hideDanmaku: !v)),
        ),
      ],
    );
  }
}
