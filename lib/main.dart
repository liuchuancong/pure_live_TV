import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/routes/getx_router_observer.dart';

void main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  PrefUtil.prefs = await SharedPreferences.getInstance();
  MediaKit.ensureInitialized();
  // 初始化服务
  initService();

  // 强制横屏
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
  // 全屏
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

  runApp(const MyApp());
}

void initService() {
  Get.put(SettingsService());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
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
              themeMode: SettingsService.themeModes[settings.themeModeName.value]!,
              theme: AppStyle.lightTheme,
              builder: FlutterSmartDialog.init(
                loadingBuilder: (msg) => Center(
                  child: SizedBox(
                    width: 64.w,
                    height: 64.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 8.w,
                      color: Colors.white,
                    ),
                  ),
                ),
                //字体大小不跟随系统变化
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: const TextScaler.linear(1.0),
                  ),
                  child: child!,
                ),
              ),
              locale: SettingsService.languages[settings.languageName.value]!,
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
              navigatorObservers: [GetXRouterObserver()],
            );
          });
        });
  }
}
