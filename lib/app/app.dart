import 'package:dpad/dpad.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:pure_live/shared/widgets/tv_scaffold.dart';
import 'package:pure_live/services/remote_sync/remote_sync_service.dart';
import 'package:pure_live/services/font_settings/font_settings_model.dart';
import 'package:pure_live/services/font_settings/font_settings_controller.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class App extends ConsumerWidget {
  const App({super.key});

  /// Bounds for 全局文字缩放, matching what the font page offers.
  static const double _minTextScale = 0.7;
  static const double _maxTextScale = 2.0;

  /// TV page transition: a plain cross-fade with no opaque fill.
  ///
  /// The Material defaults (ZoomPageTransitionsBuilder and friends) paint a
  /// `ColoredBox(colorScheme.surface)` behind the transitioning pages, which
  /// covers the single app background below the Navigator — that was the
  /// "black first, then the picture" flash on every push/pop. Pages here are
  /// transparent by design, so fading the page itself over the always-visible
  /// background needs no base colour at all.
  static final PageTransitionsTheme _kPageTransitions = PageTransitionsTheme(
    builders: <TargetPlatform, PageTransitionsBuilder>{
      for (final TargetPlatform platform in TargetPlatform.values) platform: const _FadePageTransitionsBuilder(),
    },
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    // Keep the background provider (and the video player it owns) alive for the
    // whole app.
    //
    // The background layer only *reads* it, so as an auto-dispose provider it was
    // torn down between reads: every rebuild created a new video player and
    // disposed the previous one, which disposed media_kit's video output while
    // the mounted background `Video` still pointed at it (logcat:
    // VideoOutputManager.create → dispose → Resize 0x0 → Surface.release() NPE).
    ref.watch(backgroundControllerProvider);
    // The LAN sync kit (bonsoir broadcast + discovery, HTTP on 39888): keep it
    // alive and started for the whole session so the phone can pair at any time.
    ref.watch(remoteSyncControllerProvider);
    final currentTvTheme = ref.watch(tvThemeControllerProvider);
    final themeSettings = ref.watch(themeSettingsControllerProvider);
    // A TV box reports no night mode (`UI_MODE_NIGHT_NO`), so "跟随系统" would
    // pick the light Material layer on every TV and paint light dialogs over the
    // dark palette. The app is dark-first: 跟随系统 means dark here, and 浅色
    // stays an explicit choice.
    final ThemeMode selectedMode = ref.read(themeSettingsControllerProvider.notifier).themeMode;
    final ThemeMode themeMode = selectedMode == ThemeMode.system ? ThemeMode.dark : selectedMode;
    // Resolve the TV palette for the mode and the dynamic accent. Both used to
    // live in the Material layer only — every custom widget reads the palette
    // below, so 动态取色 and 主题模式 looked like they did nothing. The accent
    // comes from DynamicColorBuilder, so the resolution itself runs in the
    // builder below.
    final Brightness paletteBrightness = themeMode == ThemeMode.light ? Brightness.light : Brightness.dark;
    final appLocale = AppConsts.languages[themeSettings.languageName] ?? const Locale('zh');

    // 界面字号调节. The app owns the text scale (the font page has a slider for
    // it), so ScreenUtil is told not to fold the system scale in as well —
    // otherwise one setting would be applied twice.
    final FontSettingsModel? fontSettings = ref.watch(fontSettingsControllerProvider).value;
    final double textScale = (fontSettings?.textScaleFactor ?? 1.0).clamp(_minTextScale, _maxTextScale);
    final String? fontFamily = _fontFamilyOf(fontSettings);

    // The operating system palette is used only when the user asked for it and
    // the platform actually provides one; the TV palette keeps supplying the
    // background and the focus colours in either case.
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        final material.ColorScheme? systemScheme = themeSettings.enableDynamicTheme
            ? (paletteBrightness == Brightness.dark ? darkDynamic : lightDynamic)
            : null;
        final TvThemeData resolvedTvTheme = currentTvTheme.resolveFor(
          brightness: paletteBrightness,
          accent: systemScheme?.primary,
        );
        return ScreenUtilPlusInit(
          designSize: Size(1920, 1080),
          autoRebuild: false,
          minTextAdapt: false,
          splitScreenMode: false,
          child: LocalizationsLocaleSync(
            locale: appLocale,
            child: MaterialApp.router(
              routerConfig: router,
              debugShowCheckedModeBanner: false,
              // Installs the D-pad root: direction-key navigation, per-region focus
              // memory and focus-loss recovery all come from it. Without this layer a TV
              // remote cannot move focus at all.
              builder: (context, child) {
                final Widget withDpad = Dpad.wrap(
                  // Snap scrolling: key repeats re-measure the item mid-animation,
                  // which aborts the scroll and clips the focused item at the edge.
                  // A zero duration jumps to the exact offset measured at rest.
                  theme: const DpadThemeData(scrollDuration: Duration.zero),
                )(context, child!);
                // The one place the user's text scale is applied.
                //
                // The app background lives here, below the Navigator, so it is
                // created once and every page simply stays transparent over it: a
                // background built per page was re-mounted on every push/pop and
                // flickered.
                // flutter_smart_dialog needs to hook the navigator's overlay to
                // show toasts; without this wrapper its context is never
                // initialized and the first showToast throws.
                return FlutterSmartDialog.init()(context, MediaQuery(
                  data: MediaQuery.of(context).copyWith(textScaler: TextScaler.linear(textScale)),
                  // Everything the widgets do not colour themselves follows the TV
                  // palette, in both 主题模式 settings (see [TvPaletteDefaults]).
                  child: TvPaletteDefaults(
                    theme: resolvedTvTheme,
                    child: Stack(fit: StackFit.expand, children: <Widget>[const TvAppBackground(), withDpad]),
                  ),
                ));
              },
              // EasyLocalization supplies the locale and the delegate list; the app's own
              // language setting is pushed into the render layer by LocalizationsLocaleSync.
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              localizationsDelegates: context.localizationDelegates,
              // 主题模式 was stored and never read. The Material layer follows it
              // now — dialogs, menus, text selection and the platform keyboard.
              // The page background and the accent keep coming from the TV
              // palette, which is what the presets are for: "浅色" therefore means
              // light Material surfaces over the palette's page, not a different
              // palette (that is the 主题外观 picker's job).
              //
              // Both themes keep the palette colour as the *scaffold* background
              // (pages that are not a TvScaffold stay opaque) but leave the route
              // canvas transparent, so the single app background below the
              // Navigator shows through instead of a Material default — that was
              // the white flash on every push and pop.
              theme: buildTvThemeData(
                palette: resolvedTvTheme,
                brightness: Brightness.light,
                fontFamily: fontFamily,
                baseTextTheme: _textThemeFor(fontSettings, ThemeData(brightness: Brightness.light).textTheme),
                pageTransitions: _kPageTransitions,
                colorScheme: _schemeFor(
                  resolvedTvTheme,
                  themeSettings.enableDynamicTheme ? lightDynamic : null,
                  Brightness.light,
                ),
              ),
              darkTheme: buildTvThemeData(
                palette: resolvedTvTheme,
                brightness: Brightness.dark,
                fontFamily: fontFamily,
                baseTextTheme: _textThemeFor(fontSettings, ThemeData(brightness: Brightness.dark).textTheme),
                pageTransitions: _kPageTransitions,
                colorScheme: _schemeFor(
                  resolvedTvTheme,
                  themeSettings.enableDynamicTheme ? darkDynamic ?? lightDynamic : null,
                  Brightness.dark,
                ),
              ),
              themeMode: themeMode,
            ),
          ),
        );
      },
    );
  }
}

