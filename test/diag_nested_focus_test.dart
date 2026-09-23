import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/tv_button.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:pure_live/shared/widgets/tv_page_scaffold.dart';
import 'package:pure_live/shared/widgets/tv_scaffold.dart';
import 'package:pure_live/shared/widgets/tv_tab_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('focus survives entering and leaving a page whose content is a nested region', (tester) async {
    final FocusNode card = FocusNode(debugLabel: 'card');
    final FocusNode nested = FocusNode(debugLabel: 'nested');
    addTearDown(card.dispose);
    addTearDown(nested.dispose);

    late NavigatorState navigator;
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
              navigator = Navigator.of(context);
              return TvScaffold(
                child: TvTabView(
                  memoryKey: 'diag/nested',
                  child: Center(
                    child: TvButton(
                      title: 'room card',
                      focusNode: card,
                      autofocus: true,
                      onTap: () => navigator.push<void>(
                        MaterialPageRoute<void>(
                          builder: (context) => TvPageScaffold(
                            title: 'area rooms',
                            child: TvTabView(
                              memoryKey: 'diag/nested2',
                              child: Center(
                                child: TvButton(title: 'inner row', focusNode: nested, autofocus: true, onTap: () {}),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
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

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    final FocusNode? afterPush = FocusManager.instance.primaryFocus;
    // ignore: avoid_print
    print('AFTER PUSH: primary=${afterPush?.debugLabel} scope=${afterPush is FocusScopeNode}');

    navigator.pop();
    await tester.pumpAndSettle();
    final FocusNode? afterPop = FocusManager.instance.primaryFocus;
    // ignore: avoid_print
    print('AFTER POP: primary=${afterPop?.debugLabel} scope=${afterPop is FocusScopeNode} card=${card.hasPrimaryFocus}');
    expect(card.hasPrimaryFocus, isTrue, reason: 'returning must restore the highlight');
  });
}
