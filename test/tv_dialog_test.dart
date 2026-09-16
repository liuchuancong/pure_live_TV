import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/dialog/tv_dialog_option_tile.dart';
import 'package:pure_live/shared/dialog/tv_dialog_utils.dart';
import 'package:pure_live/shared/dialog/tv_select_dialog.dart';
import 'package:pure_live/shared/theme/index.dart';

/// Every dialog must offer a visible way out, and its entries must be shaped rows
/// rather than full-width bars.
///
/// Two regressions are pinned here: the selection dialog used to render its
/// entries as `TvButton`s (a list stretches them into stadium bars, so the entries
/// read as blocks) and carried no button at all — closing one depended on knowing
/// that the remote's Back works.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  /// Opens a select dialog over a page and records what it returns.
  Future<void> pumpSelectDialog(
    WidgetTester tester, {
    required void Function(String?) onResult,
    TvThemeData palette = darkTvTheme,
  }) async {
    await tester.pumpWidget(
      ScreenUtilPlusInit(
        designSize: const Size(1920, 1080),
        autoRebuild: false,
        minTextAdapt: true,
        splitScreenMode: false,
        child: MaterialApp(
          builder: Dpad.wrap(),
          theme: ThemeData(extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: palette)]),
          home: Scaffold(
            body: Builder(
              builder: (context) => Center(
                child: TextButton(
                  onPressed: () async {
                    final String? picked = await TvDialogUtils.showSelect<String>(
                      context: context,
                      title: 'pick one',
                      selectedValue: 'b',
                      items: const <TvSelectItem<String>>[
                        TvSelectItem<String>(title: 'a', value: 'a'),
                        TvSelectItem<String>(title: 'b', value: 'b', subtitle: 'the one in force'),
                        TvSelectItem<String>(title: 'c', value: 'c'),
                      ],
                    );
                    onResult(picked);
                  },
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('a select dialog has one rounded row per entry and a close button', (WidgetTester tester) async {
    await pumpSelectDialog(tester, onResult: (_) {});

    expect(find.byType(TvDialogOptionTile), findsNWidgets(3));
    expect(find.text('a'), findsOneWidget);
    // Without loaded localizations `i18nOr`/`i18n` fall back to the key.
    expect(find.text('close'), findsOneWidget, reason: 'the dialog needs its own way out');

    // The rows are rounded rectangles, not square blocks.
    final TvDialogOptionTile row = tester.widget(find.byType(TvDialogOptionTile).first);
    expect(row.radius, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('the selected entry is marked and the chosen value is returned', (WidgetTester tester) async {
    String? result;
    await pumpSelectDialog(tester, onResult: (value) => result = value);

    // The value in force starts marked.
    final Iterable<TvDialogOptionTile> rows = tester.widgetList<TvDialogOptionTile>(find.byType(TvDialogOptionTile));
    expect(rows.where((row) => row.selected).map((row) => row.title), <String>['b']);

    await tester.tap(find.text('c'));
    await tester.pumpAndSettle();
    expect(result, 'c');
    expect(find.byType(TvDialogOptionTile), findsNothing, reason: 'choosing closes the dialog');
  });

  testWidgets('the close button leaves the choice untouched', (WidgetTester tester) async {
    String? result = 'unset';
    await pumpSelectDialog(tester, onResult: (value) => result = value);

    await tester.tap(find.text('close'));
    await tester.pumpAndSettle();
    expect(result, isNull, reason: 'closing must not report a choice');
    expect(find.byType(TvDialogOptionTile), findsNothing);
  });
}
