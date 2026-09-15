import 'package:dynamic_color/dynamic_color.dart';
import 'package:dpad/dpad.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final currentTvTheme = ref.watch(tvThemeControllerProvider);
    final themeSettings = ref.watch(themeSettingsControllerProvider);
    final appLocale = AppConsts.languages[themeSettings.languageName] ?? const Locale('zh');

    // The operating system palette is used only when the user asked for it and
    // the platform actually provides one; the TV palette keeps supplying the
    // background and the focus colours in either case.
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) => ScreenUtilPlusInit(
        designSize: Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: LocalizationsLocaleSync(
          locale: appLocale,
          child: MaterialApp.router(
            routerConfig: router,
            debugShowCheckedModeBanner: false,
            // Installs the D-pad root: direction-key navigation, per-region focus
            // memory and focus-loss recovery all come from it. Without this layer a TV
            // remote cannot move focus at all.
            builder: Dpad.wrap(),
            // EasyLocalization supplies the locale and the delegate list; the app's own
            // language setting is pushed into the render layer by LocalizationsLocaleSync.
            locale: context.locale,
            supportedLocales: context.supportedLocales,
            localizationsDelegates: context.localizationDelegates,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: currentTvTheme.backgroundColor,
              colorScheme: _schemeFor(
                currentTvTheme,
                themeSettings.enableDynamicTheme ? darkDynamic ?? lightDynamic : null,
              ),
              extensions: [TvThemeExtension(theme: currentTvTheme)],
            ),
          ),
        ),
      ),
    );
  }
}

/// Material color scheme for the active TV palette.
///
/// A system palette replaces the seeded accent roles but keeps the TV
/// background, so an enabled dynamic theme changes the accents without
/// flattening the curated TV appearance.
ColorScheme _schemeFor(TvThemeData tvTheme, material.ColorScheme? systemScheme) {
  if (systemScheme == null) {
    return ColorScheme.fromSeed(
      seedColor: tvTheme.focusColor,
      brightness: Brightness.dark,
      primary: tvTheme.focusColor,
      surface: tvTheme.backgroundColor,
    );
  }
  return toFlutterColorScheme(systemScheme).copyWith(surface: tvTheme.backgroundColor);
}

/// Bridges the app's own language setting to the EasyLocalization layer.
///
/// Rewriting `languageName` in settings does not move MaterialApp by itself,
/// so setLocale is called here to retarget already-rendered widgets.
class LocalizationsLocaleSync extends StatefulWidget {
  const LocalizationsLocaleSync({super.key, required this.locale, required this.child});

  final Locale locale;
  final Widget child;

  @override
  State<LocalizationsLocaleSync> createState() => _LocalizationsLocaleSyncState();
}

class _LocalizationsLocaleSyncState extends State<LocalizationsLocaleSync> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLocale();
  }

  @override
  void didUpdateWidget(LocalizationsLocaleSync oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.locale != oldWidget.locale) _syncLocale();
  }

  void _syncLocale() {
    if (context.locale.languageCode == widget.locale.languageCode) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (context.locale.languageCode == widget.locale.languageCode) return;
      context.setLocale(widget.locale);
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
