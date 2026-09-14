import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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

@riverpod
List<AppMenuItem> sideMenuList(Ref ref) {
  return [
    AppMenuItem(index: 0, title: i18n('ui_following'), icon: Icons.favorite_border),
    AppMenuItem(index: 1, title: i18n('kilakila_hot'), icon: Icons.local_fire_department_outlined),
    AppMenuItem(index: 2, title: i18n('ui_category'), icon: Icons.apps_rounded),
    AppMenuItem(index: 3, title: i18n('favorite_areas'), icon: Icons.view_module_rounded),
    AppMenuItem(index: 4, title: i18n('ui_link_playback'), icon: Icons.movie_creation_outlined),
    AppMenuItem(index: 5, title: i18n('search_live'), icon: Icons.search_rounded),
    AppMenuItem(index: 6, title: i18n('watch_history'), icon: Icons.history),
  ];
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
