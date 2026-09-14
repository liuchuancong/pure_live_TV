import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/widgets/tv_settings_slider_tile.dart';
import 'package:pure_live/services/font_settings/font_settings_controller.dart';

class FontSettingsSectionPage extends ConsumerWidget {
  const FontSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fontState = ref.watch(fontSettingsControllerProvider).value;
    if (fontState == null) return const SizedBox.shrink();
    final font = ref.read(fontSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsSliderTile(
          title: '全局文字缩放',
          icon: Icons.format_size_rounded,
          value: fontState.textScaleFactor,
          min: 0.8,
          max: 1.6,
          step: 0.05,
          displayValue: '${(fontState.textScaleFactor * 100).toStringAsFixed(0)}%',
          onChanged: (v) => font.updateSettings(fontState.copyWith(textScaleFactor: v)),
        ),
        TvSettingsSliderTile(
          title: '正文文字大小',
          icon: Icons.notes_rounded,
          value: fontState.fontSizeBodyMedium,
          min: 10,
          max: 20,
          displayValue: fontState.fontSizeBodyMedium.toStringAsFixed(0),
          onChanged: (v) => font.updateSettings(fontState.copyWith(fontSizeBodyMedium: v)),
        ),
        TvSettingsSliderTile(
          title: '标题文字大小',
          icon: Icons.title_rounded,
          value: fontState.fontSizeTitleMedium,
          min: 12,
          max: 24,
          displayValue: fontState.fontSizeTitleMedium.toStringAsFixed(0),
          onChanged: (v) => font.updateSettings(fontState.copyWith(fontSizeTitleMedium: v)),
        ),
      ],
    );
  }
}
