import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';

/// Platform display: which platforms appear in the app.
///
/// Mirrors the desktop app's `/hot_areas` page, where the visible platforms are
/// chosen. The desktop page also reorders them by drag; on a remote the
/// sidebar order is configured in 导航栏显示控制 instead, so this page only
/// turns platforms on and off.
class PlatformDisplaySectionPage extends ConsumerWidget {
  const PlatformDisplaySectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favState = ref.watch(favoriteRoomControllerProvider);
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    final enabled = favState.hotAreasList;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final site in Sites.supportSites)
          TvSettingsSwitchTile(
            title: site.name,
            iconWidget: Image.asset(
              site.logo,
              width: 30.sp,
              height: 30.sp,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Icon(
                Icons.live_tv_rounded,
                size: 30.sp,
                color: context.tvTheme.secondaryTextColor,
              ),
            ),
            value: enabled.contains(site.id),
            onChanged: (value) => fav.toggleSiteEnabled(site.id, value),
          ),
      ],
    );
  }
}
