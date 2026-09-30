import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/services/menu_icons/menu_icon_controller.dart';
import 'package:pure_live/features/settings/pages/navigation_menu_meta.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';

/// navigation & display - visibility: which entries the side menu shows.
///
/// One switch per entry. Hiding the last visible entry is refused: an empty
/// stored list means "show everything" to
/// [AppSettingsController.normalizeMenuIds], so the last switch flipped off would
/// silently turn every entry back on.
class NavVisibilitySectionPage extends ConsumerWidget {
  const NavVisibilitySectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appSettingsControllerProvider);
    final app = ref.read(appSettingsControllerProvider.notifier);
    final overrides = ref.watch(menuIconOverridesProvider);
    final visible = visibleMenuEntries(appState).map((menu) => menu.id).toSet();

    final railExpanded = ref.watch(isMenuExpandedProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // The rail's display mode: collapsed icons or expanded labels. This is
        // where the old sidebar expand button's job lives now.
        TvSettingsGroupTitle(title: i18n('navigation_display_mode')),
        TvSettingsCard(
          children: [
            TvSettingsSwitchTile(
              title: i18n('nav_rail_expanded'),
              subtitle: i18n('nav_rail_expanded_desc'),
              icon: Icons.view_sidebar_outlined,
              value: railExpanded,
              onChanged: (v) => ref.read(isMenuExpandedProvider.notifier).setExpanded(v),
            ),
          ],
        ),
        SizedBox(height: 20.ts(context)),
        TvSettingsGroupTitle(title: i18n('navigation_visibility')),
        TvSettingsCard(
          children: [
            for (final menu in HomeMenu.values)
              TvSettingsSwitchTile(
                title: navigationMenuTitle(menu),
                subtitle: navigationMenuSubtitle(menu),
                icon: overrides[menu.id] ?? navigationMenuIcon(menu),
                value: visible.contains(menu.id),
                onChanged: (enabled) {
                  if (!enabled && visible.length <= 1) {
                    ToastUtil.show(i18n('navigation_need_one_visible'));
                    return;
                  }
                  app.toggleMenuVisibility(menu.id, enabled);
                },
              ),
          ],
        ),
      ],
    );
  }
}
