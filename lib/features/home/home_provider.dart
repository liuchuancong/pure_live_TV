import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/app_settings/app_settings_controller.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

part 'home_provider.g.dart';

enum TvMenuType {
  profile(-1),
  favorite(0),
  hot(1),
  areas(2),
  favoriteAreas(3),
  poviePlaybackPage(4),
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
  final int index;
  final String title;
  final IconData icon;

  AppMenuItem({required this.index, required this.title, required this.icon});
}

@riverpod
AppMenuItem myProfileMenuItem(Ref ref) {
  return AppMenuItem(index: -1, title: i18n('ui_my_account'), icon: Icons.account_circle_outlined);
}

/// Side menu entries in the order configured in settings, limited to the
/// visible ones. An empty configuration shows every entry in default order.
@riverpod
List<AppMenuItem> sideMenuList(Ref ref) {
  final saved = ref.watch(appSettingsControllerProvider).savedMenuIds;
  final ids = saved.isEmpty ? HomeMenu.defaultOrder : AppSettingsController.normalizeMenuIds(saved);
  return [
    for (final id in ids)
      if (_sideMenuItem(id) case final item?) item,
  ];
}

AppMenuItem? _sideMenuItem(String id) {
  return switch (HomeMenu.fromId(id)) {
    HomeMenu.favorite => AppMenuItem(index: 0, title: i18n('ui_following'), icon: Icons.favorite_border),
    HomeMenu.hot => AppMenuItem(index: 1, title: i18n('kilakila_hot'), icon: Icons.local_fire_department_outlined),
    HomeMenu.areas => AppMenuItem(index: 2, title: i18n('ui_category'), icon: Icons.apps_rounded),
    HomeMenu.favoriteAreas => AppMenuItem(index: 3, title: i18n('favorite_areas'), icon: Icons.view_module_rounded),
    HomeMenu.moviePlayback => AppMenuItem(index: 4, title: i18n('ui_link_playback'), icon: Icons.movie_creation_outlined),
    HomeMenu.search => AppMenuItem(index: 5, title: i18n('search_live'), icon: Icons.search_rounded),
    HomeMenu.history => AppMenuItem(index: 6, title: i18n('watch_history'), icon: Icons.history),
    null => null,
  };
}

@riverpod
AppMenuItem mySettingsMenuItem(Ref ref) {
  return AppMenuItem(index: -2, title: i18n('settings'), icon: Icons.settings_outlined);
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
