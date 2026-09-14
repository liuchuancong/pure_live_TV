import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

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

  const AppMenuItem({required this.index, required this.title, required this.icon});
}

@riverpod
AppMenuItem myProfileMenuItem(Ref ref) {
  return const AppMenuItem(index: -1, title: '我的账户', icon: Icons.account_circle_outlined);
}

@riverpod
List<AppMenuItem> sideMenuList(Ref ref) {
  return const [
    AppMenuItem(index: 0, title: '直播关注', icon: Icons.favorite_border),
    AppMenuItem(index: 1, title: '热门直播', icon: Icons.local_fire_department_outlined),
    AppMenuItem(index: 2, title: '分区类别', icon: Icons.apps_rounded),
    AppMenuItem(index: 3, title: '关注分区', icon: Icons.view_module_rounded),
    AppMenuItem(index: 4, title: '链接放映', icon: Icons.movie_creation_outlined),
    AppMenuItem(index: 5, title: '搜索直播', icon: Icons.search_rounded),
    AppMenuItem(index: 6, title: '观看记录', icon: Icons.history),
  ];
}

@riverpod
AppMenuItem mySettingsMenuItem(Ref ref) {
  return const AppMenuItem(index: -2, title: '系统设置', icon: Icons.settings_outlined);
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
