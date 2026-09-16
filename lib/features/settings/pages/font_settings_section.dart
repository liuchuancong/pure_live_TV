import 'package:pure_live/exports/exports.dart';

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
        TvSettingsGroupTitle(title: i18n('body_typography_group')),
        TvSettingsCard(
          children: [
            TvSettingsSliderTile(
              title: i18n('ui_global_text_scale'),
              icon: Icons.format_size_rounded,
              value: fontState.textScaleFactor,
              min: 0.8,
              max: 1.6,
              step: 0.05,
              displayValue: '${(fontState.textScaleFactor * 100).toStringAsFixed(0)}%',
              onChanged: (v) => font.updateSettings(fontState.copyWith(textScaleFactor: v)),
            ),
            TvSettingsSliderTile(
              title: i18n('ui_body_text_size'),
              icon: Icons.notes_rounded,
              value: fontState.fontSizeBodyMedium,
              min: 10,
              max: 20,
              displayValue: fontState.fontSizeBodyMedium.toStringAsFixed(0),
              onChanged: (v) => font.updateSettings(fontState.copyWith(fontSizeBodyMedium: v)),
            ),
          ],
        ),
        SizedBox(height: 20.sp),
        TvSettingsGroupTitle(title: i18n('header_typography_group')),
        TvSettingsCard(
          children: [
            TvSettingsSliderTile(
              title: i18n('ui_title_text_size'),
              icon: Icons.title_rounded,
              value: fontState.fontSizeTitleMedium,
              min: 12,
              max: 24,
              displayValue: fontState.fontSizeTitleMedium.toStringAsFixed(0),
              onChanged: (v) => font.updateSettings(fontState.copyWith(fontSizeTitleMedium: v)),
            ),
          ],
        ),
      ],
    );
  }
}
