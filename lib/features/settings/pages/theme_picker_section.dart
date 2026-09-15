import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Theme picker.
///
/// The preset list lives on its own page instead of being a row per preset on
/// the theme settings page: the list grows with every added preset and needs
/// room for a colour preview, and the theme settings page then only holds the
/// options that are not a preset choice.
class ThemePickerSectionPage extends ConsumerWidget {
  const ThemePickerSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(tvThemeControllerProvider.notifier);
    final current = ref.watch(tvThemeControllerProvider);
    final tvTheme = context.tvTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TvSettingsGroupTitle(title: i18n('ui_theme')),
        TvSettingsCard(
          children: [
            for (final TvThemeData theme in controller.themes)
              TvSettingsNavTile(
                title: theme.name,
                subtitle: theme.id == current.id ? i18n('ui_current_theme') : null,
                leading: _ThemeSwatch(theme: theme, active: theme.id == current.id),
                trailing: theme.id == current.id
                    ? Icon(Icons.check_rounded, size: 30.sp, color: tvTheme.focusColor)
                    : null,
                onTap: () => controller.switchTheme(theme),
              ),
          ],
        ),
      ],
    );
  }
}

/// Palette preview: the accent inside a card-coloured square, with a border
/// rather than a rounded corner.
class _ThemeSwatch extends StatelessWidget {
  const _ThemeSwatch({required this.theme, required this.active});

  final TvThemeData theme;
  final bool active;

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return Container(
      width: 44.sp,
      height: 44.sp,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: theme.cardColor,
        border: Border.all(
          color: active ? tvTheme.focusColor : theme.focusColor.withValues(alpha: 0.7),
          width: 2.sp,
        ),
      ),
      child: Container(width: 20.sp, height: 20.sp, color: theme.focusColor),
    );
  }
}
