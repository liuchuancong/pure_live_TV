import 'dart:io';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/features/home/home_provider.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:pure_live/shared/widgets/tv_icon_button.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_diag_router');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    SettingsService.to.init(ProviderContainer());
  });

  testWidgets('returning from a sidebar page keeps the highlight', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    late GoRouter router;
    router = GoRouter(
      observers: <NavigatorObserver>[tvRouteObserver],
      initialLocation: '/home',
      routes: $appRoutes,
    );

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: false,
        splitScreenMode: false,
        child: ProviderScope(
          child: MaterialApp.router(
            routerConfig: router,
            builder: Dpad.wrap(),
            theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 1600));

    // ignore: avoid_print
    print('HOME TEXTS: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).where((t) => t != null).toList()}');
    // ignore: avoid_print
    print('SETTINGS CAPTION = ${i18n('menu_short_settings')}');

    void report(String tag) {
      final FocusNode? f = FocusManager.instance.primaryFocus;
      final BuildContext? ctx = f?.context;
      final RenderObject? ro = ctx?.findRenderObject();
      final Rect? rect = ro is RenderBox && ro.attached && ro.hasSize
          ? ro.localToGlobal(Offset.zero) & ro.size
          : null;
      // ignore: avoid_print
      print('[$tag] node=${f?.hashCode} scope=${f is FocusScopeNode} rect=$rect');
    }

    report('home');

    // Open 设置 exactly like the sidebar tile does.
    final Finder settingsTile = find.text(i18n('menu_short_settings'));
    expect(settingsTile, findsOneWidget);
    final BuildContext tileContext = tester.element(settingsTile);
    SettingsMenuRoute().push(tileContext);
    await tester.pumpAndSettle();
    report('settings open');
    // ignore: avoid_print
    print('SETTINGS TEXTS: ${tester.widgetList<Text>(find.byType(Text)).take(12).map((t) => t.data).where((t) => t != null).toList()}');

    router.pop();
    await tester.pumpAndSettle();
    report('settings closed');
    // ignore: avoid_print
    print('EXCEPTION: ${tester.takeException()}');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
