import 'package:flutter/material.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

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
        TvSettingsOptionTile(
          title: i18n('ui_preferred_platform'),
          subtitle: i18n('ui_platform_selected_on_startup'),
          icon: Icons.devices_rounded,
          options: siteNames,
          index: currentIndex,
          onChanged: (i) => fav.changePreferPlatform(siteIds[i]),
        ),
      ],
    );
  }
}
