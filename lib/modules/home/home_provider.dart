import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppMenuItem {
  final int index;
  final String title;
  final IconData icon;

  const AppMenuItem({required this.index, required this.title, required this.icon});
}

final myProfileMenuItemProvider = Provider<AppMenuItem>(
  (ref) => const AppMenuItem(index: -1, title: '我的账户', icon: Icons.account_circle_outlined),
);

final sideMenuListProvider = Provider<List<AppMenuItem>>(
  (ref) => const [
    AppMenuItem(index: 0, title: '直播关注', icon: Icons.favorite_border),
    AppMenuItem(index: 1, title: '热门直播', icon: Icons.local_fire_department_outlined),
    AppMenuItem(index: 2, title: '分区类别', icon: Icons.apps_rounded),
    AppMenuItem(index: 3, title: '关注分区', icon: Icons.view_module_rounded),
    AppMenuItem(index: 4, title: '链接放映', icon: Icons.movie_creation_outlined),
    AppMenuItem(index: 5, title: '搜索直播', icon: Icons.search_rounded),
    AppMenuItem(index: 6, title: '观看记录', icon: Icons.history),
  ],
);

final mySettingsMenuItemProvider = Provider<AppMenuItem>(
  (ref) => const AppMenuItem(index: -2, title: '系统设置', icon: Icons.settings_outlined),
);

final sideMenuIndexProvider = StateProvider.autoDispose<int>((ref) => 0);

final isMenuExpandedProvider = StateProvider.autoDispose<bool>((ref) => false);
