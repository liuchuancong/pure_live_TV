import 'tv_theme_data.dart';
import 'package:flutter/material.dart';

class TvThemeExtension extends ThemeExtension<TvThemeExtension> {
  final TvThemeData theme;

  const TvThemeExtension(this.theme);

  @override
  TvThemeExtension copyWith({TvThemeData? theme}) {
    return TvThemeExtension(theme ?? this.theme);
  }

  @override
  TvThemeExtension lerp(covariant ThemeExtension<TvThemeExtension>? other, double t) {
    return this;
  }
}
