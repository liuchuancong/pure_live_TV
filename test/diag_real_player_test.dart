import 'dart:io';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_ce/hive.dart';
import 'package:pure_live/app/router/app_router.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_diag_room');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    await HivePrefUtil.setObjectList(
      'favoriteRooms',
      <LiveRoom>[
        const LiveRoom(
          roomId: '12345',
          platform: 'bilibili',
          title: 'test room',
          nick: 'someone',
          status: true,
          liveStatus: LiveStatus.live,
        ),
      ],
      (room) => room.toJson(),
    );
    SettingsService.to.init(ProviderContainer());
  });

  testWidgets('returning from the player keeps the highlight on the card', (tester) async {
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

    // ignore: avoid_print
    print('TEXTS: ${tester.widgetList<Text>(find.byType(Text)).map((t) => t.data).where((t) => t != null).toList()}');
    report('home');

    // Move from the sidebar into the grid, then open the card.
    for (int i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump(const Duration(milliseconds: 120));
      report('right $i');
    }
    final FocusNode? cardNode = FocusManager.instance.primaryFocus;
    // ignore: avoid_print
    print('CARD before select: node=${cardNode?.hashCode} mounted=${cardNode?.context?.mounted}');
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump(const Duration(milliseconds: 200));
    // ignore: avoid_print
    print('CARD after select: node=${cardNode?.hashCode} parent=${cardNode?.parent != null} '
        'mounted=${cardNode?.context?.mounted} canRequest=${cardNode?.canRequestFocus}');
    await tester.pump(const Duration(milliseconds: 800));
    report('player open');
    // ignore: avoid_print
    print('CARD in player: node=${cardNode?.hashCode} parent=${cardNode?.parent != null} '
        'mounted=${cardNode?.context?.mounted} canRequest=${cardNode?.canRequestFocus}');
    // ignore: avoid_print
    print('PLAYER TEXTS: ${tester.widgetList<Text>(find.byType(Text)).take(10).map((t) => t.data).where((t) => t != null).toList()}');

    void traceFocus() {
      // ignore: avoid_print
      print('FOCUS -> ${FocusManager.instance.primaryFocus?.hashCode}\n${StackTrace.current}');
    }

    FocusManager.instance.addListener(traceFocus);
    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pump(const Duration(milliseconds: 600));
    FocusManager.instance.removeListener(traceFocus);
    report('player closed');
    // ignore: avoid_print
    print('CARD after pop: node=${cardNode?.hashCode} parent=${cardNode?.parent != null} '
        'mounted=${cardNode?.context?.mounted} canRequest=${cardNode?.canRequestFocus}');
    // ignore: avoid_print
    print('EXCEPTION: ${tester.takeException()}');

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
