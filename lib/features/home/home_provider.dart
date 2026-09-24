import 'package:flutter/material.dart';
import 'package:pure_live/exports/app_export.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/menu_icons/menu_icon_controller.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';

part 'home_provider.g.dart';

/// Side-menu destinations.
///
/// The value is the identity that flows through
/// [SideMenuIndex]/[TvMenuType.fromIndex]; every [AppMenuItem] must carry the
/// value of its own entry. A mismatch used to make the settings entry select
/// `-2`, which matched nothing and silently fell back to [favorite], so the
/// settings button opened the followed-rooms page.
///
/// `profile` is gone: the slot the mobile app spent on account is the home
/// sidebar's backup header now, which pushes the backup page instead of swapping
/// the content pane, so it never participates in the menu index.
enum TvMenuType {
  favorite(0),
  hot(1),
  areas(2),
  favoriteAreas(3),
  moviePlayback(4),
  search(5),
  history(6),
  settings(99);

  final int value;
  const TvMenuType(this.value);

  static TvMenuType fromIndex(int idx) {
    for (var type in TvMenuType.values) {
      if (type.value == idx) {
        return type;
      }
    }
    return TvMenuType.favorite;
  }
}

class AppMenuItem {
  /// Must be one of the [TvMenuType] values, not an ad-hoc constant.
  final int index;
  final String title;

  /// The two-character caption the collapsed sidebar paints under the icon.
  ///
  /// The full [title] is too long to fit the
  /// 110dp icon rail; the short form keeps every destination readable without
  /// expanding the sidebar. Empty falls back to [title].
  final String shortTitle;
  final IconData icon;

  AppMenuItem({required this.index, required this.title, required this.icon, String? shortTitle})
    : shortTitle = shortTitle ?? '';
}

/// Side menu entries in the order configured in settings, limited to the
/// visible ones. An empty configuration shows every entry in default order.
@riverpod
List<AppMenuItem> sideMenuList(Ref ref) {
  final saved = ref.watch(appSettingsControllerProvider).savedMenuIds;
  final overrides = ref.watch(menuIconOverridesProvider);
  final ids = saved.isEmpty ? HomeMenu.defaultOrder : AppSettingsController.normalizeMenuIds(saved);
  return [for (final id in ids) ?_sideMenuItem(id, overrides)];
}

AppMenuItem? _sideMenuItem(String id, Map<String, IconData> overrides) {
  IconData withOverride(IconData fallback) => overrides[id] ?? fallback;

  return switch (HomeMenu.fromId(id)) {
    HomeMenu.favorite => AppMenuItem(
      index: TvMenuType.favorite.value,
      title: i18n('ui_following'),
      shortTitle: i18n('menu_short_following'),
      icon: withOverride(Icons.favorite_border),
    ),
    HomeMenu.hot => AppMenuItem(
      index: TvMenuType.hot.value,
      title: i18n('kilakila_hot'),
      shortTitle: i18n('menu_short_hot'),
      icon: withOverride(Icons.local_fire_department_outlined),
    ),
    // Categories and followed categories are different destinations, so they
    // must not share the same grid glyph.
    HomeMenu.areas => AppMenuItem(
      index: TvMenuType.areas.value,
      title: i18n('ui_category'),
      shortTitle: i18n('menu_short_category'),
      icon: withOverride(RemixIcons.function_line),
    ),
    HomeMenu.favoriteAreas => AppMenuItem(
      index: TvMenuType.favoriteAreas.value,
      title: i18n('favorite_areas'),
      shortTitle: i18n('menu_short_areas'),
      icon: withOverride(Icons.collections_bookmark_outlined),
    ),
    HomeMenu.moviePlayback => AppMenuItem(
      index: TvMenuType.moviePlayback.value,
      title: i18n('ui_link_playback'),
      shortTitle: i18n('menu_short_link_playback'),
      icon: withOverride(Icons.movie_creation_outlined),
    ),
    HomeMenu.search => AppMenuItem(
      index: TvMenuType.search.value,
      title: i18n('search_live'),
      shortTitle: i18n('menu_short_search'),
      icon: withOverride(Icons.search_rounded),
    ),
    HomeMenu.history => AppMenuItem(
      index: TvMenuType.history.value,
      title: i18n('watch_history'),
      shortTitle: i18n('menu_short_history'),
      icon: withOverride(Icons.history),
    ),
    null => null,
  };
}

@riverpod
AppMenuItem mySettingsMenuItem(Ref ref) {
  return AppMenuItem(
    index: TvMenuType.settings.value,
    title: i18n('settings'),
    shortTitle: i18n('menu_short_settings'),
    icon: ref.watch(menuIconOverridesProvider)['settings'] ?? Icons.settings_outlined,
  );
}

@riverpod
class SideMenuIndex extends _$SideMenuIndex {
  @override
  int build() => 0;

  void changeIndex(int newIndex) {
    state = newIndex;
  }
}

@riverpod
class IsMenuExpanded extends _$IsMenuExpanded {
  @override
  bool build() => false;

  void toggle() {
    state = !state;
  }
}
