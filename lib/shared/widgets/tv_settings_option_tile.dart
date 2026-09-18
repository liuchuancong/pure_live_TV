import 'dart:async';

import 'package:flutter/material.dart';
import 'package:pure_live/shared/dialog/index.dart';
import 'package:pure_live/shared/widgets/tv_settings_row.dart';

/// TV settings row for a discrete choice (quality, player kernel, aspect
/// ratio, ...).
///
/// OK opens a scrollable selection dialog. Stepping with Left/Right is gone: it
/// hid the alternatives, needed one press per option, and consumed the
/// horizontal keys that focus traversal needs.
///
/// A single-option row is an *action* row (export config, clear cache, save proxy, ...), not
/// a choice: opening a one-item list would show the item already selected, and
/// the dialog reports "nothing changed", so `onChanged` never ran and every one
/// of those rows was dead. Those rows now run their action on OK and wear a
/// chevron instead of a value with a drop-down arrow.
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

  bool get _isAction => options.length <= 1;

  @override
  Widget build(BuildContext context) {
    final safeIndex = (index < 0 || index >= options.length) ? 0 : index;
    final currentOption = options.isEmpty ? '' : options[safeIndex];

    return TvSettingsRow(
      title: title,
      subtitle: subtitle,
      icon: icon,
      onSelect: options.isEmpty ? null : () => _select(context, safeIndex),
      trailingBuilder: _isAction
          ? tvSettingsChevron
          : (context, focused) => tvSettingsValueLabel(context, focused, currentOption),
    );
  }

  void _select(BuildContext context, int safeIndex) {
    if (_isAction) {
      onChanged?.call(safeIndex);
      return;
    }
    unawaited(_openSelector(context, safeIndex));
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
