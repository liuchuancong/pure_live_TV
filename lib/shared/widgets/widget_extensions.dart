import 'tv_settings_card.dart';
import 'tv_settings_menu_tile.dart';
import 'tv_settings_nav_tile.dart';
import 'tv_settings_switch_tile.dart';
import 'tv_settings_slider_tile.dart';
import 'package:flutter/material.dart';

extension AppLayoutFactory on BuildContext {
  Widget buildGroupTitle(String text) {
    return TvSettingsGroupTitle(title: text);
  }

  Widget buildModernCard(List<Widget> children) {
    return TvSettingsCard(children: children);
  }

  Widget buildSwitchTile({
    required String title,
    required bool value,
    IconData? icon,
    String? subtitle,
    Color? iconColor,
    Color? subtitleColor,
    bool isLong = false,
    ValueChanged<bool>? onChanged,
  }) {
    return TvSettingsSwitchTile(title: title, subtitle: subtitle, icon: icon, value: value, onChanged: onChanged);
  }

  Widget buildTile({
    required String title,
    IconData? icon,
    Widget? leading,
    String? subtitle,
    Future<void> Function()? onTap,
    Color? iconColor,
    Color? subtitleColor,
    Widget? trailing,
    bool isLong = false,
  }) {
    return TvSettingsMenuTile<void>(
      title: title,
      subtitle: subtitle,
      icon: icon,
      leading: leading,
      value: null,
      valueMap: const {},
      onTap: onTap,
      trailing: trailing,
    );
  }

  Widget buildMenuTile<T>({
    required String title,
    required T value,
    required Map<T, String> valueMap,
    required Function(T) onChanged,
    Future<void> Function()? onTap,
    IconData? icon,
    String? subtitle,
    Color? iconColor,
    Color? subtitleColor,
    bool isLong = false,
  }) {
    return TvSettingsMenuTile<T>(
      title: title,
      subtitle: subtitle,
      icon: icon,
      value: value,
      valueMap: valueMap,
      onTap: onTap,
      onChanged: onChanged,
    );
  }

  Widget buildSliderTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required double value,
    required double min,
    required double max,
    required String displayValue,
    required ValueChanged<double> onChanged,
    double step = 1.0,
  }) {
    return TvSettingsSliderTile(
      title: title,
      icon: icon,
      value: value,
      min: min,
      max: max,
      displayValue: displayValue,
      onChanged: onChanged,
      step: step,
    );
  }
}
