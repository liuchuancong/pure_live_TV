import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

/// TV settings row that cycles through its options on the OK key.
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
    final theme = Theme.of(context);
    final safeIndex = (index < 0 || index >= options.length) ? 0 : index;
    final currentOption = options[safeIndex];

    return DpadFocusable(
      effects: [
        DpadScaleEffect(scale: 1.02),
        DpadGlowEffect(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ],
      onSelect: () {
        final next = (safeIndex + 1) % options.length;
        onChanged?.call(next);
      },
      onDirection: (direction) {
        if (direction == TraversalDirection.right) {
          onChanged?.call((safeIndex + 1) % options.length);
          return true;
        } else if (direction == TraversalDirection.left) {
          onChanged?.call((safeIndex - 1 + options.length) % options.length);
          return true;
        }
        return false;
      },
      builder: (context, state, child) {
        return Container(
          decoration: BoxDecoration(
            color: state.focused ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (icon != null) ...[
                Icon(icon, color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 12,
                          color: state.focused
                              ? theme.colorScheme.primary.withValues(alpha: 0.7)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.chevron_left,
                    size: 18,
                    color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    currentOption,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ],
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
