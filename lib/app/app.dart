import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:go_transitions/go_transitions.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/widgets/tv_scaffold.dart';
import 'package:pure_live/app/consts/app_theme_consts.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:pure_live/features/remote/global_room_push.dart';
import 'package:pure_live/shared/widgets/tv_locale_rebuilder.dart';
import 'package:pure_live/services/font_settings/font_settings_model.dart';
import 'package:pure_live/services/font_settings/font_settings_controller.dart';
import 'package:pure_live/services/background_config/background_controller.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';

class App extends ConsumerWidget {
  const App({super.key});
  static const double _minTextScale = 0.7;
  static const double _maxTextScale = 2.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    // Keep background & remote sync alive for the whole session
    ref.watch(backgroundControllerProvider);

    final currentTvTheme = ref.watch(tvThemeControllerProvider);
    final themeSettings = ref.watch(themeSettingsControllerProvider);
    final selectedMode = ref.read(themeSettingsControllerProvider.notifier).themeMode;
    // TV reports no night mode, so "follow system" → dark
    final themeMode = selectedMode == ThemeMode.system ? ThemeMode.dark : selectedMode;
    final paletteBrightness = themeMode == ThemeMode.light ? Brightness.light : Brightness.dark;

    final appLocale = AppThemeConsts.languages[themeSettings.languageName] ?? const Locale('zh');

    // Text scale from font settings, clamped. The panel correction is applied
    // per subtree (see TvTextScale): the same font scale must mean the same
    // text size on a 720p TV and a 1080p one.
    final fontSettings = ref.watch(fontSettingsControllerProvider).value;
    final textScale = (fontSettings?.textScaleFactor ?? 1.0).clamp(_minTextScale, _maxTextScale);
    final fontFamily = _fontFamilyOf(fontSettings);
    // AppTextStyles carry the family statically: the widgets that install one
    // of its styles as a DefaultTextStyle (TvButton, TvTabBar) replace the
    // inherited style and would otherwise lose the applied font.
    AppTextStyles.fontFamily = fontFamily;

    final resolvedTvTheme = currentTvTheme.resolveFor(brightness: paletteBrightness);

    return ScreenUtilPlusInit(
      designSize: TvTextScale.designSize,
      autoRebuild: false,
      child: LocalizationsLocaleSync(
        locale: appLocale,
        child: MaterialApp.router(
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          builder: (context, child) {
            // `longSelectDuration` is the d-pad layer's hold threshold for
            // `onLongSelect`: a press held at least this long is a long press (its
            // menu runs while the key is still down) and the release is dropped
            // instead of being reported as a select. Keep it at the d-pad default —
            // shortening it was tried and made ordinary presses (~300 ms) open the
            // menu instead of the room, while a hold that *is* meant to reach the
            // menu is comfortably past half a second on a remote.
            //
            // The cards additionally guard the release with `DpadLongPressGate`:
            // a disturbed press can still report its release as a select, which
            // used to open the room on the tail of a long press.
            //
            // `scrollDuration: Duration.zero` keeps the d-pad layer from animating
            // the reveal itself; the grids drive their own scrolling.
            final withDpad = Dpad.wrap(
              theme: const DpadThemeData(
                scrollDuration: Duration.zero,
                longSelectDuration: Duration(milliseconds: 500),
              ),
            )(context, child!);

            return FlutterSmartDialog.init()(
              context,
              MediaQuery(
                // The panel correction rides along with the user's font scale, so
                // a 720p TV keeps a 1080p TV's font sizes instead of shrinking
                // every label by a third. See TvTextScale.
                data: MediaQuery.of(context).copyWith(textScaler: TvTextScale.scalerFor(context, userScale: textScale)),
                child: TvPaletteDefaults(
                  theme: resolvedTvTheme,
                  child: TvLocaleRebuilder(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [const TvAppBackground(), withDpad, const GlobalRoomPushOverlay()],
                    ),
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
            pageTransitions: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: GoTransitions.fadeUpwards,
                TargetPlatform.iOS: GoTransitions.cupertino,
                TargetPlatform.macOS: GoTransitions.cupertino,
              },
            ),
            colorScheme: _schemeFor(resolvedTvTheme, Brightness.light),
          ),
          darkTheme: buildTvThemeData(
            palette: resolvedTvTheme,
            brightness: Brightness.dark,
            fontFamily: fontFamily,
            baseTextTheme: _textThemeFor(fontSettings, ThemeData(brightness: Brightness.dark).textTheme),
            pageTransitions: const PageTransitionsTheme(
              builders: {
                TargetPlatform.android: GoTransitions.fadeUpwards,
                TargetPlatform.iOS: GoTransitions.cupertino,
                TargetPlatform.macOS: GoTransitions.cupertino,
              },
            ),
            colorScheme: _schemeFor(resolvedTvTheme, Brightness.dark),
          ),
          themeMode: themeMode,
        ),
      ),
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

ColorScheme _schemeFor(TvThemeData tvTheme, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return ColorScheme.fromSeed(
    seedColor: tvTheme.focusColor,
    brightness: brightness,
    primary: tvTheme.focusColor,
    surface: dark ? tvTheme.backgroundColor : null,
  );
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
