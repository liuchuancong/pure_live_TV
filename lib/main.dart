import 'package:pure_live/app/app.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/app/bootstrap/initialized.dart';
import 'package:pure_live/services/settings/settings.dart';

void main() async {
  final initializer = AppInitializer();
  await initializer.initialize();

  runApp(
    EasyLocalization(
      supportedLocales: AppConsts.languages.values.toList(growable: false),
      path: 'assets/translations',
      fallbackLocale: const Locale('zh'),
      // The language preference lives in Hive and is only readable once storage
      // is ready, so the saved language is applied up front to avoid a switch.
      startLocale: Locale(SettingsService.to.theme.locale.languageCode),
      useOnlyLangCode: true,
      child: UncontrolledProviderScope(container: initializer.container, child: App()),
    ),
  );
}
