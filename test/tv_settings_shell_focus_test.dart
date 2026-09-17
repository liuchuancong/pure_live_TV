import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The settings shell keeps ONE `TvScaffold` and swaps the page inside it with a
/// nested navigator — so `TvScaffold`'s route awareness never sees those pushes.
///
/// That is why the third-level failure kept coming back: every focus fix written
/// against a "page is pushed" model was blind to the way these pages are actually
/// shown. This harness has the shell's shape: one scaffold, an inner navigator, and
/// rows inside it that open the next level.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpShell(WidgetTester tester, {required int depth}) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(
          // Same d-pad root and snap-scroll theme the app installs.
          builder: Dpad.wrap(theme: const DpadThemeData(scrollDuration: Duration.zero)),
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: darkTvTheme)]),
          navigatorObservers: <NavigatorObserver>[tvRouteObserver],
          home: const Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );
    // The shell is pushed above the settings menu, so its scaffold owns the 返回
    // button — that is where the up/down round trip happens.
    final BuildContext context = tester.element(find.byType(Scaffold).first);
    Navigator.of(context).push<void>(MaterialPageRoute<void>(builder: (_) => _Shell(depth: depth)));
    await tester.pumpAndSettle();
  }

  bool onRow() {
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    return context?.findAncestorWidgetOfExactType<TvSettingsSwitchTile>() != null;
  }

  bool onBackButton() {
    final BuildContext? context = FocusManager.instance.primaryFocus?.context;
    return context?.findAncestorWidgetOfExactType<TvButton>() != null;
  }

  testWidgets('level 3: up to 返回 and back down again, repeatedly', (tester) async {
    await pumpShell(tester, depth: 3);

    // Every page opens with the highlight on 返回.
    expect(onBackButton(), isTrue, reason: 'a page opens on 返回');

    for (int cycle = 0; cycle < 5; cycle++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(onRow(), isTrue, reason: 'cycle $cycle: down from 返回 reaches the rows');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(onBackButton(), isTrue, reason: 'cycle $cycle: up returns to 返回');
    }
  });

  testWidgets('level 4: the same walk after two inner pushes', (tester) async {
    await pumpShell(tester, depth: 4);
    expect(onBackButton(), isTrue, reason: 'a page opens on 返回');

    for (int cycle = 0; cycle < 3; cycle++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(onRow(), isTrue, reason: 'cycle $cycle: down from 返回 reaches the rows');
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(onBackButton(), isTrue, reason: 'cycle $cycle: up returns to 返回');
    }
  });
}

/// One `TvScaffold` for every page, like `SettingsSectionScaffold` in the shell.
class _Shell extends StatefulWidget {
  const _Shell({required this.depth});

  final int depth;

  @override
  State<_Shell> createState() => _ShellState();
}

class _ShellState extends State<_Shell> {
  final GlobalKey<NavigatorState> _inner = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Open every level up to the requested depth, like the user walking the
      // settings menu: 设置 → section → 排序.
      for (int level = 2; level <= widget.depth; level++) {
        _open(level);
      }
    });
  }

  void _open(int level) {
    _inner.currentState?.push<void>(
      MaterialPageRoute<void>(
        // Every page carries its own chrome, exactly like the real route table:
        // `SettingsSectionScaffold` wraps each page, and the shell itself adds
        // nothing.
        builder: (context) => _Page(level: level, onOpenNext: () => _open(level + 1)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // The shell contributes no scaffold: one shared app bar (and its 返回 button)
    // for every page is what used to steal the highlight.
    return Navigator(
      key: _inner,
      // go_router merges the router's observers into the shell's navigator (with a
      // per-navigator wrapper, since an observer can only attach to one navigator),
      // which is how a page's own scaffold receives route events.
      observers: <NavigatorObserver>[_ForwardingObserver()],
      onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const SizedBox.shrink()),
    );
  }
}

class _Page extends StatelessWidget {
  const _Page({required this.level, required this.onOpenNext});

  final int level;
  final VoidCallback onOpenNext;

  @override
  Widget build(BuildContext context) {
    // Each page owns its scaffold — its app bar, its 返回 button and the focus
    // handoff between them — like `SettingsSectionScaffold` does for the real pages.
    return TvPageScaffold(
      title: 'level $level',
      child: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            for (int row = 1; row <= 3; row++)
              TvSettingsSwitchTile(
                title: 'level $level row $row',
                value: false,
                onChanged: (_) => onOpenNext(),
              ),
          ],
        ),
      ),
    );
  }
}

/// Forwards route events from the shell's own navigator to the app's observer.
///
/// An observer attaches to a single navigator, so go_router wraps the router's
/// observers per navigator instead of handing the same instance to both. This is
/// that wrapper in miniature.
class _ForwardingObserver extends NavigatorObserver {
  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      tvRouteObserver.didPush(route, previousRoute);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      tvRouteObserver.didPop(route, previousRoute);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      tvRouteObserver.didRemove(route, previousRoute);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) =>
      tvRouteObserver.didReplace(newRoute: newRoute, oldRoute: oldRoute);
}