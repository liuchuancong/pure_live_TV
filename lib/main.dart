import 'package:dpad/dpad.dart';
import 'package:pure_live/initialized.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/consts/app_consts.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pure_live/theme/tv_theme_controller.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:pure_live/routes/getx_router_observer.dart';

void main(List<String> args) async {
  await AppInitializer().initialize();
  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('zh')],
      path: 'assets/translations',
      fallbackLocale: const Locale('zh'),
      assetLoader: const RootBundleAssetLoader(),
      child: MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    initGlopalPlayer();
  }

  @override
  void dispose() {
    GlobalPlayerService.instance.dispose();
    super.dispose();
  }

  Future<void> initGlopalPlayer() async {
    final String savedKey = SettingsService.to.player.videoPlayerKey.v;
    final String validKey = PlayerConsts.engines.containsKey(savedKey) ? savedKey : PlayerConsts.defaultKey;
    GlobalPlayerService.instance.initialize(defaultEngine: PlayerConsts.engines[validKey]!);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(1920, 1080),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        final settings = Get.find<SettingsService>();

        return Obx(() {
          final tvTheme = TvThemeController.to.currentTheme;
          final currentThemeData = AppColors().getThemeData(tvTheme);

          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: '纯粹直播',
            themeMode: AppConsts.themeModes[settings.theme.themeModeName.value]!,
            theme: currentThemeData,
            darkTheme: currentThemeData,
            builder: Dpad.wrap(
              theme: DpadThemeData(
                scrollPadding: 64,
                effects: [
                  DpadScaleEffect(scale: 1.05),
                  DpadGlowEffect(color: tvTheme.focusColor.withOpacity(0.4)),
                ],
              ),
            ),
            locale: AppConsts.languages["简体中文"],
            supportedLocales: S.delegate.supportedLocales,
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: settings.startup.isFirstInApp.value ? RoutePath.kAgreementPage : RoutePath.kInitial,
            defaultTransition: Transition.native,
            getPages: AppPages.routes,
            navigatorObservers: [GetXRouterObserver(), BackButtonObserver()],
          );
        });
      },
    );
  }
}
