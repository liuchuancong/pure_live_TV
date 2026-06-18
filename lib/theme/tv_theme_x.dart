import 'tv_theme_data.dart';
import 'tv_theme_extension.dart';
import 'package:flutter/material.dart';

extension TvThemeX on BuildContext {
  TvThemeData get tvTheme {
    return Theme.of(this).extension<TvThemeExtension>()!.theme;
  }
}
