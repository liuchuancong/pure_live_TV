import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/pages/navigation_menu_meta.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/services/menu_icons/menu_icon_controller.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// navigation & display — ordering: the order of the entries in the side menu.
///
/// **Who you pick is who moves, and you say where it goes**: OK on an entry opens
/// the list of positions ("3 · categories" is the entry sitting there now) and the entry
/// the user picked lands exactly on the chosen one. Left/Right still nudge an
/// entry one step for a quick swap.
///
/// Only the visible entries are listed — ordering a hidden entry would be an
/// order nobody can see — and the hidden ones are named underneath so it is clear
/// where they went.
class NavOrderSectionPage extends ConsumerWidget {
  const NavOrderSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appSettingsControllerProvider);
    final app = ref.read(appSettingsControllerProvider.notifier);
    final overrides = ref.watch(menuIconOverridesProvider);
    final ordered = visibleMenuEntries(appState);
    final hidden = <HomeMenu>[
      for (final menu in HomeMenu.values)
        if (!ordered.contains(menu)) menu,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('navigation_order')),
        TvSettingsCard(
          children: [
            for (int index = 0; index < ordered.length; index++)
              _MenuOrderTile(
                title: navigationMenuTitle(ordered[index]),
                icon: overrides[ordered[index].id] ?? navigationMenuIcon(ordered[index]),
                position: index + 1,
                total: ordered.length,
                onPickPosition: () => _pickPosition(context, ref, ordered, index),
                onNudge: (delta) => app.moveMenu(ordered[index].id, delta),
              ),
          ],
        ),
        if (hidden.isNotEmpty) ...[
          SizedBox(height: 12.sp),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.sp),
            child: Text(
              '${i18n('ui_move_hidden_entry')}: '
              '${hidden.map(navigationMenuTitle).join(' · ')}',
              style: AppTextStyles.t14W500.copyWith(color: context.tvTheme.secondaryTextColor),
            ),
          ),
        ],
      ],
    );
  }

  /// The positions the picked entry can be moved to.
  ///
  /// Each row names the entry that currently holds that position, so "3 · categories"
  /// reads as "put it where categories is now".
  Future<void> _pickPosition(
    BuildContext context,
    WidgetRef ref,
    List<HomeMenu> ordered,
    int currentIndex,
  ) async {
    final int? target = await TvDialogUtils.showSelect<int>(
      context: context,
      title: i18n('ui_move_to'),
      selectedValue: currentIndex,
      items: <TvSelectItem<int>>[
        for (int index = 0; index < ordered.length; index++)
          TvSelectItem<int>(title: '${index + 1} · ${navigationMenuTitle(ordered[index])}', value: index),
      ],
    );
    if (target == null) return;
    ref.read(appSettingsControllerProvider.notifier).moveMenuTo(ordered[currentIndex].id, target);
  }
}

/// One ordering row: the entry, its position, and how to change it.
///
/// Left/Right nudge it one step; OK opens the position list. The key is only
/// consumed while the entry can actually move that way, so an entry at the top or
/// bottom never traps the remote.
class _MenuOrderTile extends StatelessWidget {
  const _MenuOrderTile({
    required this.title,
    required this.icon,
    required this.position,
    required this.total,
    required this.onPickPosition,
    required this.onNudge,
  });

  final String title;
  final IconData icon;
  final int position;
  final int total;
  final VoidCallback onPickPosition;
  final ValueChanged<int> onNudge;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final bool canMoveUp = position > 1;
    final bool canMoveDown = position < total;

    return TvSettingsRow(
      title: title,
      subtitle: i18n('ui_move_to'),
      icon: icon,
      onDirection: (direction) {
        if (direction == TraversalDirection.left && canMoveUp) {
          onNudge(-1);
          return true;
        }
        if (direction == TraversalDirection.right && canMoveDown) {
          onNudge(1);
          return true;
        }
        return false;
      },
      onSelect: onPickPosition,
      trailingBuilder: (context, focused) {
        final Color accent = focused ? tvTheme.focusColor : tvTheme.secondaryTextColor;
        final Color muted = tvTheme.secondaryTextColor.withValues(alpha: 0.35);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.keyboard_arrow_up_rounded, size: 26.sp, color: canMoveUp ? accent : muted),
            SizedBox(width: 4.sp),
            Text(
              '$position/$total',
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
