import 'package:pure_live/common/index.dart';

class TvSettingsSwitchTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;
  final RxBool value;
  final ValueChanged<bool>? onChanged;

  const TvSettingsSwitchTile({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DpadFocusable(
      effects: [
        DpadScaleEffect(scale: 1.02),
        DpadGlowEffect(color: theme.colorScheme.primary.withOpacity(0.3)),
      ],
      onSelect: () {
        final newValue = !value.value;
        value.value = newValue;
        onChanged?.call(newValue);
      },
      onDirection: (direction) {
        if (direction == TraversalDirection.left && value.value) {
          value.value = false;
          onChanged?.call(false);
          return true;
        } else if (direction == TraversalDirection.right && !value.value) {
          value.value = true;
          onChanged?.call(true);
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
                              ? theme.colorScheme.primary.withOpacity(0.7)
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Obx(
                () => Switch(
                  value: value.value,
                  onChanged: (v) {
                    value.value = v;
                    onChanged?.call(v);
                  },
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
