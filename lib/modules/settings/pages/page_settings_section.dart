import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/widgets/tv_settings_switch_tile.dart';
import 'package:pure_live/modules/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/page_settings/page_settings_controller.dart';

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
          title: '显示每页条数选择',
          subtitle: '列表底部显示切换每页数量的按钮',
          icon: Icons.format_list_numbered_rounded,
          value: pageState.showPageSizeSelector,
          onChanged: (v) => page.updateSettings(pageState.copyWith(showPageSizeSelector: v)),
        ),
        TvSettingsSwitchTile(
          title: '显示跳页按钮',
          subtitle: '列表底部显示跳转到指定页的按钮',
          icon: Icons.last_page_rounded,
          value: pageState.showGotoButton,
          onChanged: (v) => page.updateSettings(pageState.copyWith(showGotoButton: v)),
        ),
        TvSettingsSwitchTile(
          title: '显示回顶按钮',
          subtitle: '列表底部显示回到顶部的按钮',
          icon: Icons.vertical_align_top_rounded,
          value: pageState.showScrollToTopBtn,
          onChanged: (v) => page.updateSettings(pageState.copyWith(showScrollToTopBtn: v)),
        ),
        TvSettingsOptionTile(
          title: '默认每页条数',
          subtitle: '列表默认分页大小',
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
