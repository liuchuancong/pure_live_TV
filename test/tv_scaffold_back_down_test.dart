import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The up/down round trip between 返回 and the first content row must keep working
/// on every level of the stack.
///
/// This used to mirror `_TvScaffoldState`'s wiring by hand, which is exactly why
/// the third-level failure shipped: the copy was right while the real scaffold was
/// not. It builds the real [TvScaffold] now.
Widget scaffoldPage(String title, {required List<Widget> rows}) {
  return TvPageScaffold(
    title: title,
    child: SingleChildScrollView(child: Column(children: rows)),
  );
}

List<Widget> makeRows({int count = 3}) => <Widget>[
  for (int i = 0; i < count; i++) TvSettingsSwitchTile(title: 'row $i', value: false, onChanged: (_) {}),
];

Future<void> pumpRoot(WidgetTester tester) async {
  await tester.pumpWidget(
    ScreenUtilPlusInit(
      designSize: const Size(1920, 1080),
      autoRebuild: false,
      minTextAdapt: true,
      splitScreenMode: false,
      child: MaterialApp(
        builder: Dpad.wrap(),
        theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
        navigatorObservers: <NavigatorObserver>[tvRouteObserver],
        home: const Scaffold(body: SizedBox.shrink()),
      ),
    ),
  );
}

Future<void> pushPage(WidgetTester tester, Widget page) async {
  final BuildContext context = tester.element(find.byType(Scaffold).first);
  Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
  await tester.pumpAndSettle();
}

bool focusIsInside<T extends Widget>() {
  final BuildContext? context = FocusManager.instance.primaryFocus?.context;
  if (context == null) return false;
  return context.findAncestorWidgetOfExactType<T>() != null;
}

void main() {
  testWidgets('down from the back button re-enters the content, repeatedly', (tester) async {
    await pumpRoot(tester);
    await pushPage(tester, scaffoldPage('level 2', rows: makeRows()));

    // Round-trip up/down several times: back -> content -> back -> content.
    for (int i = 0; i < 5; i++) {
      // Up from the first content row reaches the back button...
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      // ...and down must always re-enter the content.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(
        focusIsInside<TvSettingsSwitchTile>(),
        isTrue,
        reason: 'cycle $i: down from 返回 must land on a content row',
      );
    }
  });

  testWidgets('a page pushed above another page keeps the round trip working', (tester) async {
    await pumpRoot(tester);
    await pushPage(tester, scaffoldPage('level 2', rows: makeRows()));
    await pushPage(tester, scaffoldPage('level 3', rows: makeRows()));

    // A pushed page opens with the highlight on 返回, never on a row of the page
    // below.
    expect(focusIsInside<TvButton>(), isTrue, reason: 'the third-level page opens on 返回');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(focusIsInside<TvButton>(), isTrue, reason: 'up stays on 返回 at the top');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusIsInside<TvSettingsSwitchTile>(), isTrue, reason: 'down from 返回 on a 3rd-level page must reach content');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(focusIsInside<TvButton>(), isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusIsInside<TvSettingsSwitchTile>(), isTrue, reason: 'down from 返回 must re-enter content after the round trip');
  });
}