import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/services/font_settings/font_settings_controller.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class ThemeSettingsSectionPage extends ConsumerWidget {
  const ThemeSettingsSectionPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(tvThemeControllerProvider);
    final themeState = ref.watch(themeSettingsControllerProvider);
    final theme = ref.read(themeSettingsControllerProvider.notifier);
    final loadingStyles = AppConsts.allStyles;
    final tvTheme = context.tvTheme;
    final Color loadingColor = themeState.loadingStyleColor ?? tvTheme.focusColor;
    // The mobile row shows which family is active, so the row is not just a
    // blind entry point into the font manager.
    final String currentFontName =
        ref.watch(fontSettingsControllerProvider).value?.fontFamilyName ?? i18n('font_default');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TvSettingsGroupTitle(title: i18n('theme_customization')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(
                title: i18n('ui_theme'),
                subtitle: currentTheme.name,
                icon: Remix.palette_line,
                onTap: () => const ThemePickerRoute().push(context),
              ),
              // Desktop order: dynamic colour belongs with the theme rows, above
              // the loading animation.
              TvSettingsSwitchTile(
                title: i18n('enable_dynamic_color'),
                subtitle: i18n('enable_dynamic_color_subtitle'),
                icon: Remix.magic_line,
                value: themeState.enableDynamicTheme,
                onChanged: (v) => theme.updateSettings(themeState.copyWith(enableDynamicTheme: v)),
              ),
              // The animation row shows the animation itself, exactly as the mobile
              // page does: a name alone does not tell the user what they picked.
              TvSettingsRow(
                title: i18n('change_loading_style'),
                subtitle: i18n('change_loading_style_subtitle'),
                leading: TvLoadingStylePreview(
                  style: themeState.loadingStyle,
                  color: loadingColor,
                  size: 30.w,
                  theme: tvTheme,
                ),
                trailingBuilder: (context, focused) => tvSettingsValueLabel(
                  context,
                  focused,
                  _currentLoadingStyleName(loadingStyles, themeState.loadingStyle),
                ),
                onSelect: () => const SettingsLoadingStyleRoute().push(context),
              ),
              SizedBox(height: 8.sp),
              TvSettingsMenuTile<void>(
                title: i18n('ui_background_settings'),
                subtitle: i18n('background_entry_subtitle'),
                icon: Remix.image_line,
                onTap: () async => const WallpaperPageRoute().push(context),
              ),
            ],
          ),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('grid_spacing_settings')),
          TvSettingsCard(
            children: [
              TvSettingsSliderTile(
                title: i18n('cross_axis_spacing'),
                icon: Remix.arrow_left_right_line,
                value: themeState.crossAxisSpacing,
                min: 0,
                max: 24,
                displayValue: themeState.crossAxisSpacing.toStringAsFixed(0),
                onChanged: (v) => theme.updateSettings(themeState.copyWith(crossAxisSpacing: v)),
              ),
              TvSettingsSliderTile(
                title: i18n('main_axis_spacing'),
                icon: Remix.arrow_up_down_line,
                value: themeState.mainAxisSpacing,
                min: 0,
                max: 24,
                displayValue: themeState.mainAxisSpacing.toStringAsFixed(0),
                onChanged: (v) => theme.updateSettings(themeState.copyWith(mainAxisSpacing: v)),
              ),
            ],
          ),
          SizedBox(height: 20.sp),
          // Sub-pages the desktop theme page hosts, in its order: paging, the
          // language, the font family, then the per-component font sizes.
          TvSettingsGroupTitle(title: i18n('page_settings')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(
                title: i18n('page_settings'),
                subtitle: i18n('page_settings_subtitle'),
                icon: Remix.pages_line,
                onTap: () => const PageSettingsRoute().push(context),
              ),
            ],
          ),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('localization_settings')),
          TvSettingsCard(
            children: [
              TvSettingsOptionTile(
                title: i18n('change_language'),
                subtitle: i18n('change_language_subtitle'),
                icon: Remix.global_line,
                options: AppConsts.languages.keys.toList(growable: false),
                index: _languageIndex(themeState.languageName),
                onChanged: (i) async {
                  final languageName = AppConsts.languages.keys.elementAt(i);
                  await theme.changeLanguageWithRetry(context, languageName: languageName);
                },
              ),
            ],
          ),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('font_family_settings')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(
                title: i18n('change_font_family'),
                subtitle: '${i18n('current_font_prefix')}: $currentFontName',
                icon: Remix.font_color,
                onTap: () => const FontFamilyRoute().push(context),
              ),
            ],
          ),
          SizedBox(height: 20.sp),
          TvSettingsGroupTitle(title: i18n('text_size_settings')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(
                title: i18n('font_settings_title'),
                subtitle: i18n('font_settings_desc'),
                icon: Remix.font_size,
                onTap: () => const FontSettingsRoute().push(context),
              ),
            ],
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

  /// Name of the active animation, as the mobile page shows it.
  static String _currentLoadingStyleName(List<Map<String, String>> styles, String key) {
    for (final style in styles) {
      if (style['key'] == key) return _loadingStyleName(style);
    }
    return key;
  }

  /// Index of the persisted language inside [AppConsts.languages].
  static int _languageIndex(String languageName) {
    final index = AppConsts.languages.keys.toList(growable: false).indexOf(languageName);
    return index < 0 ? 1 : index;
  }
}
