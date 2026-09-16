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

  /// Text and icon colour for content drawn on an accent-filled surface
  /// ([focusColor] background).
  ///
  /// Several presets (blue/ocean/lavender) have a *light* accent; painting the
  /// old `focusedCardColor` (white) on top of it gave a ~1.9:1 contrast that
  /// read as blurry, and on light accents it vanished entirely. This picks the
  /// readable partner for whatever the accent's luminance is.
  Color get onFocusColor =>
      focusColor.computeLuminance() > 0.5 ? const Color(0xFF101014) : Colors.white;

  /// Subtle fill for a row that is neither selected nor focused.
  ///
  /// Derived from [primaryTextColor] rather than a white/black constant so one
  /// panel looks right on a dark palette and on a light one.
  Color get subtleRowFill => primaryTextColor.withValues(alpha: 0.06);

  TvThemeData copyWith({
    Color? backgroundColor,
    Color? focusColor,
    Color? primaryTextColor,
    Color? secondaryTextColor,
    Color? cardColor,
    Color? focusedCardColor,
  }) {
    return TvThemeData(
      id: id,
      nameKey: nameKey,
      backgroundType: backgroundType,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      focusColor: focusColor ?? this.focusColor,
      primaryTextColor: primaryTextColor ?? this.primaryTextColor,
      secondaryTextColor: secondaryTextColor ?? this.secondaryTextColor,
      cardColor: cardColor ?? this.cardColor,
      focusedCardColor: focusedCardColor ?? this.focusedCardColor,
      backgroundImage: backgroundImage,
      backgroundVideo: backgroundVideo,
    );
  }

  /// Resolves this preset for the Material 主题模式 and the system dynamic
  /// accent.
  ///
  /// [brightness] comes from the theme-mode setting (跟随系统 already resolves
  /// to dark before this); [accent] is the dynamic-colour primary when
  /// 动态取色 is on. The presets themselves are fixed palettes, so without
  /// this derivation switching the theme mode only ever changed Material
  /// dialogs while every custom widget stayed on the preset's own brightness —
  /// the mode looked like it did nothing.
  TvThemeData resolveFor({Brightness brightness = Brightness.dark, Color? accent}) {
    final Color resolvedAccent = accent ?? focusColor;
    if (brightness == Brightness.dark) {
      return isLight ? _deriveDark(resolvedAccent) : copyWith(focusColor: resolvedAccent);
    }
    return isLight ? copyWith(focusColor: resolvedAccent) : _deriveLight(resolvedAccent);
  }

  /// A light sibling of a dark preset: same accent identity, surfaces lifted
  /// towards a tinted near-white, text dropped to ink.
  TvThemeData _deriveLight(Color accent) {
    return copyWith(
      focusColor: accent,
      backgroundColor: Color.lerp(const Color(0xFFF5F6FA), accent, 0.05)!,
      cardColor: Color.lerp(const Color(0xFFFFFFFF), accent, 0.14)!,
      primaryTextColor: Color.lerp(const Color(0xFF15171C), accent, 0.12)!,
      secondaryTextColor: Color.lerp(const Color(0xFF15171C), accent, 0.35)!.withValues(alpha: 0.8),
      focusedCardColor: accent,
    );
  }

  /// A dark sibling of a light preset.
  TvThemeData _deriveDark(Color accent) {
    return copyWith(
      focusColor: accent,
      backgroundColor: Color.lerp(const Color(0xFF101216), accent, 0.05)!,
      cardColor: Color.lerp(const Color(0xFF1A1D24), accent, 0.12)!,
      primaryTextColor: const Color(0xFFF3F4F6),
      secondaryTextColor: const Color(0xFFF3F4F6).withValues(alpha: 0.65),
      focusedCardColor: Colors.white,
    );
  }
}
