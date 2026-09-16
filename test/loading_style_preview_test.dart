import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/shared/widgets/index.dart';

/// The animation picker is only useful if every entry animates.
///
/// The regression this pins: the `default` entry was drawn as a frozen
/// `CircularProgressIndicator(value: 0.7)`, and the preview helper decided
/// whether a library had handled a style by testing `is! SizedBox` — so a style
/// whose animation is wrapped in a box could be reported as "handled" while
/// rendering nothing at all.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the style table is the mobile one', () {
    expect(AppConsts.allStyles.length, greaterThan(80));
    expect(AppConsts.allStyles.first['key'], AppConsts.defaultLoadingStyleKey);
    expect(
      AppConsts.allStyles.map((style) => style['key']).toSet().length,
      AppConsts.allStyles.length,
      reason: 'duplicate style key',
    );
  });

  testWidgets('every loading style renders a live animation', (WidgetTester tester) async {
    final List<String> missing = <String>[];
    final List<String> still = <String>[];

    for (final Map<String, String> style in AppConsts.allStyles) {
      final String key = style['key']!;
      if (tvLoadingStyleWidget(style: key, color: Colors.red, size: 44, theme: darkTvTheme) == null) {
        missing.add(key);
        continue;
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: TvLoadingStylePreview(style: key, color: Colors.red, size: 44, theme: darkTvTheme),
            ),
          ),
        ),
      );
      // Let the animation tickers start before asking whether any is running.
      await tester.pump(const Duration(milliseconds: 32));

      if (!tester.hasRunningAnimations) still.add(key);
    }

    expect(missing, isEmpty, reason: 'styles with no animation: $missing');
    expect(still, isEmpty, reason: 'styles that do not animate: $still');
  });

  testWidgets('a preview scales styles that paint wider than their box', (WidgetTester tester) async {
    // SpinKitThreeInOut paints ~1.5x its size; unscaled it overflowed the tile
    // and painted over its neighbours.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(child: TvLoadingStylePreview(style: 'threeInOut', color: Colors.red, size: 44, theme: darkTvTheme)),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 32));

    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(TvLoadingStylePreview)), const Size(44, 44));
  });

  testWidgets('an unknown style falls back to nothing, never to a stray box', (WidgetTester tester) async {
    expect(tvLoadingStyleWidget(style: 'not-a-style', color: Colors.red, size: 44, theme: darkTvTheme), isNull);
  });
}
