import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';

class PlatformSettingsSectionPage extends ConsumerWidget {
  const PlatformSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final favState = ref.watch(favoriteRoomControllerProvider);
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    final siteIds = Sites.supportSites.map((s) => s.id).toList();
    final siteNames = Sites.supportSites.map((s) => s.name).toList();
    final currentIndex = siteIds.indexOf(favState.preferPlatform).clamp(0, siteIds.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Same rows and order as the desktop platform page: which platforms are
        // shown, the preferred platform, then the authorisation and tag pages.
        TvSettingsNavTile(
          title: i18n('platform_display'),
          subtitle: i18n('platform_display_subtitle'),
          icon: Remix.apps_2_line,
          onTap: () => context.push(AppRoutes.kSettingsHotAreas),
        ),
        TvSettingsOptionTile(
          title: i18n('prefer_platform'),
          subtitle: i18n('prefer_platform_subtitle'),
          icon: Remix.heart_3_line,
          options: siteNames,
          index: currentIndex,
          onChanged: (i) => fav.changePreferPlatform(siteIds[i]),
        ),
        TvSettingsNavTile(
          title: i18n('third_party_auth'),
          subtitle: i18n('third_party_auth_subtitle'),
          icon: Remix.accessibility_line,
          onTap: () => context.push(AppRoutes.kSettingsAccount),
        ),
        TvSettingsNavTile(
          title: i18n('tag_management'),
          subtitle: i18n('tag_management_subtitle'),
          icon: Remix.price_tag_3_line,
          onTap: () => context.push(AppRoutes.kSettingsTags),
        ),
      ],
    );
  }
}
