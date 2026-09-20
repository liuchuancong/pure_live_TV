import 'package:flutter/material.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
/// Grid spacing settings, hosted on its own page.
///
/// The two sliders lived as rows of the theme page; they moved here so the
/// theme page stays a menu of entries and each spacing axis gets its own row.
class GridSpacingSectionPage extends ConsumerWidget {
  const GridSpacingSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeSettingsControllerProvider);
    final theme = ref.read(themeSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('grid_spacing_settings')),
        TvSettingsCard(
          children: [
            // Landscape room-card grids show this many cards per row; it
            // replaces the old favourites-only dense-layout switch.
            TvSettingsOptionTile(
              title: i18n('room_card_columns'),
              subtitle: i18n('room_card_columns_subtitle'),
              icon: Remix.layout_grid_line,
              options: ThemeSettingsController.roomCardColumnsOptions.map((n) => '$n').toList(),
              index: ThemeSettingsController.roomCardColumnsOptions.indexOf(themeState.roomCardColumns),
              onChanged: (i) => theme.updateSettings(
                themeState.copyWith(roomCardColumns: ThemeSettingsController.roomCardColumnsOptions[i]),
              ),
            ),
            TvSettingsSliderTile(
              title: i18n('cross_axis_spacing'),
              subtitle: i18n('cross_axis_spacing_subtitle'),
              icon: Remix.arrow_left_right_line,
              value: themeState.crossAxisSpacing,
              min: 0,
              max: 24,
              displayValue: themeState.crossAxisSpacing.toStringAsFixed(0),
              onChanged: (v) => theme.updateSettings(themeState.copyWith(crossAxisSpacing: v)),
            ),
            TvSettingsSliderTile(
              title: i18n('main_axis_spacing'),
              subtitle: i18n('main_axis_spacing_subtitle'),
              icon: Remix.arrow_up_down_line,
              value: themeState.mainAxisSpacing,
              min: 0,
              max: 24,
              displayValue: themeState.mainAxisSpacing.toStringAsFixed(0),
              onChanged: (v) => theme.updateSettings(themeState.copyWith(mainAxisSpacing: v)),
            ),
          ],
        ),
      ],
    );
  }
}
