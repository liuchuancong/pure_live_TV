import 'package:dynamic_color/dynamic_color.dart';
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
            // EasyLocalization 提供语言与本地化代理；应用自有语言设置在
            // LocalizationsLocaleSync 中同步到渲染层。
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

/// 应用自有语言设置与 EasyLocalization 渲染层之间的同步桥。
///
/// 设置页改写 `languageName` 后，MaterialApp 的语言不会自己变化，
/// 这里用 setLocale 让已渲染的界面立即切换。
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
