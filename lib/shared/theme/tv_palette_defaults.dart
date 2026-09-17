import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/index.dart';

/// Colours anything that does not colour itself with the **TV palette** instead of
/// letting the Material layer decide.
///
/// A `Text` or `Icon` with no colour of its own inherits from the Material theme,
/// whose foreground in 浅色 mode is black — while the surfaces around it (cards,
/// panels, the wallpaper wash) come from the palette. That mismatch is what left the
/// shared widgets with unreadable black text and black icons in light mode.
///
/// Wrapped around the whole app, below the Navigator, so dialogs and overlays
/// inherit it too.
class TvPaletteDefaults extends StatelessWidget {
  const TvPaletteDefaults({super.key, required this.theme, required this.child});

  final TvThemeData theme;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(color: theme.primaryTextColor),
      child: DefaultTextStyle(
        style: AppTextStyles.t16W500.copyWith(color: theme.primaryTextColor),
        child: child,
      ),
    );
  }
}
