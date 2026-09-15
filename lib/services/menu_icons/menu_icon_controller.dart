import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/consts/icon_catalog.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';

/// Menu entries whose icon the user may replace from the icon picker.
List<String> iconCustomisableMenuIds() => <String>[
  'profile',
  for (final HomeMenu menu in HomeMenu.values) menu.id,
  'settings',
];

/// The catalog entry with [label], or null when the label is unknown.
IconOption? iconOptionForLabel(String label) {
  for (final IconOption option in kIconCatalog) {
    if (option.label == label) return option;
  }
  return null;
}

/// Icon overrides for the home side menu, keyed by menu id.
///
/// The home menu used to be the closed set of icons hard-coded in
/// `home_provider`; the picker lets the user re-point an entry at an icon that
/// actually says what the entry does. Only the catalog *label* is persisted, so
/// the stored value stays readable and no `IconData` has to be rebuilt from a
/// code point (which cannot be constructed outside a constant context).
final menuIconOverridesProvider = NotifierProvider<MenuIconOverrides, Map<String, IconData>>(
  MenuIconOverrides.new,
);

class MenuIconOverrides extends Notifier<Map<String, IconData>> {
  static const String _labelPrefix = 'menuIconLabel_';

  @override
  Map<String, IconData> build() {
    final Map<String, IconData> overrides = <String, IconData>{};
    try {
      for (final String id in iconCustomisableMenuIds()) {
        final String? label = HivePrefUtil.getString('$_labelPrefix$id');
        if (label == null || label.isEmpty) continue;
        final IconOption? option = iconOptionForLabel(label);
        if (option != null) overrides[id] = option.icon;
      }
    } catch (_) {
      // Storage not ready: fall back to the built-in icons rather than
      // breaking the home page.
      return const <String, IconData>{};
    }
    return overrides;
  }

  String? labelFor(String menuId) => HivePrefUtil.getString('$_labelPrefix$menuId');

  Future<void> setIcon(String menuId, IconOption option) async {
    await HivePrefUtil.setString('$_labelPrefix$menuId', option.label);
    state = <String, IconData>{...state, menuId: option.icon};
  }

  Future<void> resetIcon(String menuId) async {
    await HivePrefUtil.setString('$_labelPrefix$menuId', '');
    final Map<String, IconData> next = Map<String, IconData>.from(state)..remove(menuId);
    state = next;
  }
}
