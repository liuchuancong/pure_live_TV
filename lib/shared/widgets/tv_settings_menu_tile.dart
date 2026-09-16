import 'package:flutter/material.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/widgets/tv_settings_row.dart';

/// Settings row whose value comes from a fixed map, or which opens a page.
///
/// A row with a value opens the same scrollable selection dialog as
/// `TvSettingsOptionTile`; a row with only [onTap] keeps the trailing chevron.
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
    final bool hasChoices = value != null && valueMap.isNotEmpty && onChanged != null;

    return TvSettingsRow(
      title: title,
      subtitle: subtitle,
      icon: icon,
      leading: leading,
      onSelect: hasChoices ? () => _openSelector(context) : () => onTap?.call(),
      trailingBuilder: (context, focused) {
        if (trailing != null) return trailing!;
        if (!hasChoices) return tvSettingsChevron(context, focused);
        return tvSettingsValueLabel(context, focused, display);
      },
    );
  }

  Future<void> _openSelector(BuildContext context) async {
    final keys = valueMap.keys.toList();
    final selected = await TvDialogUtils.showSelect<T>(
      context: context,
      title: title,
      selectedValue: value,
      items: <TvSelectItem<T>>[for (final key in keys) TvSelectItem<T>(title: valueMap[key] ?? '$key', value: key)],
    );
    if (selected == null || selected == value) return;
    onChanged?.call(selected);
  }
}
