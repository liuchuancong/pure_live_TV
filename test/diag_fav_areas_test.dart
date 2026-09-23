import 'dart:io';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/features/home/home_page.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';

class _FavAreasIndex extends SideMenuIndex {
  @override
  int build() => TvMenuType.favoriteAreas.value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_diag');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    SettingsService.to.init(ProviderContainer());
  });

  testWidgets('home page opens the followed-areas page', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: false,
        splitScreenMode: false,
        child: ProviderScope(
          overrides: [sideMenuIndexProvider.overrideWith(_FavAreasIndex.new)],
          child: MaterialApp(
            builder: Dpad.wrap(),
            theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
            home: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 1500));

    final Object? ex = tester.takeException();
    // ignore: avoid_print
    print('EXCEPTION: $ex');
    // ignore: avoid_print
    print('TEXTS: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).toList()}');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
