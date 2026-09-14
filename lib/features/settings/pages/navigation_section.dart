import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Home side-menu configuration: show or hide entries and change their order.
class NavigationSectionPage extends ConsumerWidget {
  const NavigationSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appSettingsControllerProvider);
    final app = ref.read(appSettingsControllerProvider.notifier);
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
                  icon: _icon(menu),
                  value: visible.contains(menu.id),
                  onChanged: (enabled) => app.toggleMenuVisibility(menu.id, enabled),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          TvSettingsCard(
            children: [
              for (final menu in HomeMenu.values)
                TvSettingsOptionTile(
                  title: '${_title(menu)} · ${i18n('ui_move')}',
                  icon: Icons.swap_vert_rounded,
                  options: [i18n('ui_move_up'), i18n('ui_move_down')],
                  index: 0,
                  onChanged: (index) => app.moveMenu(menu.id, index == 0 ? -1 : 1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _title(HomeMenu menu) => switch (menu) {
    HomeMenu.favorite => i18n('ui_following'),
    HomeMenu.hot => i18n('kilakila_hot'),
    HomeMenu.areas => i18n('ui_category'),
    HomeMenu.favoriteAreas => i18n('favorite_areas'),
    HomeMenu.moviePlayback => i18n('ui_link_playback'),
    HomeMenu.search => i18n('search_live'),
    HomeMenu.history => i18n('watch_history'),
  };

  static String _subtitle(HomeMenu menu) => switch (menu) {
    HomeMenu.favorite => i18n('favorites'),
    HomeMenu.hot => i18n('hot'),
    HomeMenu.areas => i18n('areas_title'),
    HomeMenu.favoriteAreas => i18n('favorite_areas'),
    HomeMenu.moviePlayback => i18n('movie_playback'),
    HomeMenu.search => i18n('search'),
    HomeMenu.history => i18n('history'),
  };

  static IconData _icon(HomeMenu menu) => switch (menu) {
    HomeMenu.favorite => Icons.favorite_border,
    HomeMenu.hot => Icons.local_fire_department_outlined,
    HomeMenu.areas => Icons.apps_rounded,
    HomeMenu.favoriteAreas => Icons.view_module_rounded,
    HomeMenu.moviePlayback => Icons.movie_creation_outlined,
    HomeMenu.search => Icons.search_rounded,
    HomeMenu.history => Icons.history,
  };
}
