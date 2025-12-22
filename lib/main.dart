import 'package:get/get.dart';
import 'package:pure_live/initialized.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/common/consts/app_consts.dart';
import 'package:pure_live/routes/getx_router_observer.dart';
import 'package:pure_live/player/switchable_global_player.dart';

void main(List<String> args) async {
  // 初始化
  await AppInitializer().initialize();
  runApp(const MyApp());
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
    Future.delayed(const Duration(seconds: 1), () {
      initGlopalPlayer();
    });
  }

  Future<void> initGlopalPlayer() async {
    final settings = Get.find<SettingsService>();
    await SwitchableGlobalPlayer().init(PlayerEngine.values[settings.videoPlayerIndex.value]);
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
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: '纯粹直播',
            themeMode: AppConsts.themeModes[settings.themeModeName.value]!,
            theme: AppStyle.lightTheme,
            builder: FlutterSmartDialog.init(
              loadingBuilder: (msg) => Center(
                child: SizedBox(
                  width: 64.w,
                  height: 64.w,
                  child: CircularProgressIndicator(strokeWidth: 8.w, color: Colors.white),
                ),
              ),
              //字体大小不跟随系统变化
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(textScaler: const TextScaler.linear(1.0)),
                child: child!,
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
            initialRoute: settings.isFirstInApp.value ? RoutePath.kAgreementPage : RoutePath.kInitial,
            defaultTransition: Transition.native,
            getPages: AppPages.routes,
            navigatorObservers: [GetXRouterObserver(), BackButtonObserver()],
          );
        });
      },
    );
  }
}
