import 'package:flutter/material.dart';
import 'package:pure_live/routes/app_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/theme/tv_theme_extension.dart';
import 'package:pure_live/theme/tv_theme_controller.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final currentTvTheme = ref.watch(tvThemeControllerProvider);

    return ScreenUtilPlusInit(
      designSize: Size(1920, 1080),
      autoRebuild: false,
      minTextAdapt: true,
      splitScreenMode: false,
      child: MaterialApp.router(
        routerConfig: router,
        debugShowCheckedModeBanner: false,
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
    );
  }
}