/// The chosen font family, or null for the system default.
String? _fontFamilyOf(FontSettingsModel? font) {
  final String name = font?.fontFamilyName ?? '';
  if (name.isEmpty || name == 'Default') return null;
  return name;
}

/// The fade-only transition used for every platform; see [App._kPageTransitions].
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
    // Fade-through, not cross-fade. Every page is transparent over the shared
    // wallpaper, so blending an incoming page with the outgoing one — however
    // the alphas are balanced — puts both pages' content on screen at once,
    // which reads as a ghost of the previous page. Sequencing instead: the
    // outgoing page is gone within the first third, the incoming page fills
    // the last two thirds, and the brief wallpaper-only moment in between is
    // the constant backdrop, not a missing page.
    final Animatable<double> fadeIn = CurveTween(
      curve: const Interval(0.35, 1.0, curve: Curves.easeOutCubic),
    );
    final Animatable<double> fadeOut = CurveTween(
      curve: const Interval(0.0, 0.35, curve: Curves.easeIn),
    ).chain(Tween<double>(begin: 1.0, end: 0.0));
    return FadeTransition(
      opacity: animation.drive(fadeIn),
      child: FadeTransition(opacity: secondaryAnimation.drive(fadeOut), child: child),
    );
  }
}

/// 精细化字号微调: the five levels the font page edits, applied to the Material
/// text theme. The app's own text goes through `AppTextStyles` and follows the
/// global text scale instead.
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

/// Material color scheme for the active TV palette.
///
/// A system palette replaces the seeded accent roles but keeps the TV
/// background, so an enabled dynamic theme changes the accents without
/// flattening the curated TV appearance.
ColorScheme _schemeFor(TvThemeData tvTheme, material.ColorScheme? systemScheme, Brightness brightness) {
  final bool dark = brightness == Brightness.dark;
  if (systemScheme == null) {
    return ColorScheme.fromSeed(
      seedColor: tvTheme.focusColor,
      brightness: brightness,
      primary: tvTheme.focusColor,
      // Only the dark scheme adopts the palette background; a light Material
      // layer with a dark surface would leave dark text on a dark dialog.
      surface: dark ? tvTheme.backgroundColor : null,
    );
  }
  final ColorScheme converted = toFlutterColorScheme(systemScheme);
  return dark ? converted.copyWith(surface: tvTheme.backgroundColor) : converted;
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
