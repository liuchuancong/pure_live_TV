import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/settings/tv_settings_option_tile.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

class ThemeSettingsSectionPage extends ConsumerWidget {
  const ThemeSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(tvThemeControllerProvider);
    final themeState = ref.watch(themeSettingsControllerProvider);
    final theme = ref.read(themeSettingsControllerProvider.notifier);
    final themeModes = AppConsts.themeModes.keys.toList(growable: false);
    final loadingStyles = AppConsts.allStyles;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // The preset list lives on its own page now: it grows with every
          // added preset and needs room for a colour preview.
          TvSettingsNavTile(
            title: i18n('ui_theme'),
            subtitle: currentTheme.name,
            icon: Remix.palette_line,
            onTap: () => context.push(AppRoutes.kSettingsThemePicker),
          ),
          SizedBox(height: 8.sp),
          TvSettingsMenuTile<void>(
            title: i18n('ui_background_settings'),
            subtitle: i18n('background_entry_subtitle'),
            icon: Remix.image_line,
            onTap: () async => context.push(AppRoutes.kWallpaperPage),
          ),
          TvSettingsOptionTile(
            title: i18n('theme_mode'),
            // Icon taken from the desktop theme page (moon), so the same row
            // looks the same in both apps.
            icon: Remix.moon_clear_line,
            options: [for (final mode in themeModes) i18n(AppConsts.themeModeI18n[mode] ?? mode)],
            index: themeModes.indexOf(themeState.themeModeName).clamp(0, themeModes.length - 1),
            onChanged: (index) => theme.changeThemeMode(themeModes[index]),
          ),
          TvSettingsOptionTile(
            title: i18n('change_loading_style'),
            subtitle: i18n('change_loading_style_subtitle'),
            icon: Remix.loader_4_line,
            options: [for (final style in loadingStyles) _loadingStyleName(style)],
            index: loadingStyles.indexWhere((e) => e['key'] == themeState.loadingStyle).clamp(0, loadingStyles.length - 1),
            onChanged: (index) => theme.updateSettings(themeState.copyWith(loadingStyle: loadingStyles[index]['key'] ?? 'default')),
          ),
          TvSettingsOptionTile(
            title: i18n('loading_style_color'),
            subtitle: i18n('loading_style_color_desc'),
            icon: Remix.brush_line,
            options: [i18n('follow_theme_color'), ...colorNames],
            index: _loadingColorIndex(themeState.loadingStyleColor),
            onChanged: (index) {
              final color = index == 0 ? null : _loadingColors[index - 1];
              theme.updateSettings(themeState.copyWith(loadingStyleColor: color));
            },
          ),
          TvSettingsSwitchTile(
            title: i18n('ui_dynamic_theme_color'),
            subtitle: i18n('ui_derive_the_theme_color_from_the_cover_image'),
            icon: Remix.magic_line,
            value: themeState.enableDynamicTheme,
            onChanged: (v) => theme.updateSettings(themeState.copyWith(enableDynamicTheme: v)),
          ),
          TvSettingsSliderTile(
            title: i18n('ui_horizontal_card_spacing'),
            icon: Remix.arrow_left_right_line,
            value: themeState.crossAxisSpacing,
            min: 0,
            max: 24,
            displayValue: themeState.crossAxisSpacing.toStringAsFixed(0),
            onChanged: (v) => theme.updateSettings(themeState.copyWith(crossAxisSpacing: v)),
          ),
          TvSettingsSliderTile(
            title: i18n('ui_vertical_card_spacing'),
            icon: Remix.arrow_up_down_line,
            value: themeState.mainAxisSpacing,
            min: 0,
            max: 24,
            displayValue: themeState.mainAxisSpacing.toStringAsFixed(0),
            onChanged: (v) => theme.updateSettings(themeState.copyWith(mainAxisSpacing: v)),
          ),
          // Sub-pages the desktop theme page hosts, in its order: paging, then
          // the font family, then the per-component font sizes.
          TvSettingsNavTile(
            title: i18n('page_settings'),
            subtitle: i18n('page_settings_subtitle'),
            icon: Remix.pages_line,
            onTap: () => context.push(AppRoutes.kSettingsPage),
          ),
          TvSettingsNavTile(
            title: i18n('font_family'),
            subtitle: i18n('change_font_family'),
            icon: Remix.font_color,
            onTap: () => context.push(AppRoutes.kSettingsFontFamily),
          ),
          TvSettingsNavTile(
            title: i18n('ui_font_settings'),
            subtitle: i18n('font_settings_desc'),
            icon: Remix.font_size,
            onTap: () => context.push(AppRoutes.kSettingsFont),
          ),
        ],
      ),
    );
  }

  /// Loading animation labels follow the active language, falling back to the
  /// English name when a translation is missing.
  static String _loadingStyleName(Map<String, String> style) {
    final localized = style['nameZh'] ?? '';
    final english = style['nameEn'] ?? '';
    if (localized.isEmpty) return english;
    return i18nExists(localized) ? i18n(localized) : (english.isNotEmpty ? english : localized);
  }

  /// Named accents offered for the loading animation; index 0 keeps the
  /// animation on the colour of the active theme.
  static final List<String> colorNames = PlayerConsts.themeColors.keys.toList(growable: false);
  static final List<Color> _loadingColors = PlayerConsts.themeColors.values.toList(growable: false);

  static int _loadingColorIndex(Color? current) {
    if (current == null) return 0;
    final index = _loadingColors.indexWhere((color) => color.toARGB32() == current.toARGB32());
    return index < 0 ? 0 : index + 1;
  }
}
