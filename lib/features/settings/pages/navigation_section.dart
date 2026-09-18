import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/pages/navigation_menu_meta.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_router.dart';

/// navigation & display — the side menu's three separate concerns.
///
/// This page used to pile all of them into one long list (visibility switches,
/// reorder rows and icon rows). Each concern is its own page now, which is also
/// what the ordering needs: ordering asks *which entry* and then *which position*, and
/// that only reads clearly on a page of its own.
class NavigationSectionPage extends ConsumerWidget {
  const NavigationSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appSettingsControllerProvider);
    final int visibleCount = visibleMenuEntries(appState).length;
    final int total = HomeMenu.values.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('navigation_display_settings')),
        TvSettingsCard(
          children: [
            TvSettingsNavTile(
              title: i18n('navigation_visibility'),
              subtitle: i18n('navigation_visibility_desc'),
              icon: Icons.visibility_rounded,
              trailing: Text(
                i18n('navigation_visible_count', args: {'count': '$visibleCount', 'total': '$total'}),
                style: AppTextStyles.t16W500.copyWith(color: context.tvTheme.secondaryTextColor),
              ),
              onTap: () => const NavVisibilityRoute().push(context),
            ),
            TvSettingsNavTile(
              title: i18n('navigation_order'),
              subtitle: i18n('navigation_order_desc'),
              icon: Icons.swap_vert_rounded,
              onTap: () => const NavOrderRoute().push(context),
            ),
            TvSettingsNavTile(
              title: i18n('navigation_icons'),
              subtitle: i18n('navigation_icons_desc'),
              icon: Icons.palette_outlined,
              onTap: () => const NavIconsRoute().push(context),
            ),
          ],
        ),
      ],
    );
  }
}
