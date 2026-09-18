import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/features/live_play/widgets/panels/player_index_panel.dart';

/// The player's side panels and the bar's option lists must offer the same way
/// out, and the highlight must stay readable on every palette.
///
/// Two regressions are pinned here:
///  * the panel used to open with a 返回 row *first* while 清晰度/线路/比例/内核 all
///    end with a 关闭 row, and the leading row shifted every index by one;
///  * 弹幕设置 painted its focused row black, which is unreadable on the accent
///    fill, and the panel surface was hard-coded black, so a light palette got a
///    black slab inside a light page.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Minimal harness: the panel is index-driven, so the parent owns the
  /// selection like the real panels do.
  Future<void> pumpPanel(
    WidgetTester tester, {
    required TvThemeData palette,
    required List<int> selectedCalls,
    required List<int> closeCalls,
  }) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: palette)]),
          home: Scaffold(
            body: _PanelHost(palette: palette, onSelect: selectedCalls.add, onClose: () => closeCalls.add(0)),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the close row is last, and the real rows keep their index', (WidgetTester tester) async {
    final selected = <int>[];
    final closed = <int>[];
    await pumpPanel(tester, palette: darkTvTheme, selectedCalls: selected, closeCalls: closed);

    // Without loaded localizations `i18nOr` returns its fallback, so the close
    // row reads 关闭 here.
    expect(find.text('关闭'), findsOneWidget, reason: 'the panel ends with a 关闭 row');
    expect(find.text('ui_back'), findsNothing, reason: 'the old leading 返回 row must be gone');

    // OK on row 2 must report index 2, not 1 — the shift existed only because of
    // the leading row. A frame between the keys, as on a real remote.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(selected, <int>[2]);

    // Walking on to the last row and confirming closes the panel.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.select);
    await tester.pump();
    expect(closed, hasLength(1));
    expect(selected, <int>[2], reason: 'the close row must not be reported as a row action');
  });
}

class _PanelHost extends StatefulWidget {
  const _PanelHost({required this.palette, required this.onSelect, required this.onClose});

  final TvThemeData palette;
  final ValueChanged<int> onSelect;
  final VoidCallback onClose;

  @override
  State<_PanelHost> createState() => _PanelHostState();
}

class _PanelHostState extends State<_PanelHost> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return PlayerIndexPanel(
      title: 'panel',
      rows: const <PlayerPanelRow>[
        PlayerPanelRow(label: 'row 0'),
        PlayerPanelRow(label: 'row 1'),
        PlayerPanelRow(label: 'row 2'),
      ],
      selectedIndex: _index,
      onSelectionChanged: (i) => setState(() => _index = i),
      onSelect: widget.onSelect,
      onClose: widget.onClose,
    );
  }
}
