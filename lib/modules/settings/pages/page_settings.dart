import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/tv_dialog/tv_dialog.dart';
import 'package:pure_live/tv_dialog/tv_input_dialog.dart';
import 'package:pure_live/services/settings/page_settings_controller.dart';

class PageSettingsPage extends GetView<SettingsService> {
  const PageSettingsPage({super.key});

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
              i18n("page_settings"),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: DpadRegion(
              memoryKey: 'settings/page',
              horizontalEdge: DpadEdgeBehavior.stop,
              verticalEdge: DpadEdgeBehavior.stop,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  context.buildGroupTitle(i18n("paging_controller")),
                  context.buildModernCard([
                    context.buildSwitchTile(
                      title: i18n('show_page_size_selector'),
                      subtitle: i18n('show_page_size_selector_subtitle'),
                      value: SettingsService.to.page.showPageSizeSelector,
                      icon: Remix.list_settings_line,
                    ),
                    context.buildSwitchTile(
                      title: i18n('show_goto_button'),
                      subtitle: i18n('show_goto_button_subtitle'),
                      value: SettingsService.to.page.showGotoButton,
                      icon: Remix.skip_forward_mini_line,
                    ),
                    context.buildSwitchTile(
                      title: i18n('show_scroll_to_top'),
                      subtitle: i18n('show_scroll_to_top_subtitle'),
                      value: SettingsService.to.page.showScrollToTopBtn,
                      icon: Remix.arrow_up_circle_line,
                    ),
                    Obx(
                      () => context.buildTile(
                        icon: Remix.list_check_2,
                        title: i18n("page_size_options_manage"),
                        subtitle: SettingsService.to.page.pageSizeOptions.join(', '),
                        onTap: () async => _showManageOptionsDialog(context),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showManageOptionsDialog(BuildContext context) {
    final List<int> draftOptions = List<int>.from(SettingsService.to.page.pageSizeOptions);

    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return TvDialog(
          title: i18n("page_size_options_manage"),
          child: SizedBox(
            width: 560,
            height: 480,
            child: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  children: [
                    Expanded(
                      child: DpadRegion(
                        horizontalEdge: DpadEdgeBehavior.stop,
                        verticalEdge: DpadEdgeBehavior.stop,
                        child: ListView(
                          children: [
                            DpadFocusable(
                              effects: [
                                DpadScaleEffect(scale: 1.02),
                                DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                              ],
                              onSelect: () {
                                setDialogState(() {
                                  draftOptions.clear();
                                  draftOptions.assignAll(PageSettingsController.getInitPageSizeOptions());
                                });
                              },
                              builder: (c, s, ch) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: s.focused
                                      ? theme.colorScheme.primary.withOpacity(0.12)
                                      : theme.colorScheme.primary.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.screen_rotation_rounded, size: 16, color: theme.colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Text(
                                      i18n("adaptive_recommend"),
                                      style: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
                              child: const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 16),
                            DpadFocusable(
                              effects: [
                                DpadScaleEffect(scale: 1.02),
                                DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                              ],
                              onSelect: () async {
                                final customString = await Get.dialog<String>(
                                  TvInputDialog(title: i18n("custom_input"), hintText: "20", maxLength: 3),
                                );
                                if (customString != null && customString.isNotEmpty) {
                                  final int? val = int.tryParse(customString);
                                  if (val != null && val > 0 && !draftOptions.contains(val)) {
                                    setDialogState(() {
                                      draftOptions.add(val);
                                      draftOptions.sort();
                                    });
                                  }
                                }
                              },
                              builder: (c, s, ch) => Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: s.focused
                                      ? theme.colorScheme.primary.withOpacity(0.12)
                                      : theme.colorScheme.surfaceContainerHigh,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 16,
                                      color: s.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      i18n("add"),
                                      style: TextStyle(
                                        color: s.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              child: const SizedBox.shrink(),
                            ),
                            const SizedBox(height: 16),
                            context.buildGroupTitle(i18n("current_options")),
                            context.buildModernCard(
                              draftOptions.map((size) {
                                return DpadFocusable(
                                  effects: [
                                    DpadScaleEffect(scale: 1.02),
                                    DpadGlowEffect(color: theme.colorScheme.error.withOpacity(0.3)),
                                  ],
                                  enabled: draftOptions.length > 1,
                                  onSelect: () {
                                    setDialogState(() {
                                      draftOptions.remove(size);
                                    });
                                  },
                                  builder: (c, s, ch) => Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    color: s.focused ? theme.colorScheme.error.withOpacity(0.12) : Colors.transparent,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          "$size ${i18n('items_per_page')}",
                                          style: TextStyle(
                                            color: s.focused ? theme.colorScheme.error : theme.colorScheme.onSurface,
                                          ),
                                        ),
                                        Icon(
                                          Icons.delete_outline_rounded,
                                          size: 18,
                                          color: s.focused
                                              ? theme.colorScheme.error
                                              : theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                  child: const SizedBox.shrink(),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    DpadRegion(
                      horizontalEdge: DpadEdgeBehavior.stop,
                      verticalEdge: DpadEdgeBehavior.stop,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          DpadFocusable(
                            effects: const [DpadScaleEffect(scale: 1.05)],
                            onSelect: () => Navigator.pop(context),
                            builder: (c, s, ch) => TextButton(
                              onPressed: null,
                              child: Text(
                                i18n("cancel"),
                                style: TextStyle(
                                  color: s.focused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                            child: const SizedBox.shrink(),
                          ),
                          const SizedBox(width: 16),
                          DpadFocusable(
                            effects: const [DpadScaleEffect(scale: 1.05)],
                            onSelect: () {
                              SettingsService.to.page.saveAllPageSizeOptions(draftOptions);
                              Navigator.pop(context);
                            },
                            builder: (c, s, ch) => ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: s.focused
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.primaryContainer,
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
                );
              },
            ),
          ),
        );
      },
    );
  }
}
