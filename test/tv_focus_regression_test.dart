import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/widgets/tv_tab_bar.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, Widget home) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(
          builder: Dpad.wrap(),
          home: Scaffold(body: home),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Rect rectOf(WidgetTester tester, Finder finder) => tester.getRect(finder);

  testWidgets('focusing the last tab scrolls it fully into view', (tester) async {
    final tabs = List.generate(20, (i) => TvTabItemData(title: 'Tab $i'));
    await pumpApp(
      tester,
      Center(
        child: SizedBox(
          width: 900,
          child: TvTabBar(tabs: tabs, currentIndex: 0, onTabChange: (i) {}),
        ),
      ),
    );

    // Walk focus to the last tab, the way a remote user would.
    for (int i = 0; i < 19; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }

    final Rect barRect = rectOf(tester, find.byType(TvTabBar));
    final Rect lastRect = rectOf(tester, find.text('Tab 19'));
    expect(
      lastRect.left >= barRect.left && lastRect.right <= barRect.right,
      true,
      reason:
          'focused last tab must be fully inside the bar viewport: '
          'bar=$barRect last=$lastRect',
    );
  });

  testWidgets('focusing the first tab from the right scrolls it fully into view', (tester) async {
    final tabs = List.generate(20, (i) => TvTabItemData(title: 'Tab $i'));
    await pumpApp(
      tester,
      Center(
        child: SizedBox(
          width: 900,
          child: TvTabBar(tabs: tabs, currentIndex: 0, onTabChange: (_) {}),
        ),
      ),
    );

    // Start somewhere in the middle, then walk left to the first tab.
    for (int i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();
    }
    for (int i = 0; i < 8; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pumpAndSettle();
    }

    final Rect barRect = rectOf(tester, find.byType(TvTabBar));
    final Rect firstRect = rectOf(tester, find.text('Tab 0'));
    expect(
      firstRect.left >= barRect.left && firstRect.right <= barRect.right,
      true,
      reason:
          'focused first tab must be fully inside the bar viewport: '
          'bar=$barRect first=$firstRect',
    );
  });

  testWidgets('focus is selectable after returning from a pushed route', (tester) async {
    bool rowSelected = false;
    await pumpApp(
      tester,
      Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              DpadFocusable(autofocus: true, onSelect: () => rowSelected = true, child: const Text('Row A')),
              const SizedBox(height: 40),
              Builder(
                builder: (context) => DpadFocusable(
                  onSelect: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => Scaffold(
                        body: Center(
                          child: DpadFocusable(
                            autofocus: true,
                            onSelect: () => Navigator.of(context).pop(),
                            child: const Text('Page B'),
                          ),
                        ),
                      ),
                    ),
                  ),
                  child: const Text('Open B'),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    // Focus "Open B" and select it: page B is pushed.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Page B'), findsOneWidget);

    // Select again: page B pops and focus should fall back on page A.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Page B'), findsNothing);

    // Move to Row A and select it — this must fire its callback.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(rowSelected, true);
  });
}
