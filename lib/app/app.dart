import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/consts/app_consts.dart';
import 'package:pure_live/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/theme_settings/theme_settings_controller.dart';
import 'package:pure_live/theme/tv_theme_extension.dart';
import 'package:pure_live/theme/tv_theme_controller.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final currentTvTheme = ref.watch(tvThemeControllerProvider);
    final appLocale = AppConsts.languages[ref.watch(themeSettingsControllerProvider).languageName] ?? const Locale('zh');

    return ScreenUtilPlusInit(
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
            colorScheme: ColorScheme.fromSeed(
              seedColor: currentTvTheme.focusColor,
              brightness: Brightness.dark,
              primary: currentTvTheme.focusColor,
              surface: currentTvTheme.backgroundColor,
            ),
            extensions: [TvThemeExtension(theme: currentTvTheme)],
          ),
        ),
      ),
    );
  }
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
