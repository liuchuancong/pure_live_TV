import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/widgets/tv_settings_switch_tile.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/page_settings/page_settings_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

class PageSettingsSectionPage extends ConsumerWidget {
  const PageSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(pageSettingsControllerProvider);
    final page = ref.read(pageSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsSwitchTile(
          title: i18n('ui_show_page_size_selector'),
          subtitle: i18n('ui_show_a_page_size_selector_below_the_list'),
          icon: Icons.format_list_numbered_rounded,
          value: pageState.showPageSizeSelector,
          onChanged: (v) => page.updateSettings(pageState.copyWith(showPageSizeSelector: v)),
        ),
        TvSettingsSwitchTile(
          title: i18n('ui_show_jump_to_page_button'),
          subtitle: i18n('ui_show_a_jump_to_page_button_below_the_list'),
          icon: Icons.last_page_rounded,
          value: pageState.showGotoButton,
          onChanged: (v) => page.updateSettings(pageState.copyWith(showGotoButton: v)),
        ),
        TvSettingsSwitchTile(
          title: i18n('ui_show_back_to_top_button'),
          subtitle: i18n('ui_show_a_back_to_top_button_below_the_list'),
          icon: Icons.vertical_align_top_rounded,
          value: pageState.showScrollToTopBtn,
          onChanged: (v) => page.updateSettings(pageState.copyWith(showScrollToTopBtn: v)),
        ),
        TvSettingsOptionTile(
          title: i18n('ui_default_items_per_page'),
          subtitle: i18n('ui_default_page_size'),
          icon: Icons.numbers_rounded,
          options: pageState.pageSizeOptions.map((e) => '$e 条').toList(),
          index: pageState.pageSizeOptions
              .indexOf(pageState.defaultPageSize)
              .clamp(0, pageState.pageSizeOptions.length - 1),
          onChanged: (i) => page.updateSettings(pageState.copyWith(defaultPageSize: pageState.pageSizeOptions[i])),
        ),
      ],
    );
  }
}
