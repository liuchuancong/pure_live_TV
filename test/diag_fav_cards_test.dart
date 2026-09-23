import 'dart:io';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/features/home/home_page.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/models/live_area/live_area.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';

class _FavAreasIndex extends SideMenuIndex {
  @override
  int build() => TvMenuType.favoriteAreas.value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_diag3');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    await HivePrefUtil.setObjectList(
      'favoriteAreas',
      <LiveArea>[
        const LiveArea(platform: 'bilibili', areaType: '0', typeName: '网游', areaId: '1', areaName: '英雄联盟'),
        const LiveArea(platform: 'bilibili', areaType: '0', typeName: '网游', areaId: '2', areaName: '绝地求生'),
      ],
      (area) => area.toJson(),
    );
    SettingsService.to.init(ProviderContainer());
  });

  testWidgets('followed areas page renders and reacts to OK', (tester) async {
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
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1500));

    // ignore: avoid_print
    print('TEXTS: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).where((t) => t != null).toList()}');

    void report(String tag) {
      final FocusNode? f = FocusManager.instance.primaryFocus;
      final BuildContext? ctx = f?.context;
      final RenderObject? ro = ctx?.findRenderObject();
      final Rect? rect = ro is RenderBox && ro.attached && ro.hasSize
          ? ro.localToGlobal(Offset.zero) & ro.size
          : null;
      // ignore: avoid_print
      print('[$tag] node=${f?.hashCode} rect=$rect');
    }

    report('after open');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump(const Duration(milliseconds: 200));
    report('right');
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 600));
    report('select');
    // ignore: avoid_print
    print('AFTER SELECT TEXTS: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).where((t) => t != null).toList()}');
    // ignore: avoid_print
    print('EXCEPTION: ${tester.takeException()}');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
