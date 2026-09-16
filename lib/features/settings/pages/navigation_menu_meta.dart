import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/services/app_settings/app_settings_model.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// Labels, subtitles and default icons of the side-menu entries.
///
/// Shared by the three 导航与显示设置 sub-pages (显示 / 排序 / 图标) so they can
/// never disagree about what an entry is called or which icon it uses by
/// default.
///
/// The three entries the mobile navigation page also has keep its labels
/// (关注 / 热门 / 分区); the other four are TV-only destinations.
String navigationMenuTitle(HomeMenu menu) => switch (menu) {
  HomeMenu.favorite => i18n('favorites_title'),
  HomeMenu.hot => i18n('popular_title'),
  HomeMenu.areas => i18n('areas_title'),
  HomeMenu.favoriteAreas => i18n('favorite_areas'),
  HomeMenu.moviePlayback => i18n('ui_link_playback'),
  HomeMenu.search => i18n('search_live'),
  HomeMenu.history => i18n('watch_history'),
};

/// Second line of an entry, or null when the mobile page labels it with the bare
/// name.
String? navigationMenuSubtitle(HomeMenu menu) => switch (menu) {
  HomeMenu.favorite || HomeMenu.hot || HomeMenu.areas => null,
  HomeMenu.favoriteAreas => i18n('favorite_areas'),
  HomeMenu.moviePlayback => i18n('movie_playback'),
  HomeMenu.search => i18n('search'),
  HomeMenu.history => i18n('history'),
};

/// Kept in step with the icons the side menu itself uses.
IconData navigationMenuIcon(HomeMenu menu) => switch (menu) {
  HomeMenu.favorite => Icons.favorite_border,
  HomeMenu.hot => Icons.local_fire_department_outlined,
  HomeMenu.areas => Icons.category_rounded,
  HomeMenu.favoriteAreas => Icons.collections_bookmark_outlined,
  HomeMenu.moviePlayback => Icons.movie_creation_outlined,
  HomeMenu.search => Icons.search_rounded,
  HomeMenu.history => Icons.history,
};

/// The visible entries, in their stored order.
///
/// An empty stored list means "every entry, in the default order" — the same rule
/// [AppSettingsController.normalizeMenuIds] applies — so one helper keeps the
/// three sub-pages and the menu itself in agreement.
List<HomeMenu> visibleMenuEntries(AppSettingsModel appState) {
  final List<String> ids = appState.savedMenuIds.isEmpty
      ? HomeMenu.defaultOrder
      : AppSettingsController.normalizeMenuIds(appState.savedMenuIds);
  return <HomeMenu>[
    for (final String id in ids)
      if (HomeMenu.fromId(id) case final HomeMenu menu) menu,
  ];
}
