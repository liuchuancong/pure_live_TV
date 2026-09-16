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

  /// Whether this is a light palette (bright background, dark text).
  bool get isLight => backgroundColor.computeLuminance() > 0.5;

  /// Text and icon colour for content drawn on [focusedCardColor].
  ///
  /// Most presets focus a card onto white while the coffee/amber/mint/forest/…
  /// ones focus onto a dark shade, so the pairing cannot be hard-coded — and the
  /// old rule (`focused ? backgroundColor : primaryTextColor`) painted near-white
  /// text on the white focused card of every light preset.
  Color get onFocusedCard =>
      focusedCardColor.computeLuminance() > 0.5 ? const Color(0xFF101014) : Colors.white;

  /// Muted companion of [onFocusedCard], for subtitles on a focused card.
  Color get onFocusedCardSecondary => onFocusedCard.withValues(alpha: 0.7);

  /// Subtle fill for a row that is neither selected nor focused.
  ///
  /// Derived from [primaryTextColor] rather than a white/black constant so one
  /// panel looks right on a dark palette and on a light one.
  Color get subtleRowFill => primaryTextColor.withValues(alpha: 0.06);
}
