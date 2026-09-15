import 'package:flutter/material.dart';
import 'package:pure_live/shared/widgets/tv_settings_row.dart';

class TvSettingsMenuTile<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  /// Replaces [icon] when the row is identified by artwork or a swatch.
  final Widget? leading;
  final T? value;
  final Map<T, String> valueMap;
  final ValueChanged<T>? onChanged;
  final Future<void> Function()? onTap;
  final Widget? trailing;

  const TvSettingsMenuTile({
    super.key,
    required this.title,
    this.value,
    this.valueMap = const {},
    this.onChanged,
    this.subtitle,
    this.icon,
    this.leading,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final display = value != null ? (valueMap[value] ?? value.toString()) : '';
    final keys = valueMap.keys.toList();
    final currentIndex = value != null ? keys.indexOf(value as T) : -1;

    return TvSettingsRow(
      title: title,
      subtitle: subtitle,
      icon: icon,
      leading: leading,
      onSelect: () => onTap?.call(),
      onDirection: (direction) {
        if (onChanged == null || keys.isEmpty || currentIndex == -1) {
          return false;
        }
        // Only consume the key while the value can actually change; consuming
        // it at the first/last entry would trap focus on the row.
        final int? nextIndex = switch (direction) {
          TraversalDirection.left when currentIndex > 0 => currentIndex - 1,
          TraversalDirection.right when currentIndex < keys.length - 1 => currentIndex + 1,
          _ => null,
        };
        if (nextIndex == null) return false;
        onChanged!(keys[nextIndex]);
        return true;
      },
      trailingBuilder: (context, focused) {
        if (trailing != null) return trailing!;
        if (value == null) return tvSettingsChevron(context, focused);
        return tvSettingsValueStepper(context, focused, display);
      },
    );
  }
}
