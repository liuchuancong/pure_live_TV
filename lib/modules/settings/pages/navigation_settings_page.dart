import 'package:dpad/dpad.dart';
import 'package:remixicon/remixicon.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_scaffold.dart';
import 'package:pure_live/common/consts/app_consts.dart';
import 'package:pure_live/common/style/app_text_styles.dart';

class NavigationSettingsPage extends StatelessWidget {
  const NavigationSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final allMenus = [HomeMenu.favorites, HomeMenu.popular, HomeMenu.areas, HomeMenu.record];

    return TvScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Text(
              i18n("navigation_display_settings"),
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: DpadRegion(
              memoryKey: 'settings/navigation',
              horizontalEdge: DpadEdgeBehavior.stop,
              verticalEdge: DpadEdgeBehavior.stop,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                children: [
                  _buildTipBanner(theme),
                  const SizedBox(height: 20),
                  context.buildGroupTitle(i18n("navigation_display_settings")),
                  Obx(() {
                    final savedOrder = SettingsService.to.app.savedMenuIds.v;
                    final sortedMenus = List<HomeMenu>.from(allMenus);
                    sortedMenus.sort((a, b) {
                      final indexA = savedOrder.indexOf(a.id);
                      final indexB = savedOrder.indexOf(b.id);
                      if (indexA != -1 && indexB != -1) return indexA.compareTo(indexB);
                      if (indexA != -1) return -1;
                      if (indexB != -1) return 1;
                      return 0;
                    });

                    return context.buildModernCard(
                      List.generate(sortedMenus.length, (index) {
                        final menu = sortedMenus[index];
                        final isVisible = SettingsService.to.app.savedMenuIds.v.contains(menu.id);

                        String titleText = "";
                        IconData menuIcon = Remix.question_line;
                        switch (menu) {
                          case HomeMenu.favorites:
                            titleText = i18n("favorites_title");
                            menuIcon = Remix.heart_3_fill;
                            break;
                          case HomeMenu.popular:
                            titleText = i18n("popular_title");
                            menuIcon = CustomIcons.popular;
                            break;
                          case HomeMenu.areas:
                            titleText = i18n("areas_title");
                            menuIcon = Remix.apps_2_line;
                            break;
                          case HomeMenu.record:
                            titleText = i18n("record_center");
                            menuIcon = Remix.download_2_fill;
                            break;
                        }

                        return DpadFocusable(
                          effects: [
                            DpadScaleEffect(scale: 1.02),
                            DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
                          ],
                          excludeChildFocus: false,
                          builder: (context, state, child) {
                            return Container(
                              color: state.focused ? theme.colorScheme.primary.withOpacity(0.12) : Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                children: [
                                  Icon(
                                    menuIcon,
                                    size: 22,
                                    color: state.focused
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      titleText,
                                      style: AppTextStyles.t15.copyWith(
                                        fontWeight: FontWeight.w600,
                                        color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      DpadFocusable(
                                        effects: const [DpadScaleEffect(scale: 1.1)],
                                        enabled: index > 0,
                                        onSelect: () {
                                          final currentOrder = List<String>.from(SettingsService.to.app.savedMenuIds.v);
                                          final movedId = currentOrder.removeAt(index);
                                          currentOrder.insert(index - 1, movedId);
                                          SettingsService.to.app.savedMenuIds.v = currentOrder;
                                        },
                                        builder: (c, s, ch) => Icon(
                                          Remix.arrow_up_s_line,
                                          color: index == 0
                                              ? theme.disabledColor
                                              : (s.focused
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.onSurfaceVariant),
                                        ),
                                        child: const SizedBox.shrink(),
                                      ),
                                      const SizedBox(width: 12),
                                      DpadFocusable(
                                        effects: const [DpadScaleEffect(scale: 1.1)],
                                        enabled: index < sortedMenus.length - 1,
                                        onSelect: () {
                                          final currentOrder = List<String>.from(SettingsService.to.app.savedMenuIds.v);
                                          final movedId = currentOrder.removeAt(index);
                                          currentOrder.insert(index + 1, movedId);
                                          SettingsService.to.app.savedMenuIds.v = currentOrder;
                                        },
                                        builder: (c, s, ch) => Icon(
                                          Remix.arrow_down_s_line,
                                          color: index == sortedMenus.length - 1
                                              ? theme.disabledColor
                                              : (s.focused
                                                    ? theme.colorScheme.primary
                                                    : theme.colorScheme.onSurfaceVariant),
                                        ),
                                        child: const SizedBox.shrink(),
                                      ),
                                      const SizedBox(width: 16),
                                      Switch(
                                        value: isVisible,
                                        activeColor: theme.colorScheme.primary,
                                        onChanged: (value) => SettingsService.to.app.toggleMenuVisibility(menu, value),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                          child: const SizedBox.shrink(),
                        );
                      }),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Remix.information_line, size: 18, color: theme.colorScheme.primary.withOpacity(0.8)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              i18n('click_arrow_to_sort_tip'),
              style: AppTextStyles.t13.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withOpacity(0.8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
