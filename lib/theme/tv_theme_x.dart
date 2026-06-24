import 'tv_theme_data.dart';
import 'tv_theme_extension.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/themes/cyber_theme.dart';

extension TvThemeX on BuildContext {
  TvThemeData get tvTheme {
    final extension = Theme.of(this).extension<TvThemeExtension>();
    return extension?.theme ?? cyberTvTheme;
  }
}
