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
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final Directory dir = Directory.systemTemp.createTempSync('pure_live_diag2');
    Hive.init(dir.path);
    await HivePrefUtil.init();
    SettingsService.to.init(ProviderContainer());
  });

  testWidgets('focus after switching the side menu', (tester) async {
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
          child: MaterialApp(
            builder: Dpad.wrap(),
            home: const HomePage(),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 1500));

    void report(String tag) {
      final FocusNode? f = FocusManager.instance.primaryFocus;
      final BuildContext? ctx = f?.context;
      final RenderObject? ro = ctx?.findRenderObject();
      final Rect? rect = ro is RenderBox && ro.attached && ro.hasSize
          ? ro.localToGlobal(Offset.zero) & ro.size
          : null;
      final DpadFocusable? focusable = ctx?.findAncestorWidgetOfExactType<DpadFocusable>();
      // ignore: avoid_print
      print('[$tag] node=${f?.hashCode} scope=${f is FocusScopeNode} rect=$rect select=${focusable?.onSelect != null}');
    }

    report('opened');

    final container = ProviderScope.containerOf(tester.element(find.byType(HomePage)));
    for (final int index in <int>[0, 1, 2, 3]) {
      container.read(sideMenuIndexProvider.notifier).changeIndex(index);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      report('menu $index');
    }

    // Walk around with the remote to see whether the page reacts.
    for (int i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump(const Duration(milliseconds: 200));
      report('down $i');
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
