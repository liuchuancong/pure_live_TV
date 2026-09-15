import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The title bar's back button must be reachable from the content, both ways.
///
/// A settings sub-page can only be left through that button on a remote, so a
/// one-way trip strands the user. The page structure mirrors `TvScaffold`
/// (title bar above the content, one region) without its background layer,
/// which needs the app's settings service.
///
/// Focus is identified by widget ancestry rather than by `Focus.of`: a
/// `DpadFocusable` wraps whatever it presenters in an `ExcludeFocus`, so the
/// nearest enclosing `Focus` of a button's label is that non-focusable node,
/// not the one the d-pad drives.
void main() {
  bool focusIsInside<T extends Widget>() {
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return false;
    return context.findAncestorWidgetOfExactType<T>() != null;
  }

  Widget page({required Widget child}) {
    return Scaffold(
      body: DpadRegion(
        child: Column(
          children: [
            TvAppBar(title: 'Section'),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Future<void> pumpPage(WidgetTester tester, Widget child) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(
          builder: Dpad.wrap(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => page(child: child)),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  Widget twoRows() => Column(
    children: [
      TvSettingsSwitchTile(title: 'First row', value: true, onChanged: _ignore),
      TvSettingsSwitchTile(title: 'Second row', value: false, onChanged: _ignore),
    ],
  );

  testWidgets('down reaches the content and up returns to the back button', (tester) async {
    await pumpPage(tester, twoRows());

    expect(focusIsInside<TvButton>(), isTrue, reason: 'a pushed page should start on its back button');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusIsInside<TvSettingsRow>(), isTrue, reason: 'down should reach the content');

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(focusIsInside<TvButton>(), isTrue, reason: 'up should return to the back button');
  });

  testWidgets('up from a lower row climbs back to the back button', (tester) async {
    await pumpPage(tester, twoRows());

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusIsInside<TvSettingsRow>(), isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();

    expect(focusIsInside<TvButton>(), isTrue, reason: 'up must climb back to the back button');
  });
}

void _ignore(bool _) {}
