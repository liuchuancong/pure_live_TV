import 'package:dpad/dpad.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:pure_live/shared/widgets/tv_scaffold.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pure_live/shared/widgets/tv_locale_rebuilder.dart';
import 'package:pure_live/services/remote_sync/remote_sync_service.dart';
import 'package:pure_live/services/font_settings/font_settings_model.dart';
import 'package:pure_live/services/font_settings/font_settings_controller.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class App extends ConsumerWidget {
  const App({super.key});
  static const double _minTextScale = 0.7;
  static const double _maxTextScale = 2.0;

  /// Fade-through transition, no opaque base color — pages are transparent over the shared background.
  static final PageTransitionsTheme _kPageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      for (final p in TargetPlatform.values) p: const _FadePageTransitionsBuilder(),
    },
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Keep background & remote sync alive for the whole session
    ref.watch(backgroundControllerProvider);
    ref.watch(remoteSyncControllerProvider);

    final currentTvTheme = ref.watch(tvThemeControllerProvider);
    final themeSettings = ref.watch(themeSettingsControllerProvider);
    final selectedMode = ref.read(themeSettingsControllerProvider.notifier).themeMode;
    // TV reports no night mode, so "跟随系统" → dark
    final themeMode = selectedMode == ThemeMode.system ? ThemeMode.dark : selectedMode;
    final paletteBrightness = themeMode == ThemeMode.light ? Brightness.light : Brightness.dark;

    final appLocale = AppConsts.languages[themeSettings.languageName] ?? const Locale('zh');

    // Text scale from font settings, clamped
    final fontSettings = ref.watch(fontSettingsControllerProvider).value;
    final textScale = (fontSettings?.textScaleFactor ?? 1.0).clamp(_minTextScale, _maxTextScale);
    final fontFamily = _fontFamilyOf(fontSettings);

    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final systemScheme = themeSettings.enableDynamicTheme
            ? (paletteBrightness == Brightness.dark ? darkDynamic : lightDynamic)
            : null;
        final resolvedTvTheme = currentTvTheme.resolveFor(brightness: paletteBrightness, accent: systemScheme?.primary);

        return ScreenUtilPlusInit(
          designSize: const Size(1920, 1080),
          autoRebuild: false,
          child: LocalizationsLocaleSync(
            locale: appLocale,
            child: MaterialApp.router(
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              builder: (context, child) {
                final withDpad = Dpad.wrap(theme: const DpadThemeData(scrollDuration: Duration.zero))(context, child!);

                return FlutterSmartDialog.init()(
                  context,
                  MediaQuery(
                    data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
                    child: TvPaletteDefaults(
                      theme: resolvedTvTheme,
                      child: TvLocaleRebuilder(
                        child: Stack(fit: StackFit.expand, children: [const TvAppBackground(), withDpad]),
                      ),
                    ),
                  ),
                );
              },
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              theme: buildTvThemeData(
                palette: resolvedTvTheme,
                brightness: Brightness.light,
                fontFamily: fontFamily,
                baseTextTheme: _textThemeFor(fontSettings, ThemeData(brightness: Brightness.light).textTheme),
                pageTransitions: _kPageTransitions,
                colorScheme: _schemeFor(resolvedTvTheme, systemScheme, Brightness.light),
              ),
              darkTheme: buildTvThemeData(
                palette: resolvedTvTheme,
                brightness: Brightness.dark,
                fontFamily: fontFamily,
                baseTextTheme: _textThemeFor(fontSettings, ThemeData(brightness: Brightness.dark).textTheme),
                pageTransitions: _kPageTransitions,
                colorScheme: _schemeFor(resolvedTvTheme, systemScheme, Brightness.dark),
              ),
              themeMode: themeMode,
            ),
          ),
        );
      },
    );
  }
}

/// Fade-through: outgoing page fades out in first 35%, incoming fills last 65%.
class _FadePageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadePageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final fadeIn = CurveTween(curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic));
    final fadeOut = CurveTween(
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    ).chain(Tween<double>(begin: 1.0, end: 0.0));
    return FadeTransition(
      opacity: animation.drive(fadeIn),
      child: FadeTransition(opacity: secondaryAnimation.drive(fadeOut), child: child),
    );
  }
}

String? _fontFamilyOf(FontSettingsModel? font) {
  final name = font?.fontFamilyName ?? '';
  if (name.isEmpty || name == 'Default') return null;
  return name;
}

TextTheme _textThemeFor(FontSettingsModel? font, TextTheme base) {
  if (font == null) return base;
  return base.copyWith(
    bodySmall: base.bodySmall?.copyWith(fontSize: font.fontSizeBodySmall),
    bodyMedium: base.bodyMedium?.copyWith(fontSize: font.fontSizeBodyMedium),
    bodyLarge: base.bodyLarge?.copyWith(fontSize: font.fontSizeBodyLarge),
    titleMedium: base.titleMedium?.copyWith(fontSize: font.fontSizeTitleMedium),
    titleLarge: base.titleLarge?.copyWith(fontSize: font.fontSizeTitleLarge),
  );
}

ColorScheme _schemeFor(TvThemeData tvTheme, material.ColorScheme? systemScheme, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  if (systemScheme == null) {
    return ColorScheme.fromSeed(
      seedColor: tvTheme.focusColor,
      brightness: brightness,
      primary: tvTheme.focusColor,
      surface: dark ? tvTheme.backgroundColor : null,
    );
  }
  final converted = toFlutterColorScheme(systemScheme);
  return dark ? converted.copyWith(surface: tvTheme.backgroundColor) : converted;
}

/// Syncs app language setting → EasyLocalization locale.
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
  void didUpdateWidget(covariant LocalizationsLocaleSync oldWidget) {
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
