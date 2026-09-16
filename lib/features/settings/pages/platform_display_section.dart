import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';

/// 平台显示 — the two separate concerns.
///
/// The page used to be one list of platform switches, and the desktop app also
/// reorders the same list by dragging. On a remote that reordering is its own
/// page now: 显示项目 decides which platforms are listed, 平台排序 decides the order
/// their tabs appear in on 热门 / 分区 (the stored `hotAreasList` order is what
/// `Sites.availableSites()` reads, so the order here *is* the tab order).
class PlatformDisplaySectionPage extends ConsumerWidget {
  const PlatformDisplaySectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favState = ref.watch(favoriteRoomControllerProvider);
    final int visibleCount = favState.hotAreasList.length;
    final int total = Sites.supportSites.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('platform_display')),
        TvSettingsCard(
          children: [
            TvSettingsNavTile(
              title: i18n('platform_display_visibility'),
              subtitle: i18n('platform_display_visibility_desc'),
              icon: Icons.visibility_rounded,
              trailing: Text(
                i18n('platform_visible_count', args: {'count': '$visibleCount', 'total': '$total'}),
                style: AppTextStyles.t16W500.copyWith(color: context.tvTheme.secondaryTextColor),
              ),
              onTap: () => context.push(AppRoutes.kSettingsHotAreasVisibility),
            ),
            TvSettingsNavTile(
              title: i18n('platform_display_order'),
              subtitle: i18n('platform_display_order_desc'),
              icon: Icons.swap_vert_rounded,
              onTap: () => context.push(AppRoutes.kSettingsHotAreasOrder),
            ),
          ],
        ),
      ],
    );
  }
}
