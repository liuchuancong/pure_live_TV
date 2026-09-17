import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pure_live/shared/theme/index.dart';

/// Content that does not colour itself must follow the **palette**, not Material.
///
/// The bug this pins: in 浅色 mode a `Text` or `Icon` with no colour of its own
/// inherited the Material scheme's black foreground, while the surface around it came
/// from the TV palette — the shared widgets showed black text and black icons in light
/// mode. `buildTvThemeData` gives the Material theme the palette's text and icon
/// colours, which is what `Scaffold`/`Material` re-install for unstyled content (a
/// wrapper above the Navigator is not enough).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final Brightness brightness in Brightness.values) {
    final TvThemeData palette = darkTvTheme.resolveFor(brightness: brightness);
    final ThemeData theme = buildTvThemeData(
      palette: palette,
      brightness: brightness,
      colorScheme: ColorScheme.fromSeed(seedColor: palette.focusColor, brightness: brightness),
      baseTextTheme: ThemeData(brightness: brightness).textTheme,
    );

    testWidgets('unstyled content follows the palette in ${brightness.name} mode', (WidgetTester tester) async {
      late BuildContext inside;
      await tester.pumpWidget(
        MaterialApp(
          theme: theme,
          home: Builder(
            builder: (context) {
              inside = context;
              return const Scaffold(
                body: Column(children: <Widget>[Text('unstyled'), Icon(Icons.abc)]),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(Theme.of(inside).brightness, brightness);
      expect(IconTheme.of(inside).color, palette.primaryTextColor);
      // `Scaffold` installs the Material text style, so this is the colour the row
      // content of an unstyled page actually gets.
      expect(Theme.of(inside).textTheme.bodyMedium?.color, palette.primaryTextColor);

      final RenderParagraph paragraph = tester.renderObject<RenderParagraph>(find.text('unstyled'));
      expect(paragraph.text.style?.color, palette.primaryTextColor);
      final RenderParagraph iconGlyph = tester.renderObject<RenderParagraph>(
        find.descendant(of: find.byType(Icon), matching: find.byType(RichText)),
      );
      expect(iconGlyph.text.style?.color, palette.primaryTextColor);

      // And the palette's own text colours really contrast with its surfaces.
      expect(
        TvThemeData.contrastRatio(palette.primaryTextColor, palette.backgroundColor),
        greaterThan(4.5),
      );
      expect(TvThemeData.contrastRatio(palette.primaryTextColor, palette.cardColor), greaterThan(4.5));
    });
  }
}
