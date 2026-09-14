import 'package:flutter/material.dart';

class TvSettingsTile extends StatelessWidget {
  final String title;

  final String? subtitle;

  final IconData? icon;

  final Widget? iconWidget;

  final Widget? trailing;

  final VoidCallback? onTap;

  const TvSettingsTile({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.iconWidget,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget? leading;

    if (iconWidget != null) {
      leading = iconWidget;
    } else if (icon != null) {
      leading = Icon(icon, color: theme.colorScheme.primary);
    }

    return ListTile(
      leading: leading,

      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),

      subtitle: subtitle == null ? null : Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis),

      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right_rounded) : null),

      onTap: onTap,
    );
  }
}
