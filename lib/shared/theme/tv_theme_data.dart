import 'package:flutter/material.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

enum TvBackgroundType { color, image, video }

class TvThemeData {
  final String id;

  /// Translation key of the display name, resolved on every read so the
  /// list follows the active language.
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

  /// Text/icon colour on [focusedCardColor]; varies per preset since most
  /// focus onto white but a few onto a dark shade.
  Color get onFocusedCard => readableOn(focusedCardColor);

  /// Muted companion of [onFocusedCard], for subtitles on a focused card.
  Color get onFocusedCardSecondary => onFocusedCard.withValues(alpha: 0.7);

  /// Text/icon colour on an accent-filled surface (focused/selected rows, tabs).
  Color get onFocusColor => readableOn(focusColor);

  /// Text/icon colour on the faded accent fill (focused, not selected). The
  /// contrast target is the blended colour, not the accent itself.
  Color get onFadedFocusColor => backgroundColor;

  /// The two candidate inks content is drawn in: near-black and white.
  static const Color _ink = Color(0xFF101014);
  static const Color _paper = Color(0xFFFFFFFF);

  /// Whichever of ink and paper contrasts more with [background]. Contrast
  /// comparison (not a luminance threshold) guarantees ~4.3:1 on any preset.
  static Color readableOn(Color background) =>
      _contrastOf(_paper, background) >= _contrastOf(_ink, background) ? _paper : _ink;

  /// WCAG relative-luminance contrast ratio between two colours.
  static double contrastRatio(Color a, Color b) => _contrastOf(a, b);

  static double _contrastOf(Color a, Color b) {
    final double la = a.computeLuminance();
    final double lb = b.computeLuminance();
    final double lighter = la > lb ? la : lb;
    final double darker = la > lb ? lb : la;
    return (lighter + 0.05) / (darker + 0.05);
  }

  /// Subtle fill for a row that is neither selected nor focused.
  ///
  /// Derived from [primaryTextColor] rather than a white/black constant so one
  /// panel looks right on a dark palette and on a light one.
  Color get subtleRowFill => primaryTextColor.withValues(alpha: 0.06);

  /// Background of an idle (unfocused, unselected) button.
  ///
  /// The seeded containers already carry the preset's tint at the right tone,
  /// so the button simply sits on the card colour (rendered translucent by the
  /// button itself). The old extra lerp towards the accent is what produced
  /// the muddy grey-purple pills on desaturated presets.
  Color get buttonSurface => cardColor;

  /// This preset with legacy hard-coded focus surfaces rewritten.
  ///
  /// Most presets declared `focusedCardColor: Colors.white` — on a dark palette
  /// the focused input field or card flashed pure white regardless of the
  /// theme's accent (and the three light presets focused onto the same white
  /// their idle card already had, so focus was invisible). The white is now a
  /// rung of the preset's own hue ladder (a lit-up tinted surface), and
  /// [onFocusedCard] keeps the text readable on it.
  TvThemeData normalized() {
    if (focusedCardColor != const Color(0xFFFFFFFF)) {
      return this;
    }
    return copyWith(focusedCardColor: _tinted(focusColor, isLight ? 0.88 : 0.20, isLight ? 0.45 : 0.48));
  }

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

  /// Resolves this preset for the Material theme mode.
  ///
  /// [brightness] comes from the theme-mode setting (follow system already resolves
  /// to dark before this).
  ///
  /// A preset whose own brightness already matches the mode keeps its curated
  /// surfaces (those palettes were tuned by hand and look right). The *other*
  /// mode is derived with [_deriveDark] / [_deriveLight]: a hue-tinted ladder
  /// built in HSL, in the spirit of the polished TV launchers — deep *coloured*
  /// backgrounds, not Material's grey tone-6 neutrals, which read as mud next
  /// to a wallpaper.
  TvThemeData resolveFor({Brightness brightness = Brightness.dark}) {
    final Color seed = focusColor;
    final bool nativeMode = isLight == (brightness == Brightness.light);
    if (nativeMode) {
      return copyWith(focusColor: seed).normalized();
    }
    return brightness == Brightness.dark ? _deriveDark(seed) : _deriveLight(seed);
  }

  // ---------------------------------------------------------------------------
  // HSL colour ladder
  //
  // One idea, applied everywhere: take the seed's hue, then place each role at
  // a fixed saturation/lightness tuned for TV (big surfaces, wallpaper behind
  // translucent panels, white ink on accent fills). Because every colour is
  // the same hue at a different depth, a palette can never fight itself —
  // which is what both the legacy white lerps and Material's neutral tones
  // got wrong on this app.
  // ---------------------------------------------------------------------------

  /// The seed's hue re-saturated to a lively but TV-safe level.
  ///
  /// Preset accents are hand-picked and used as-is; this is for the *derived*
  /// sibling mode, where the accent must stay recognizably the preset's
  /// colour while white ink on it keeps ≈4:1. Lightness lands mid-scale so
  /// the same value works on a dark and a light page.
  static Color _vividAccent(Color seed) {
    final HSLColor hsl = HSLColor.fromColor(seed);
    return HSLColor.fromAHSL(1, hsl.hue, hsl.saturation.clamp(0.55, 0.95), 0.52).toColor();
  }

  /// A surface of the seed's hue at the given depth.
  ///
  /// [lightness] picks the rung of the ladder; [saturation] defaults to a
  /// gentle tint (deep surfaces stay subtly coloured, never neon, never grey).
  static Color _tinted(Color seed, double lightness, [double? saturation]) {
    final HSLColor hsl = HSLColor.fromColor(seed);
    final double s = (saturation ?? hsl.saturation).clamp(0.22, 0.42);
    return HSLColor.fromAHSL(1, hsl.hue, s, lightness).toColor();
  }

  /// A dark sibling of a light preset: the seed hue pushed down into a deep,
  /// *coloured* base — the look of a curated dark theme, generated.
  TvThemeData _deriveDark(Color accent) {
    return copyWith(
      focusColor: _vividAccent(accent),
      backgroundColor: _tinted(accent, 0.055),
      cardColor: _tinted(accent, 0.105),
      primaryTextColor: _tinted(accent, 0.96, 0.10),
      secondaryTextColor: _tinted(accent, 0.96, 0.10),
      // A lit-up rung of the ladder: clearly above the card, unmistakably the
      // preset's colour, and dark enough that [onFocusedCard] resolves to
      // white ink.
      focusedCardColor: _tinted(accent, 0.20, 0.48),
    );
  }

  /// A light sibling of a dark preset: the seed hue lifted into warm paper
  /// tones — white-ish, but carrying the preset's colour temperature instead
  /// of flat studio white.
  TvThemeData _deriveLight(Color accent) {
    return copyWith(
      focusColor: _vividAccent(accent),
      backgroundColor: _tinted(accent, 0.955, 0.30),
      cardColor: _tinted(accent, 0.99, 0.22),
      primaryTextColor: _tinted(accent, 0.13, 0.28),
      secondaryTextColor: _tinted(accent, 0.13, 0.28),
      // A pale wash of the accent; [onFocusedCard] picks dark ink on it.
      focusedCardColor: _tinted(accent, 0.88, 0.45),
    );
  }
}
