import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/tv_button.dart';
import 'package:pure_live/shared/widgets/tv_focus_restorer.dart';
import 'package:pure_live/shared/widgets/tv_page_scaffold.dart';

/// Walking up out of a page's content and back down again must keep working.
///
/// The regression: on a third-level page, moving the highlight down from 返回 into
/// the rows and then back up to 返回 left the remote stuck on 返回 — up and down
/// did nothing until the page was left and re-entered. Second-level pages were
/// fine, third-level pages always failed.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// One set of row nodes per level: a node cannot be attached to two pages at
  /// once, and the pages below stay alive in the stack.
  final Map<int, List<FocusNode>> levelRows = <int, List<FocusNode>>{};

  List<FocusNode> rowsFor(int level) => levelRows.putIfAbsent(
    level,
    () => <FocusNode>[for (int i = 0; i < 3; i++) FocusNode(debugLabel: 'level $level/row ${i + 1}')],
  );

  tearDown(() {
    for (final List<FocusNode> nodes in levelRows.values) {
      for (final FocusNode node in nodes) {
        node.dispose();
      }
    }
    levelRows.clear();
  });

  Future<void> pumpApp(WidgetTester tester) async {
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
          home: _Page(level: 1, rowNodes: rowsFor(1)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pushLevel(WidgetTester tester, int level) async {
    final NavigatorState navigator = tester.state(find.byType(Navigator));
    navigator.push<void>(
      MaterialPageRoute<void>(builder: (context) => _Page(level: level, rowNodes: rowsFor(level))),
    );
    await tester.pumpAndSettle();
  }

  /// The back button's focus node, and the page's first content row.
  ({FocusNode? back, FocusNode? row}) nodes(WidgetTester tester, int level) {
    final Iterable<TvButton> buttons = tester.widgetList<TvButton>(find.byType(TvButton));
    // The label comes from the built-in table when assets are not loaded.
    bool isBack(TvButton button) => button.title == '返回' || button.title == 'ui_back';
    TvButton? back;
    for (final TvButton button in buttons) {
      if (isBack(button) && button.focusNode != null) back = button;
    }
    return (back: back?.focusNode, row: rowsFor(level).first);
  }

  testWidgets('down from 返回 still reaches the rows on a third-level page', (WidgetTester tester) async {
    await pumpApp(tester);
    await pushLevel(tester, 2);
    await pushLevel(tester, 3);

    final FocusNode back = nodes(tester, 3).back!;
    final FocusNode row = nodes(tester, 3).row!;

    // The state the user reports: the highlight is on 返回. Then up/down must keep
    // working — this used to leave the remote stuck on 返回 on a third-level page.
    back.requestFocus();
    await tester.pump();
    expect(back.hasPrimaryFocus, isTrue);

    for (int i = 0; i < 3; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(row.hasPrimaryFocus, isTrue, reason: 'round trip $i: down from 返回 must reach the rows');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(back.hasPrimaryFocus, isTrue, reason: 'round trip $i: up must return to 返回');
    }
  });

  testWidgets('the same walk works on a second-level page', (WidgetTester tester) async {
    await pumpApp(tester);
    await pushLevel(tester, 2);

    final FocusNode back = nodes(tester, 2).back!;
    final FocusNode row = nodes(tester, 2).row!;

    back.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(row.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(back.hasPrimaryFocus, isTrue);
  });

  testWidgets('a freshly pushed page opens on 返回 and leaves the page below alone', (WidgetTester tester) async {
    await pumpApp(tester);
    await pushLevel(tester, 2);
    await pushLevel(tester, 3);

    // The highlight opens on this page's own 返回, not on a row of the page below
    // (which is what made the remote drive an invisible screen).
    expect(nodes(tester, 3).back?.hasPrimaryFocus, isTrue, reason: 'a pushed page opens on its own 返回');
    for (final FocusNode covered in rowsFor(2)) {
      expect(covered.hasPrimaryFocus, isFalse, reason: 'the covered page must have given the keyboard up');
    }

    // Down walks into the page, up comes back: the round trip on a pushed route.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    expect(rowsFor(3).first.hasPrimaryFocus, isTrue, reason: 'down from 返回 reaches the first row');
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump();
    expect(nodes(tester, 3).back?.hasPrimaryFocus, isTrue, reason: 'up from the first row returns to 返回');
  });
}

/// A page shaped like every settings page: a [TvScaffold] with a 返回 in its app
/// bar and a few focusable rows.
class _Page extends StatelessWidget {
  const _Page({required this.level, required this.rowNodes});

  final int level;
  final List<FocusNode> rowNodes;

  @override
  Widget build(BuildContext context) {
    return TvPageScaffold(
      title: 'level $level',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (int row = 1; row <= rowNodes.length; row++)
            TvButton(
              title: 'row $row',
              focusNode: rowNodes[row - 1],
              autofocus: row == 1,
              onTap: () {
                final NavigatorState navigator = Navigator.of(context);
                navigator.push<void>(MaterialPageRoute<void>(builder: (context) => _Page(level: level + 1, rowNodes: rowNodes)));
              },
            ),
        ],
      ),
    );
  }
}