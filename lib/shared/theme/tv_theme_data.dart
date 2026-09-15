import 'package:flutter/material.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

enum TvBackgroundType { color, image, video }

class TvThemeData {
  final String id;

  /// Translation key of the display name.
  ///
  /// The name is resolved on every read so the theme list follows the active
  /// language. Storing the translated string froze whichever language was
  /// active when the preset was first touched.
  final String nameKey;

  String get name => i18n(nameKey);

  final TvBackgroundType backgroundType;

  final Color backgroundColor;

  final String? backgroundImage;

  final String? backgroundVideo;

  final Color focusColor;

  final Color primaryTextColor;

  final Color secondaryTextColor;

  final Color cardColor;

  final Color focusedCardColor;

  const TvThemeData({
    required this.id,
    required this.nameKey,
    required this.backgroundType,
    required this.backgroundColor,
    required this.focusColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.cardColor,
    required this.focusedCardColor,
    this.backgroundImage,
    this.backgroundVideo,
  });
}
