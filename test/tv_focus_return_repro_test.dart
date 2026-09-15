import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// Regression: focus must return to the item the user acted on when a pushed
/// route pops away, and that item must still react to the remote.
///
/// Mirrors the settings flow: a menu page pushes a sub-page, the user pops
/// back, then presses OK again on the same row.
void main() {
  testWidgets('focus returns to the acted-on row after popping a route', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final List<String> selected = [];

    Widget menuPage(BuildContext context) {
      return TvFocusRestorer(
        child: DpadRegion(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    for (int i = 0; i < 12; i++)
                      DpadFocusable(
                        autofocus: i == 0,
                        onSelect: () {
                          if (i == 3) {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (context) => const SubPage()),
                            );
                          } else {
                            selected.add('row $i');
                          }
                        },
                        child: Text('Menu row $i'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(
          navigatorObservers: [tvRouteObserver],
          builder: Dpad.wrap(),
          home: Builder(builder: menuPage),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Walk down to row 3 and open it — pushes the sub-page.
    for (int i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
    }
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sub')), findsOneWidget);

    // Pop the sub-page with its select handler.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('sub')), findsNothing);

    // Focus must be back on row 3, and OK must activate it.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(selected, ['row 3'], reason: 'the row the user came back from must be selectable');
  });

  testWidgets('focus returns to the acted-on row after closing a dialog route', (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    bool selected = false;
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(
          navigatorObservers: [tvRouteObserver],
          builder: Dpad.wrap(),
          home: Builder(
            builder: (context) => TvFocusRestorer(
              child: DpadRegion(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    DpadFocusable(
                      autofocus: true,
                      onSelect: () {
                        selected = true;
                        showDialog<void>(
                          context: context,
                          builder: (context) => AlertDialog(
                            content: DpadFocusable(
                              onSelect: () => Navigator.of(context).pop(),
                              child: const Text('Dialog close'),
                            ),
                          ),
                        );
                      },
                      child: const Text('Open dialog'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open the dialog (its select fired), then close it.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Dialog close'), findsOneWidget);
    expect(selected, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Dialog close'), findsNothing);

    // Focus is back on the button: OK must open the dialog again.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('Dialog close'), findsOneWidget);
  });
}

class SubPage extends StatelessWidget {
  const SubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: const ValueKey('sub'),
      body: DpadRegion(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: DpadFocusable(
                autofocus: true,
                onSelect: () => Navigator.of(context).maybePop(),
                child: const Text('SUB BACK'),
              ),
            ),
            Expanded(
              child: ListView(
                children: [for (int i = 0; i < 6; i++) DpadFocusable(child: Text('Sub row $i'))],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
