import 'package:pure_live/app/consts/app_consts.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/app/router/app/app_router.dart';
import 'package:pure_live/app/consts/app_theme_consts.dart';
import 'package:pure_live/services/font_settings/font_settings_model.dart';
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
    final fontSettings = ref.watch(fontSettingsControllerProvider).value ?? const FontSettingsModel();
    final font = ref.read(fontSettingsControllerProvider.notifier);
    final double fontTextScale = fontSettings.textScaleFactor;
    // The mobile row shows which family is active, so the row is not just a
    // blind entry point into the font manager.
    final String currentFontName = () {
      // A locked weight stores a derived family id (`X::700`); display the base.
      final String id = fontSettings.fontFamilyName;
      if (id == 'Default' || id.isEmpty) return i18n('font_default');
      return FontDownloadManager.baseFamilyId(id);
    }();

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
              SizedBox(height: 8.ts(context)),
              TvSettingsMenuTile<void>(
                title: i18n('ui_background_settings'),
                subtitle: i18n('background_entry_subtitle'),
                icon: Remix.image_line,
                onTap: () async => const WallpaperPageRoute().push(context),
              ),
            ],
          ),
          SizedBox(height: 20.ts(context)),
          TvSettingsGroupTitle(title: i18n('grid_spacing_settings')),
          TvSettingsCard(
            children: [
              TvSettingsNavTile(
                title: i18n('grid_spacing_settings'),
                subtitle: i18n('grid_spacing_entry_subtitle'),
                icon: Remix.grid_line,
                onTap: () => const GridSpacingRoute().push(context),
              ),
            ],
          ),
          SizedBox(height: 20.ts(context)),
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
          SizedBox(height: 20.ts(context)),
          TvSettingsGroupTitle(title: i18n('localization_settings')),
          TvSettingsCard(
            children: [
              TvSettingsOptionTile(
                title: i18n('change_language'),
                subtitle: i18n('change_language_subtitle'),
                icon: Remix.global_line,
                options: AppThemeConsts.languages.keys.toList(growable: false),
                index: _languageIndex(themeState.languageName),
                onChanged: (i) async {
                  final languageName = AppThemeConsts.languages.keys.elementAt(i);
                  await theme.changeLanguageWithRetry(context, languageName: languageName);
                },
              ),
            ],
          ),
          SizedBox(height: 20.ts(context)),
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
          SizedBox(height: 20.ts(context)),
          // The one global scale lives here, not on a sub-page: the per-level
          // fine-tuning (body/title sizes) is gone — a single multiplier keeps
          // every tier's contrast intact, which is what the fine-tuning broke.
          TvSettingsGroupTitle(title: i18n('text_size_settings')),
          TvSettingsCard(
            children: [
              TvSettingsSliderTile(
                title: i18n('ui_global_text_scale'),
                icon: Icons.format_size_rounded,
                value: fontTextScale,
                min: 0.8,
                // The user scale stacks on the panel's legibility correction
                // (1.5x on a 720p TV), so 1.6 here painted at 2.4x and broke
                // every layout that followed the font. 1.3 keeps the worst
                // case at 1.95x — past what the panel lift already gives,
                // short of the zone where grids collapse and dialogs scroll.
                max: 1.3,
                step: 0.05,
                displayValue: '${(fontTextScale * 100).toStringAsFixed(0)}%',
                onChanged: (v) => font.updateSettings(fontSettings.copyWith(textScaleFactor: v)),
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

  /// Index of the persisted language inside [AppThemeConsts.languages].
  static int _languageIndex(String languageName) {
    final index = AppThemeConsts.languages.keys.toList(growable: false).indexOf(languageName);
    return index < 0 ? 1 : index;
  }
}
