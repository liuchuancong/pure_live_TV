import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class TvSettingsMenuTile<T> extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? iconWidget;
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
    this.iconWidget,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final display = value != null ? (valueMap[value] ?? value.toString()) : '';
    final keys = valueMap.keys.toList();
    final currentIndex = value != null ? keys.indexOf(value as T) : -1;

    return DpadFocusable(
      effects: [
        DpadScaleEffect(scale: 1.02),
        DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
      ],
      onSelect: () => onTap?.call(),
      onDirection: (direction) {
        if (onChanged == null || keys.isEmpty || currentIndex == -1) {
          return false;
        }
        if (direction == TraversalDirection.left) {
          final nextIndex = (currentIndex - 1 + keys.length) % keys.length;
          onChanged!(keys[nextIndex]);
          return true;
        } else if (direction == TraversalDirection.right) {
          final nextIndex = (currentIndex + 1) % keys.length;
          onChanged!(keys[nextIndex]);
          return true;
        }
        return false;
      },
      builder: (context, state, child) {
        return Container(
          decoration: BoxDecoration(
            color: state.focused ? theme.colorScheme.primaryContainer.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (iconWidget != null) ...[
                iconWidget!,
                const SizedBox(width: 12),
              ] else if (icon != null) ...[
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
                              ? theme.colorScheme.primary.withOpacity(0.7)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (trailing != null)
                trailing!
              else if (value != null)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_left, size: 16, color: state.focused ? theme.colorScheme.primary : Colors.grey),
                    Text(
                      display,
                      style: TextStyle(
                        color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Icon(Icons.arrow_right, size: 16, color: state.focused ? theme.colorScheme.primary : Colors.grey),
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
