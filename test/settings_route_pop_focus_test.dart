import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// Popping a second-level page must leave focus inside the page that comes
/// back, not on a node belonging to a route further down the stack.
///
/// `Dpad`'s focus resilience restores focus by picking a candidate from the
/// scope that ends up holding focus. When that scope is an ancestor scope, the
/// candidate list contains the focusables of *every* mounted route, so the
/// restore can land on an off-screen node of a lower route and the remote then
/// appears dead on the page the user is looking at.
///
/// The pages here mirror `TvScaffold`'s structure (a title bar with a back
/// button above the content, inside one region) without its background layer,
/// which needs the app's settings service.
void main() {
  /// Title bar + content, as TvScaffold builds it.
  Widget page({required String title, required Widget child}) {
    return Scaffold(
      body: DpadRegion(
        child: Column(
          children: [
            TvAppBar(title: title),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }

  Widget buildApp({required bool restoreFocus}) {
    return ScreenUtilPlusInit(
      designSize: const Size(1920, 1080),
      autoRebuild: false,
      minTextAdapt: true,
      splitScreenMode: false,
      child: MaterialApp(
        builder: Dpad.wrap(restoreFocus: restoreFocus),
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: TextButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => page(
                      title: 'Level one',
                      child: Column(
                        children: [
                          TvSettingsNavTile(
                            title: 'Open level two',
                            icon: Icons.palette_outlined,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => page(
                                  title: 'Level two',
                                  child: Column(
                                    children: [
                                      TvSettingsSwitchTile(
                                        title: 'Picker row one',
                                        value: true,
                                        onChanged: _ignore,
                                      ),
                                      TvSettingsSwitchTile(
                                        title: 'Picker row two',
                                        value: false,
                                        onChanged: _ignore,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                child: const Text('open level one'),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Opens both levels, moves focus inside level two, then pops back.
  Future<void> focusThenPop(WidgetTester tester) async {
    await tester.tap(find.text('open level one'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Open level two'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(Focus.of(tester.element(find.text('Picker row one'))).hasFocus, isTrue);

    // The same result as activating the title bar's back button.
    tester.state<NavigatorState>(find.byType(Navigator)).pop();
    await tester.pumpAndSettle();
  }

  testWidgets('after popping two levels, focus stays on the restored page', (tester) async {
    await tester.pumpWidget(buildApp(restoreFocus: true));
    await focusThenPop(tester);

    // The routes below the top one are offstage, but their focus nodes are
    // still in the tree — which is how the restore can reach them.
    final Finder hostButton = find.text('open level one', skipOffstage: false);
    final Finder restoredRow = find.text('Open level two', skipOffstage: false);

    expect(hostButton, findsOneWidget);
    final bool primaryOnLowerRoute =
        Focus.of(hostButton.evaluate().first).hasFocus;
    expect(
      primaryOnLowerRoute,
      isFalse,
      reason: 'focus was grabbed by a route below the restored page',
    );
    expect(
      Focus.of(restoredRow.evaluate().first).hasFocus,
      isTrue,
      reason: 'focus should return to the row that opened the page',
    );

    // And the title bar of the restored page must still be one step away,
    // which is the whole point: the remote can only leave through it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    final BuildContext? focusContext = FocusManager.instance.primaryFocus?.context;
    expect(
      focusContext?.findAncestorWidgetOfExactType<TvButton>() != null,
      isTrue,
      reason: 'up should reach the back button of the restored page',
    );
  });
}

void _ignore(bool _) {}
