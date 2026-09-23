import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:go_transitions/go_transitions.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/tv_button.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:pure_live/shared/widgets/tv_page_scaffold.dart';
import 'package:pure_live/shared/widgets/tv_scaffold.dart';
import 'package:pure_live/shared/widgets/tv_tab_view.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('focus survives a GoRouter push/pop', (tester) async {
    final FocusNode card = FocusNode(debugLabel: 'card');
    final FocusNode inner = FocusNode(debugLabel: 'inner');
    addTearDown(card.dispose);
    addTearDown(inner.dispose);

    late GoRouter router;
    router = GoRouter(
      observers: <NavigatorObserver>[tvRouteObserver],
      initialLocation: '/',
      routes: <RouteBase>[
        GoRoute(
          path: '/',
          builder: (context, state) => TvScaffold(
            child: TvTabView(
              memoryKey: 'diag/go-router',
              child: Center(
                child: TvButton(
                  title: 'room card',
                  focusNode: card,
                  autofocus: true,
                  onTap: () => router.push('/second'),
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: '/second',
          builder: (context, state) => TvPageScaffold(
            title: 'second',
            child: Center(
              child: TvButton(title: 'inner row', focusNode: inner, autofocus: true, onTap: () {}),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp.router(
          routerConfig: router,
          builder: Dpad.wrap(),
          theme: ThemeData(
            extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)],
            pageTransitionsTheme: const PageTransitionsTheme(
              builders: <TargetPlatform, PageTransitionsBuilder>{
                TargetPlatform.android: GoTransitions.fadeUpwards,
                TargetPlatform.iOS: GoTransitions.cupertino,
                TargetPlatform.macOS: GoTransitions.cupertino,
              },
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(card.hasPrimaryFocus, isTrue, reason: 'the page starts focused');

    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pumpAndSettle();
    // ignore: avoid_print
    print('AFTER PUSH: primary=${FocusManager.instance.primaryFocus?.debugLabel}');

    router.pop();
    await tester.pumpAndSettle();
    final FocusNode? afterPop = FocusManager.instance.primaryFocus;
    // ignore: avoid_print
    print('AFTER POP: primary=${afterPop?.debugLabel} scope=${afterPop is FocusScopeNode} '
        'cardMounted=${card.context?.mounted} card=${card.hasPrimaryFocus}');
    expect(card.hasPrimaryFocus, isTrue, reason: 'returning must restore the highlight');
  });
}
