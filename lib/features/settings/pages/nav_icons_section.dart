import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/pages/icon_picker_section.dart';
import 'package:pure_live/features/settings/pages/navigation_menu_meta.dart';
import 'package:pure_live/services/menu_icons/menu_icon_controller.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/consts/icon_catalog.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 导航与显示设置 — 图标: which icon each side-menu entry shows.
///
/// One row per entry (hidden ones included: the icon is remembered for whenever
/// the entry comes back), with the icon picker opened on OK. A null result from
/// the picker means it was dismissed; a result carrying a null icon is the
/// picker's "restore default" action.
class NavIconsSectionPage extends ConsumerWidget {
  const NavIconsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overrides = ref.watch(menuIconOverridesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('navigation_icons')),
        TvSettingsCard(
          children: [
            for (final menu in HomeMenu.values)
              TvSettingsNavTile(
                title: navigationMenuTitle(menu),
                subtitle: i18n('ui_choose_icon'),
                icon: overrides[menu.id] ?? navigationMenuIcon(menu),
                onTap: () => _pickIcon(context, ref, menu),
              ),
          ],
        ),
      ],
    );
  }

  static Future<void> _pickIcon(BuildContext context, WidgetRef ref, HomeMenu menu) async {
    final controller = ref.read(menuIconOverridesProvider.notifier);

    final IconPickResult? result = await context.push<IconPickResult>(
      AppRoutes.kSettingsIconPicker,
      extra: controller.labelFor(menu.id),
    );
    if (result == null) return;

    final IconOption? option = result.option;
    if (option == null) {
      await controller.resetIcon(menu.id);
      return;
    }
    await controller.setIcon(menu.id, option);
  }
}
