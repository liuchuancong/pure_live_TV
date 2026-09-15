import 'package:flutter/material.dart';
import 'package:pure_live/shared/widgets/tv_settings_row.dart';

/// TV settings row that cycles through its options with Left/Right and OK.
/// Used for discrete settings such as quality, player kernel and aspect ratio.
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
      onSelect: () {
        if (options.isEmpty) return;
        onChanged?.call((safeIndex + 1) % options.length);
      },
      onDirection: (direction) {
        // Left/right adjust the value, but only while the value can still
        // change in that direction. Consuming the key at the first/last option
        // would trap focus on the row and make the neighbouring rows and
        // regions unreachable with the remote.
        final int? next = switch (direction) {
          TraversalDirection.left when safeIndex > 0 => safeIndex - 1,
          TraversalDirection.right when safeIndex < options.length - 1 => safeIndex + 1,
          _ => null,
        };
        if (next == null) return false;
        onChanged?.call(next);
        return true;
      },
      trailingBuilder: (context, focused) => tvSettingsValueStepper(context, focused, currentOption),
    );
  }
}
