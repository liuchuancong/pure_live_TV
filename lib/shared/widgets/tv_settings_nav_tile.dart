import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/tv_settings_row.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Settings row that opens another page.
///
/// A navigation row does not react to Left/Right, and it renders
/// through [TvSettingsRow] so every other settings row shares its look.
class TvSettingsNavTile extends StatelessWidget {
  const TvSettingsNavTile({
    super.key,
    required this.title,
    this.icon,
    this.leading,
    this.trailing,
    required this.onTap,
    this.subtitle,
  }) : assert(icon != null || leading != null, 'A row needs an icon or a leading widget');

  final String title;
  final String? subtitle;
  final IconData? icon;

  /// Replaces [icon] when the row is identified by artwork or a swatch.
  final Widget? leading;

  /// Replaces the trailing chevron.
  final Widget? trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TvSettingsRow(
      title: title,
      subtitle: subtitle,
      icon: icon,
      leading: leading,
      onSelect: onTap,
      trailingBuilder: (context, focused) => trailing ?? tvSettingsChevron(context, focused),
    );
  }
}

/// Small coloured heading above a group of [TvSettingsNavTile]s.
class TvSettingsGroupTitle extends StatelessWidget {
  const TvSettingsGroupTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    // The TV palette, not the Material scheme: the scheme's primary follows the
    // theme mode and drifted to a washed-out grey-blue on some presets, while the
    // rows below already use the palette accent — one heading, one accent.
    final theme = context.tvTheme;
    return Padding(
      padding: EdgeInsets.only(left: 8.sp, bottom: 8.sp),
      child: Text(
        title,
        style: AppTextStyles.t16W600.copyWith(
          fontWeight: FontWeight.bold,
          color: theme.focusColor.withValues(alpha: 0.85),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
