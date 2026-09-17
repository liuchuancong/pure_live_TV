import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/tv_theme_data.dart';
import 'package:pure_live/shared/theme/tv_theme_extension.dart';

/// Builds the Material layer for a palette and a 主题模式.
///
/// The palette drives the *text and icon* colours of the Material theme as well as
/// its own widgets. Without that, anything a widget does not colour itself inherits
/// the Material scheme's foreground — black in 浅色 mode — while the surface around it
/// comes from the palette, which is exactly the "black text and black icons in light
/// mode" the shared widgets showed. `Scaffold`/`Material` re-install a text style, so
/// this has to be set on the theme itself; wrapping the app subtree is not enough.
///
/// The page background stays the palette's, and the route canvas stays transparent so
/// the single app background below the Navigator shows through (an opaque canvas was
/// the white flash on every push and pop).
ThemeData buildTvThemeData({
  required TvThemeData palette,
  required Brightness brightness,
  required ColorScheme colorScheme,
  required TextTheme baseTextTheme,
  String? fontFamily,
  PageTransitionsTheme? pageTransitions,
}) {
  return ThemeData(
    useMaterial3: true,
    brightness: brightness,
    fontFamily: fontFamily,
    textTheme: baseTextTheme.apply(
      bodyColor: palette.primaryTextColor,
      displayColor: palette.primaryTextColor,
    ),
    iconTheme: IconThemeData(color: palette.primaryTextColor),
    scaffoldBackgroundColor: palette.backgroundColor,
    canvasColor: Colors.transparent,
    pageTransitionsTheme: pageTransitions,
    colorScheme: colorScheme,
    extensions: <ThemeExtension<dynamic>>[TvThemeExtension(theme: palette)],
  );
}
