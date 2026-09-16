import 'package:pure_live/shared/widgets/index.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/page_settings/page_settings_controller.dart';

/// Paging settings.
///
/// Only 默认每页条数 survives on a TV. The three visibility switches the mobile
/// page has drive a pager bar (page-size selector, jump-to-page, back-to-top)
/// that does not exist here: the TV lists are continuous grids that load the next
/// page as the user scrolls, so those switches wrote values nothing could honour.
/// The remaining row is wired into the paging core, so it decides how many
/// entries each page request asks for.
class PageSettingsSectionPage extends ConsumerWidget {
  const PageSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState = ref.watch(pageSettingsControllerProvider);
    final page = ref.read(pageSettingsControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsOptionTile(
          title: i18n('ui_default_items_per_page'),
          subtitle: i18n('ui_default_page_size'),
          icon: Icons.numbers_rounded,
          options: pageState.pageSizeOptions.map((e) => '$e ${i18n('items_per_page')}').toList(),
          index: pageState.pageSizeOptions
              .indexOf(pageState.defaultPageSize)
              .clamp(0, pageState.pageSizeOptions.length - 1),
          onChanged: (i) => page.updateSettings(pageState.copyWith(defaultPageSize: pageState.pageSizeOptions[i])),
        ),
      ],
    );
  }
}
