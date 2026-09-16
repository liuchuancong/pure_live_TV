import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/pages/icon_picker_section.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/services/menu_icons/menu_icon_controller.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/consts/icon_catalog.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Home side-menu configuration: show or hide entries, reorder them and pick
/// the icon each entry shows.
class NavigationSectionPage extends ConsumerWidget {
  const NavigationSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appSettingsControllerProvider);
    final app = ref.read(appSettingsControllerProvider.notifier);
    final overrides = ref.watch(menuIconOverridesProvider);
    final visible = appState.savedMenuIds.isEmpty
        ? HomeMenu.defaultOrder
        : AppSettingsController.normalizeMenuIds(appState.savedMenuIds);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsCard(
            children: [
              for (final menu in HomeMenu.values)
                TvSettingsSwitchTile(
                  title: _title(menu),
                  subtitle: _subtitle(menu),
                  icon: overrides[menu.id] ?? _icon(menu),
                  value: visible.contains(menu.id),
                  onChanged: (enabled) => app.toggleMenuVisibility(menu.id, enabled),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          TvSettingsCard(
            children: [
              for (final menu in HomeMenu.values)
                _MoveMenuTile(
                  title: '${_title(menu)} · ${i18n('ui_move')}',
                  // Position among the *visible* entries decides whether a move
                  // is possible; an entry hidden by the switches above cannot
                  // be reordered.
                  visibleIndex: visible.indexOf(menu.id),
                  visibleCount: visible.length,
                  onMove: (delta) => app.moveMenu(menu.id, delta),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          TvSettingsCard(
            children: [
              for (final menu in HomeMenu.values)
                TvSettingsNavTile(
                  title: _title(menu),
                  subtitle: i18n('ui_choose_icon'),
                  icon: overrides[menu.id] ?? _icon(menu),
                  onTap: () => _pickIcon(context, ref, menu),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// Opens the icon picker for [menu] and stores what comes back.
  ///
  /// A null result means the picker was dismissed; a result carrying a null
  /// icon is the picker's "restore default" action.
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

  /// The three entries the mobile navigation page also has keep its labels
  /// (关注 / 热门 / 分区); the other four are TV-only destinations.
  static String _title(HomeMenu menu) => switch (menu) {
    HomeMenu.favorite => i18n('favorites_title'),
    HomeMenu.hot => i18n('popular_title'),
    HomeMenu.areas => i18n('areas_title'),
    HomeMenu.favoriteAreas => i18n('favorite_areas'),
    HomeMenu.moviePlayback => i18n('ui_link_playback'),
    HomeMenu.search => i18n('search_live'),
    HomeMenu.history => i18n('watch_history'),
  };

  static String? _subtitle(HomeMenu menu) => switch (menu) {
    // No subtitle: the mobile page labels these three with the bare name.
    HomeMenu.favorite || HomeMenu.hot || HomeMenu.areas => null,
    HomeMenu.favoriteAreas => i18n('favorite_areas'),
    HomeMenu.moviePlayback => i18n('movie_playback'),
    HomeMenu.search => i18n('search'),
    HomeMenu.history => i18n('history'),
  };

  /// Kept in step with the icons the side menu itself uses.
  static IconData _icon(HomeMenu menu) => switch (menu) {
    HomeMenu.favorite => Icons.favorite_border,
    HomeMenu.hot => Icons.local_fire_department_outlined,
    HomeMenu.areas => Icons.category_rounded,
    HomeMenu.favoriteAreas => Icons.collections_bookmark_outlined,
    HomeMenu.moviePlayback => Icons.movie_creation_outlined,
    HomeMenu.search => Icons.search_rounded,
    HomeMenu.history => Icons.history,
  };
}

/// One reorder row: left moves the entry up, right moves it down.
///
/// This replaces a cycling [TvSettingsOptionTile] whose index was pinned to 0,
/// which made the label always read "move up" while every action actually
/// computed index 1 — so "move up" could not be performed at all.
class _MoveMenuTile extends StatelessWidget {
  const _MoveMenuTile({
    required this.title,
    required this.visibleIndex,
    required this.visibleCount,
    required this.onMove,
  });

  final String title;
  final int visibleIndex;
  final int visibleCount;
  final void Function(int delta) onMove;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final bool isVisible = visibleIndex >= 0;
    final bool canMoveUp = isVisible && visibleIndex > 0;
    final bool canMoveDown = isVisible && visibleIndex < visibleCount - 1;

    return TvSettingsRow(
      title: title,
      subtitle: isVisible ? null : i18n('ui_move_hidden_entry'),
      icon: Icons.swap_vert_rounded,
      // Only consume the key while the entry can actually move that way, so an
      // entry at the top or bottom never traps the remote on this row.
      onDirection: (direction) {
        if (direction == TraversalDirection.left && canMoveUp) {
          onMove(-1);
          return true;
        }
        if (direction == TraversalDirection.right && canMoveDown) {
          onMove(1);
          return true;
        }
        return false;
      },
      onSelect: () {
        if (canMoveDown) onMove(1);
      },
      trailingBuilder: (context, focused) {
        final Color accent = focused ? tvTheme.focusColor : tvTheme.secondaryTextColor;
        final Color muted = tvTheme.secondaryTextColor.withValues(alpha: 0.35);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.keyboard_arrow_up_rounded, size: 26.sp, color: canMoveUp ? accent : muted),
            SizedBox(width: 4.sp),
            Text(
              isVisible ? '${visibleIndex + 1}/$visibleCount' : '-',
              style: AppTextStyles.t20W600.copyWith(
                color: focused ? tvTheme.focusColor : tvTheme.primaryTextColor,
              ),
            ),
            SizedBox(width: 4.sp),
            Icon(Icons.keyboard_arrow_down_rounded, size: 26.sp, color: canMoveDown ? accent : muted),
          ],
        );
      },
    );
  }
}
