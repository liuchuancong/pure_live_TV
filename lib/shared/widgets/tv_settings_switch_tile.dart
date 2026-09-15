import 'package:flutter/material.dart';
import 'package:pure_live/shared/widgets/tv_settings_row.dart';

class TvSettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Leading widget for rows identified by artwork (platform logos).
  final Widget? leading;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const TvSettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.leading,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TvSettingsRow(
      title: title,
      subtitle: subtitle,
      icon: icon,
      leading: leading,
      // The remote toggles with OK; the indicator is presentation only, which
      // is also why it is not the Material switch.
      onSelect: () => onChanged?.call(!value),
      onDirection: (direction) {
        if (direction == TraversalDirection.left && value) {
          onChanged?.call(false);
          return true;
        } else if (direction == TraversalDirection.right && !value) {
          onChanged?.call(true);
          return true;
        }
        return false;
      },
      trailingBuilder: (context, focused) => TvSettingsSwitchIndicator(value: value, focused: focused),
    );
  }
}
