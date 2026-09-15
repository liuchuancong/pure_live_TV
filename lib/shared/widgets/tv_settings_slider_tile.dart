import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class TvSettingsSliderTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final String displayValue;
  final ValueChanged<double> onChanged;
  final double step;

  const TvSettingsSliderTile({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.value,
    required this.min,
    required this.max,
    required this.displayValue,
    required this.onChanged,
    this.step = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final double progress = ((value - min) / (max - min)).clamp(0.0, 1.0);

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
      onDirection: (direction) {
        if (direction != TraversalDirection.left && direction != TraversalDirection.right) {
          return false;
        }
        final double delta = direction == TraversalDirection.left ? -step : step;
        final double newValue = (value + delta).clamp(min, max);
        // At the minimum/maximum the value no longer changes: release the key
        // so focus can leave the slider instead of being trapped on it.
        if (newValue == value) return false;
        onChanged(newValue);
        return true;
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
                Icon(icon, color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                            ),
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.arrow_left,
                                size: 16,
                                color: state.focused ? theme.colorScheme.primary : Colors.grey,
                              ),
                              Text(
                                displayValue,
                                style: TextStyle(
                                  color: state.focused ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Icon(
                                Icons.arrow_right,
                                size: 16,
                                color: state.focused ? theme.colorScheme.primary : Colors.grey,
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 12,
                            color: state.focused
                                ? theme.colorScheme.primary.withValues(alpha: 0.8)
                                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.surfaceContainerHighest,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            state.focused ? theme.colorScheme.primary : theme.colorScheme.outline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
