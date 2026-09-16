import 'package:flutter/material.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/widgets/tv_settings_row.dart';

/// TV settings row for a discrete choice (quality, player kernel, aspect
/// ratio, ...).
///
/// OK opens a scrollable selection dialog. Stepping with Left/Right is gone: it
/// hid the alternatives, needed one press per option, and consumed the
/// horizontal keys that focus traversal needs.
class TvSettingsOptionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final List<String> options;
  final int index;
  final ValueChanged<int>? onChanged;

  const TvSettingsOptionTile({
    super.key,
    required this.title,
    required this.options,
    required this.index,
    this.subtitle,
    this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeIndex = (index < 0 || index >= options.length) ? 0 : index;
    final currentOption = options.isEmpty ? '' : options[safeIndex];

    return TvSettingsRow(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onSelect: options.isEmpty ? null : () => _openSelector(context, safeIndex),
      trailingBuilder: (context, focused) => tvSettingsValueLabel(context, focused, currentOption),
    );
  }

  Future<void> _openSelector(BuildContext context, int safeIndex) async {
    final selected = await TvDialogUtils.showSelect<int>(
      context: context,
      title: title,
      selectedValue: safeIndex,
      items: <TvSelectItem<int>>[
        for (int i = 0; i < options.length; i++) TvSelectItem<int>(title: options[i], value: i),
      ],
    );
    if (selected == null || selected == safeIndex) return;
    onChanged?.call(selected);
  }
}
