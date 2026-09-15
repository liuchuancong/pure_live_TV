import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class TvSettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Leading widget for rows identified by artwork (platform logos).
  final Widget? iconWidget;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const TvSettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.iconWidget,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // `DpadFocusable` asserts that `effects` and `builder` are never both
    // supplied, so the glow and scale are applied around the builder's own
    // presentation instead of being passed to the focusable.
    final List<DpadEffect> effects = [
      DpadScaleEffect(scale: 1.02),
      DpadGlowEffect(
        color: theme.colorScheme.primary.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
      ),
    ];

    return DpadFocusable(
      onSelect: () {
        onChanged?.call(!value);
      },
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
      builder: (context, state, child) {
        return DpadEffect.wrap(
          context,
          effects,
          state,
          Container(
            decoration: BoxDecoration(
              color: state.focused ? theme.colorScheme.primaryContainer.withValues(alpha: 0.15) : Colors.transparent,
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
                                ? theme.colorScheme.primary.withValues(alpha: 0.7)
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Switch(value: value, onChanged: onChanged),
              ],
            ),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
