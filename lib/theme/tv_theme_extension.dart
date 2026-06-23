import 'tv_theme_data.dart';
import 'package:flutter/material.dart';

class TvThemeExtension extends ThemeExtension<TvThemeExtension> {
  final TvThemeData theme;

  const TvThemeExtension({required this.theme});

  @override
  ThemeExtension<TvThemeExtension> copyWith({TvThemeData? theme}) {
    return TvThemeExtension(theme: theme ?? this.theme);
  }

  @override
  ThemeExtension<TvThemeExtension> lerp(ThemeExtension<TvThemeExtension>? other, double t) {
    if (other is! TvThemeExtension) return this;
    return this;
  }
}
