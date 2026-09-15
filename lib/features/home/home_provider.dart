import 'package:flutter/material.dart';
import 'package:pure_live/services/menu_icons/menu_icon_controller.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';

part 'home_provider.g.dart';

/// Side-menu destinations.
///
/// The value is the identity that flows through
/// [SideMenuIndex]/[TvMenuType.fromIndex]; every [AppMenuItem] must carry the
/// value of its own entry. A mismatch used to make the settings entry select
/// `-2`, which matched nothing and silently fell back to [favorite], so the
/// settings button opened the followed-rooms page.
enum TvMenuType {
  profile(-1),
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
  final IconData icon;

  AppMenuItem({required this.index, required this.title, required this.icon});
}

@riverpod
AppMenuItem myProfileMenuItem(Ref ref) {
  return AppMenuItem(
    index: TvMenuType.profile.value,
    title: i18n('ui_my_account'),
    // The icon picker may have re-pointed this entry at another icon.
    icon: ref.watch(menuIconOverridesProvider)['profile'] ?? Icons.account_circle_outlined,
  );
}

/// Side menu entries in the order configured in settings, limited to the
/// visible ones. An empty configuration shows every entry in default order.
@riverpod
List<AppMenuItem> sideMenuList(Ref ref) {
  final saved = ref.watch(appSettingsControllerProvider).savedMenuIds;
  final overrides = ref.watch(menuIconOverridesProvider);
  final ids = saved.isEmpty ? HomeMenu.defaultOrder : AppSettingsController.normalizeMenuIds(saved);
  return [
    for (final id in ids)
      ?_sideMenuItem(id, overrides),
  ];
}

AppMenuItem? _sideMenuItem(String id, Map<String, IconData> overrides) {
  IconData withOverride(IconData fallback) => overrides[id] ?? fallback;

  return switch (HomeMenu.fromId(id)) {
    HomeMenu.favorite => AppMenuItem(
      index: TvMenuType.favorite.value,
      title: i18n('ui_following'),
      icon: withOverride(Icons.favorite_border),
    ),
    HomeMenu.hot => AppMenuItem(
      index: TvMenuType.hot.value,
      title: i18n('kilakila_hot'),
      icon: withOverride(Icons.local_fire_department_outlined),
    ),
    // Categories and followed categories are different destinations, so they
    // must not share the same grid glyph.
    HomeMenu.areas => AppMenuItem(
      index: TvMenuType.areas.value,
      title: i18n('ui_category'),
      icon: withOverride(Icons.category_rounded),
    ),
    HomeMenu.favoriteAreas => AppMenuItem(
      index: TvMenuType.favoriteAreas.value,
      title: i18n('favorite_areas'),
      icon: withOverride(Icons.collections_bookmark_outlined),
    ),
    HomeMenu.moviePlayback => AppMenuItem(
      index: TvMenuType.moviePlayback.value,
      title: i18n('ui_link_playback'),
      icon: withOverride(Icons.movie_creation_outlined),
    ),
    HomeMenu.search => AppMenuItem(
      index: TvMenuType.search.value,
      title: i18n('search_live'),
      icon: withOverride(Icons.search_rounded),
    ),
    HomeMenu.history => AppMenuItem(
      index: TvMenuType.history.value,
      title: i18n('watch_history'),
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
