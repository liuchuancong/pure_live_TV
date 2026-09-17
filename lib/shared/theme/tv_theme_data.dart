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
  Color get onFocusedCard => readableOn(focusedCardColor);

  /// Muted companion of [onFocusedCard], for subtitles on a focused card.
  Color get onFocusedCardSecondary => onFocusedCard.withValues(alpha: 0.7);

  /// Text and icon colour for content drawn on an accent-filled surface
  /// ([focusColor] background) — a focused/selected button, tab, row or player pill.
  Color get onFocusColor => readableOn(focusColor);

  /// Text and icon colour for content on the *faded* accent fill — the
  /// "focused but not selected" state that paints [focusColor] at 50% over the
  /// page background.
  ///
  /// The text must contrast with the **blended** colour, not the accent itself:
  /// for a mid-blue accent the blend is a darker blue where white would sink in.
  Color get onFadedFocusColor => readableOn(Color.lerp(backgroundColor, focusColor, 0.5)!);

  /// The two candidate inks content is drawn in: near-black and white.
  static const Color _ink = Color(0xFF101014);
  static const Color _paper = Color(0xFFFFFFFF);

  /// The readable partner for content drawn on [background]: whichever of ink and
  /// paper contrasts *more* with it.
  ///
  /// A luminance threshold is not the same thing as contrast, and that difference is
  /// where unreadable content came from: 深色's accent (#00A1FF) sat below the old
  /// threshold so white was chosen, giving 2.8:1, and 赛博's accent gave 1.9:1 — the
  /// focused/selected label was washed out in **both** theme modes. Comparing contrast
  /// ratios guarantees at least ~4.3:1 against any background.
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

  /// Moves [accent] towards [towards] until it contrasts with [background] by at
  /// least [minimum].
  ///
  /// A fixed nudge is not enough: a pale amber needs a much bigger step than a mid
  /// blue. The loop is bounded (1/16 steps) so it always terminates and never turns a
  /// colour into a different one.
  static Color _accentVisibleOn(Color accent, Color background, Color towards, double minimum) {
    Color result = accent;
    for (int step = 0; step < 16; step++) {
      if (_contrastOf(result, background) >= minimum) return result;
      result = Color.lerp(result, towards, 0.12)!;
    }
    return result;
  }

  /// A light sibling of a dark preset: same accent identity, surfaces lifted
  /// towards a tinted near-white, text dropped to ink.
  ///
  /// Text colours are opaque on purpose: a translucent secondary colour composites
  /// with whatever happens to be behind it (card, page, wallpaper), so its contrast
  /// is not the contrast the palette promises. The accent is darkened until the focus
  /// ring and accent-coloured labels stay visible on a light page — the raw preset
  /// accent is tuned for a dark one and can sit at ~2.5:1 here.
  TvThemeData _deriveLight(Color accent) {
    final Color background = Color.lerp(const Color(0xFFF5F6FA), accent, 0.05)!;
    final Color readableAccent = _accentVisibleOn(accent, background, const Color(0xFF101014), 3.0);
    return copyWith(
      focusColor: readableAccent,
      backgroundColor: background,
      cardColor: Color.lerp(const Color(0xFFFFFFFF), accent, 0.14)!,
      primaryTextColor: Color.lerp(const Color(0xFF15171C), accent, 0.12)!,
      secondaryTextColor: Color.lerp(const Color(0xFF4A4E57), accent, 0.25)!,
      focusedCardColor: readableAccent,
    );
  }

  /// A dark sibling of a light preset: surfaces dropped towards ink, text lifted.
  ///
  /// The accent is lightened for the same reason: a pale preset accent (amber, mint,
  /// a light blue) disappears on a dark page.
  TvThemeData _deriveDark(Color accent) {
    final Color background = Color.lerp(const Color(0xFF101216), accent, 0.05)!;
    final Color readableAccent = _accentVisibleOn(accent, background, const Color(0xFFFFFFFF), 3.0);
    return copyWith(
      focusColor: readableAccent,
      backgroundColor: background,
      cardColor: Color.lerp(const Color(0xFF1A1D24), accent, 0.12)!,
      primaryTextColor: const Color(0xFFF3F4F6),
      secondaryTextColor: Color.lerp(const Color(0xFFB9BDC6), accent, 0.2)!,
      focusedCardColor: Colors.white,
    );
  }
}
