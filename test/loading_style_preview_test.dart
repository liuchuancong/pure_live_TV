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

  testWidgets('every loading style paints in a preview smaller than 25 px', (WidgetTester tester) async {
    // The picker previews at `44.w`, and the settings row at `30.w`, which is under 25
    // logical pixels on a small TV. `SpinKitWaveSpinner` could not paint that small: its
    // painter builds `RRect.fromRectAndRadius` with a radius of
    // `(w - 10 * max(2.5, w * 0.015)) / 2`, negative below 25, which trips
    // `assert(tlRadiusX >= 0)` in `dart:ui/geometry.dart` — 主题设置 → 加载动画 threw out
    // of the render tree. Every style is painted at these sizes so the next style with a
    // minimum size of its own fails here instead of on the device.
    for (final double size in <double>[12, 18, 24]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Wrap(
              children: <Widget>[
                for (final Map<String, String> style in AppConsts.allStyles)
                  TvLoadingStylePreview(style: style['key']!, color: Colors.red, size: size, theme: darkTvTheme),
              ],
            ),
          ),
        ),
      );
      // Pump by hand: every preview animates forever, so `pumpAndSettle` never returns.
      for (int frame = 0; frame < 4; frame++) {
        await tester.pump(const Duration(milliseconds: 120));
      }
      expect(tester.takeException(), isNull, reason: 'a loading style threw at $size px');
    }
  });

  testWidgets('a preview scales styles that paint wider than their box', (WidgetTester tester) async {    // SpinKitThreeInOut paints ~1.5x its size; unscaled it overflowed the tile
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
