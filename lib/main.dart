import 'package:pure_live/core/exports/package_export.dart';
import 'package:pure_live/app/app.dart';
import 'package:pure_live/core/consts/app_consts.dart';
import 'package:pure_live/global/initialized.dart';
import 'package:pure_live/services/settings/settings.dart';

void main() async {
  final initializer = AppInitializer();
  await initializer.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: AppConsts.languages.values.toList(growable: false),
      path: 'assets/translations',
      fallbackLocale: const Locale('zh'),
      // 语言偏好存在 Hive 里，初始化完成后才能读取：启动时直接使用已保存语言，
      // 避免先按设备语言渲染再跳变。
      startLocale: Locale(SettingsService.to.theme.locale.languageCode),
      useOnlyLangCode: true,
      child: UncontrolledProviderScope(container: initializer.container, child: const App()),
    ),
  );
}
