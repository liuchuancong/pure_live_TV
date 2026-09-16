import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:pure_live/shared/widgets/tv_scaffold.dart';

/// The back button must follow the route stack, not a value cached at build
/// time.
///
/// The regression: `TvAppBar` read `Navigator.canPop()` while the page was being
/// rebuilt *during* a pop. At that moment the pop had not finished, so the page
/// underneath still saw "there is something to pop" and drew a 返回 — and nothing
/// rebuilt it afterwards, which is why it stayed on screen on the home page and
/// on the favorites tab (and why refreshing fixed it).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GoRouter> pumpApp(WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/home',
      observers: <NavigatorObserver>[tvRouteObserver],
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (context, state) => const TvScaffold(title: 'Home')),
        GoRoute(path: '/settings', builder: (context, state) => const TvScaffold(title: 'Settings')),
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

  testWidgets('a pushed page shows a back button and the page below does not', (WidgetTester tester) async {
    final GoRouter router = await pumpApp(tester);

    // `i18n` falls back to the key when localizations are not loaded, which is
    // what these finders match on.
    expect(find.text('ui_back'), findsNothing, reason: 'the first page cannot pop');

    router.push('/settings');
    await tester.pumpAndSettle();
    expect(find.text('ui_back'), findsOneWidget, reason: 'the pushed page can pop');

    // Pop and check the frame in which the page underneath is rebuilt, before
    // the transition has finished — this is where the stale button appeared.
    router.pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    expect(find.text('ui_back'), findsNothing, reason: 'the home page must not gain a back button during the pop');

    await tester.pumpAndSettle();
    expect(find.text('ui_back'), findsNothing, reason: 'and it must stay hidden once the pop has settled');
  });

  testWidgets('the back button returns after the page above it pops', (WidgetTester tester) async {
    final GoRouter router = await pumpApp(tester);

    router.push('/settings');
    await tester.pumpAndSettle();
    // A second push: the page in the middle is covered, and the top one shows a
    // back button. After popping, the middle page must show one again.
    router.push('/settings');
    await tester.pumpAndSettle();
    expect(find.text('ui_back'), findsOneWidget);

    router.pop();
    await tester.pumpAndSettle();
    expect(find.text('ui_back'), findsOneWidget, reason: 'the covered page is on screen again and can still pop');
  });
}
