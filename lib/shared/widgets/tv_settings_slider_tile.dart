import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';

class TvSettingsSliderTile extends StatelessWidget {
  final String title;
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

    return DpadFocusable(
      effects: [
        DpadScaleEffect(scale: 1.02),
        DpadGlowEffect(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ],
      onDirection: (direction) {
        if (direction == TraversalDirection.left) {
          final newValue = (value - step).clamp(min, max);
          onChanged(newValue);
          return true;
        } else if (direction == TraversalDirection.right) {
          final newValue = (value + step).clamp(min, max);
          onChanged(newValue);
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
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
