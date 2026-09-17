import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// 设置 → 主题设置 → 背景设置 → 纯色/视频: coming **back** to 背景设置 left the screen with
/// no highlight and a dead remote.
///
/// The shape matters. `/settings/theme` lives inside the shell's *nested* navigator,
/// while 背景设置 and 纯色 are top-level routes pushed on the **root** navigator. The
/// root push therefore covers the shell's route — it does not cover `/settings/theme`
/// inside that shell, so the nested page never receives `didPushNext` and keeps its
/// focus tree alive while a page the user cannot see is on top of it.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<GoRouter> pumpStack(WidgetTester tester) async {
    final GoRouter router = GoRouter(
      initialLocation: '/home',
      observers: <NavigatorObserver>[tvRouteObserver],
      routes: <RouteBase>[
        GoRoute(path: '/home', builder: (context, state) => const _Page(title: 'home', rows: 3)),
        GoRoute(path: '/settings', builder: (context, state) => const _Page(title: 'settings', rows: 3)),
        ShellRoute(
          builder: (context, state, child) => child,
          routes: <RouteBase>[
            GoRoute(path: '/settings/theme', builder: (context, state) => const _Page(title: 'theme', rows: 3)),
          ],
        ),
        GoRoute(path: '/wallpaper', builder: (context, state) => const _Page(title: 'wallpaper', rows: 4)),
        GoRoute(path: '/wallpaper_items', builder: (context, state) => const _GridPage()),
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
          builder: Dpad.wrap(theme: const DpadThemeData(scrollDuration: Duration.zero)),
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  /// The title of the page the keyboard is actually on, read off the focused node's
  /// ancestors — a node of a page that is not on screen reads its own page's title.
  String? focusedPage() {
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    if (context == null) return null;
    final _Page? page = context.findAncestorWidgetOfExactType<_Page>();
    if (page != null) return page.title;
    return context.findAncestorWidgetOfExactType<_GridPage>() == null ? null : 'wallpaper_items';
  }

  bool focusIsReal() {
    final FocusNode? primary = FocusManager.instance.primaryFocus;
    return primary != null && primary is! FocusScopeNode && primary.context?.mounted == true;
  }

  testWidgets('returning from 纯色 leaves the highlight on 背景设置', (WidgetTester tester) async {
    final GoRouter router = await pumpStack(tester);

    router.push('/settings');
    await tester.pumpAndSettle();
    router.push('/settings/theme');
    await tester.pumpAndSettle();
    router.push('/wallpaper');
    await tester.pumpAndSettle();

    expect(focusedPage(), 'wallpaper', reason: '背景设置 opens on its own 返回');

    router.push('/wallpaper_items');
    await tester.pumpAndSettle();
    expect(focusedPage(), 'wallpaper_items');

    router.pop();
    await tester.pumpAndSettle();

    expect(focusIsReal(), isTrue, reason: 'the revealed page must hold a real node');
    expect(
      focusedPage(),
      'wallpaper',
      reason: 'the highlight belongs to 背景设置, not to a covered page still sitting in the tree',
    );

    // …and the remote still drives it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    expect(focusedPage(), 'wallpaper', reason: 'the remote still moves inside 背景设置');

    // Up at the top edge stays in 背景设置: the covered theme page must not be able to
    // take the keyboard at all, however the d-pad's geometric fallback feels about it.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    expect(focusedPage(), 'wallpaper', reason: 'the covered page behind 背景设置 is unreachable');

    // Going in and out again keeps working — the restore used to leave focus behind.
    for (int cycle = 0; cycle < 3; cycle++) {
      router.push('/wallpaper_items');
      await tester.pumpAndSettle();
      expect(focusedPage(), 'wallpaper_items', reason: 'cycle $cycle: 纯色 opens on its own 返回');

      router.pop();
      await tester.pumpAndSettle();
      expect(focusedPage(), 'wallpaper', reason: 'cycle $cycle: 返回 lands on 背景设置');
    }
  });
}

/// A settings-shaped page: its own chrome and a few focusable rows.
class _Page extends StatelessWidget {
  const _Page({required this.title, required this.rows});

  final String title;
  final int rows;

  @override
  Widget build(BuildContext context) {
    return TvPageScaffold(
      title: title,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(16.sp),
        child: Column(
          children: <Widget>[
            for (int row = 1; row <= rows; row++)
              TvSettingsNavTile(title: '$title row $row', icon: Icons.circle_outlined, onTap: () {}),
          ],
        ),
      ),
    );
  }
}

/// The 纯色 grid: its own region that lets the d-pad leave upward, like
/// `WallpaperItemsPage`.
class _GridPage extends StatelessWidget {
  const _GridPage();

  @override
  Widget build(BuildContext context) {
    return TvPageScaffold(
      title: 'items',
      child: DpadRegion(
        verticalEdge: DpadEdgeBehavior.leave,
        child: GridView.count(
          crossAxisCount: 4,
          padding: EdgeInsets.all(16.sp),
          children: <Widget>[
            for (int i = 1; i <= 8; i++)
              TvSettingsNavTile(title: 'tile $i', icon: Icons.image_outlined, onTap: () {}),
          ],
        ),
      ),
    );
  }
}
