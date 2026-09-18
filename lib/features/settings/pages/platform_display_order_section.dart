import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';

/// platform display — platform order: the order the platform tabs appear in.
///
/// The stored `hotAreasList` order is what `Sites.availableSites()` reads, so this
/// order *is* the tab order on hot / categories. Same rule as ordering on the side menu:
/// **who you pick is who moves, and you say where it goes** — OK opens the list of
/// positions ("2 · douyu" is the platform sitting there now) and the picked platform
/// lands exactly on the chosen one. Left/Right nudges one step for a quick swap.
///
/// Only visible platforms are listed; the ones switched off in visibility are named
/// underneath, because an order for something nobody can see is not an order.
class PlatformDisplayOrderSectionPage extends ConsumerWidget {
  const PlatformDisplayOrderSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    final List<String> orderedIds = ref.watch(favoriteRoomControllerProvider).hotAreasList;
    // Stored ids are compared without case: a migrated profile can hold them in
    // the platform's own spelling, and a platform must not read as hidden just
    // because of that.
    final Set<String> orderedKeys = <String>{for (final id in orderedIds) id.trim().toLowerCase()};
    final Map<String, Site> byId = <String, Site>{for (final site in Sites.supportSites) site.id: site};
    final List<Site> ordered = <Site>[
      for (final id in orderedIds)
        if (byId[id.trim().toLowerCase()] case final Site site) site,
    ];
    final List<Site> hidden = <Site>[
      for (final site in Sites.supportSites)
        if (!orderedKeys.contains(site.id)) site,
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('platform_display_order')),
        TvSettingsCard(
          children: [
            for (int index = 0; index < ordered.length; index++)
              _SiteOrderTile(
                title: ordered[index].name,
                logo: ordered[index].logo,
                position: index + 1,
                total: ordered.length,
                onPickPosition: () => _pickPosition(context, fav, ordered, index),
                onNudge: (delta) => fav.moveSite(ordered[index].id, delta),
              ),
          ],
        ),
        if (hidden.isNotEmpty) ...[
          SizedBox(height: 12.sp),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 4.sp),
            child: Text(
              i18n('platform_display_hidden_hint', args: {'names': hidden.map((site) => site.name).join(' · ')}),
              style: AppTextStyles.t14W500.copyWith(color: context.tvTheme.secondaryTextColor),
            ),
          ),
        ],
      ],
    );
  }

  /// The positions the picked platform can be moved to.
  Future<void> _pickPosition(
    BuildContext context,
    FavoriteRoomController fav,
    List<Site> ordered,
    int currentIndex,
  ) async {
    final int? target = await TvDialogUtils.showSelect<int>(
      context: context,
      title: i18n('ui_move_to'),
      selectedValue: currentIndex,
      items: <TvSelectItem<int>>[
        for (int index = 0; index < ordered.length; index++)
          TvSelectItem<int>(title: '${index + 1} · ${ordered[index].name}', value: index),
      ],
    );
    if (target == null) return;
    fav.moveSiteTo(ordered[currentIndex].id, target);
  }
}

/// One ordering row: the platform, its position, and how to change it.
class _SiteOrderTile extends StatelessWidget {
  const _SiteOrderTile({
    required this.title,
    required this.logo,
    required this.position,
    required this.total,
    required this.onPickPosition,
    required this.onNudge,
  });

  final String title;
  final String logo;
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
      leading: TvPlatformLogo(logo: logo),
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
