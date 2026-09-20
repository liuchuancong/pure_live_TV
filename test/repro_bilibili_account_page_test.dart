import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dpad/dpad.dart';
import 'package:pure_live/features/settings/pages/account_bilibili_page.dart';
import 'package:pure_live/services/cookie_manager/cookie_controller.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/theme/tv_theme_extension.dart';
import 'package:pure_live/shared/theme/themes/cyber_theme.dart';

void main() {
  testWidgets('account bilibili page builds and polls without framework assertions', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // Real file I/O cannot complete inside the FakeAsync zone; runAsync lifts
    // this one setup step onto the real event loop.
    Hive.init(Directory.systemTemp.createTempSync('hive').path);
    await tester.runAsync(HivePrefUtil.init);

    debugPrint('REPRO: hive ok');
    final container = ProviderContainer();
    SettingsService.to.init(container);
    addTearDown(container.dispose);

    debugPrint('REPRO: before pumpWidget');
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ScreenUtilPlusInit(
          designSize: const Size(1920, 1080),
          autoRebuild: false,
          minTextAdapt: true,
          splitScreenMode: false,
          child: MaterialApp(
            builder: Dpad.wrap(),
            theme: ThemeData(
              useMaterial3: true,
              extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: cyberTvTheme)],
            ),
            home: const AccountBilibiliPage(),
          ),
        ),
      ),
    );

    // Opening frame + the QR service's post-frame load. The QR login service
    // fires a real network request that never settles under FakeAsync; the
    // page must still build and lay out cleanly around it.
    debugPrint('REPRO: pumpWidget done');
    await tester.pump(const Duration(seconds: 1));

    // Simulate a confirmed QR login: the cookie provider notifies while the
    // page, the embedded QR view's onLogined and the listen in the cookie page
    // all react in the same frame.
    debugPrint('REPRO: login');
    await tester.runAsync(() async {
      container.read(cookieControllerProvider.notifier).setBilibiliCookie('SESSDATA=fake');
    });
    for (int i = 0; i < 8; i++) {
      await tester.pump(const Duration(seconds: 1));
      debugPrint('REPRO: pumped $i');
    }

    expect(tester.takeException(), isNull);
  });
}
