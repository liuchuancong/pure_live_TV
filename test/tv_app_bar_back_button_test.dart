import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:pure_live/shared/widgets/tv_page_scaffold.dart';

/// The back button must follow the route stack, not a value cached at build
/// time.
///
/// The regression: the app bar decided "there is something to pop" once, during
/// a build. A page that is rebuilt while another route sits on top of it — which
/// is exactly what happens around a pop — kept a 返回 it should not have, and
/// nothing recomputed it afterwards. That is the stale 返回 the user saw on the
/// home page and the favorites page until an unrelated rebuild cleared it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/home',
      observers: <NavigatorObserver>[tvRouteObserver],
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (context, state) => const TvPageScaffold(title: 'Home', child: SizedBox.shrink())),
        GoRoute(
          path: '/settings',
          builder: (context, state) => const TvPageScaffold(title: 'Settings', child: SizedBox.shrink()),
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
          // The palette the TV shell reads through `context.tvTheme`.
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('the first page has no back button', (WidgetTester tester) async {
    await pumpApp(tester);
    // `i18n` falls back to the key when localizations are not loaded, which is
    // what these finders match on.
    expect(find.text('ui_back'), findsNothing);
  });

  testWidgets('a covered page hides its back button while the route above is on top', (WidgetTester tester) async {
    final GoRouter router = await pumpApp(tester);

    router.push('/settings');
    // Mid-transition: both pages are mounted, so both app bars are on screen and
    // the covered one can still pop (`canPop()` is true for it). Only the "am I
    // the current route" half of the rule keeps its 返回 off the screen.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('Settings'), findsWidgets, reason: 'the pushed page must be mounted');
    expect(find.text('ui_back'), findsOneWidget, reason: 'only the page on top may show a back button');

    await tester.pumpAndSettle();
    expect(find.text('ui_back'), findsOneWidget);
  });

  testWidgets('after a pop the page underneath has no back button', (WidgetTester tester) async {
    final GoRouter router = await pumpApp(tester);

    router.push('/settings');
    await tester.pumpAndSettle();
    expect(find.text('ui_back'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('ui_back'), findsNothing, reason: 'home cannot pop again, so its 返回 must be gone');
  });

  testWidgets('a page that becomes current again gets its back button back', (WidgetTester tester) async {
    final GoRouter router = await pumpApp(tester);

    router.push('/settings');
    await tester.pumpAndSettle();
    router.push('/settings');
    await tester.pumpAndSettle();
    expect(find.text('ui_back'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    // The middle page is on screen again and can still pop, so the button has to
    // come back — the other half of the regression: a hidden button that never
    // returns would be just as broken.
    expect(find.text('ui_back'), findsOneWidget);
  });
}