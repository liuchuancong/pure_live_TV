import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/tv_button.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:pure_live/shared/widgets/tv_scaffold.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('focus survives pushing and popping a player-like route', (tester) async {
    final FocusNode card = FocusNode(debugLabel: 'card');
    addTearDown(card.dispose);

    late BuildContext pageContext;
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(
          builder: Dpad.wrap(),
          navigatorObservers: <NavigatorObserver>[tvRouteObserver],
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
          home: Builder(
            builder: (context) {
              pageContext = context;
              return TvScaffold(
                child: Center(
                  child: TvButton(
                    title: 'room card',
                    focusNode: card,
                    autofocus: true,
                    onTap: () {
                      Navigator.of(pageContext).push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => const Scaffold(
                            backgroundColor: Colors.black,
                            body: DpadRegion(child: SizedBox.expand()),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(card.hasPrimaryFocus, isTrue, reason: 'the page starts focused');

    // Enter the room (push the player-like route).
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();

    // ignore: avoid_print
    print('AFTER PUSH: primary=${FocusManager.instance.primaryFocus?.debugLabel} '
        'scope=${FocusManager.instance.primaryFocus is FocusScopeNode} card=${card.hasPrimaryFocus}');

    // Leave it again.
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.pop();
    await tester.pumpAndSettle();

    // ignore: avoid_print
    print('AFTER POP: primary=${FocusManager.instance.primaryFocus?.debugLabel} '
        'scope=${FocusManager.instance.primaryFocus is FocusScopeNode} card=${card.hasPrimaryFocus}');
    expect(card.hasPrimaryFocus, isTrue, reason: 'returning to the list must restore the highlight');
  });
}
