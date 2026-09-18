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
  Color get onFadedFocusColor => backgroundColor;

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
  /// their idle card already had, so focus was invisible). The white is now
  /// blended from the card towards the accent, and [onFocusedCard] keeps the
  /// text readable on either.
  TvThemeData normalized() {
    if (focusedCardColor != const Color(0xFFFFFFFF)) {
      return this;
    }
    return copyWith(focusedCardColor: Color.lerp(cardColor, focusColor, isLight ? 0.14 : 0.22)!);
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

  /// Resolves this preset for the Material 主题模式 and the system dynamic
  /// accent.
  ///
  /// [brightness] comes from the theme-mode setting (跟随系统 already resolves
  /// to dark before this); [accent] is the dynamic-colour primary when
  /// 动态取色 is on.
  ///
  /// A preset whose own brightness already matches the mode keeps its curated
  /// surfaces and only re-seeds the accent; the *other* mode is derived from
  /// Material 3's `ColorScheme.fromSeed` over the preset's accent. That tonal
  /// system is the same one the Material ecosystem uses, so every derived
  /// colour comes from the seed hue's tone ladder instead of ad-hoc lerps —
  /// hand-mixed `lerp(white, accent)` surfaces were what made desaturated
  /// presets (graphite, mint) fight themselves with muddy grey-purple cards.
  TvThemeData resolveFor({Brightness brightness = Brightness.dark, Color? accent}) {
    final Color seed = accent ?? focusColor;
    final bool nativeMode = isLight == (brightness == Brightness.light);
    if (nativeMode) {
      return copyWith(focusColor: _focusFillOf(seed)).normalized();
    }
    return brightness == Brightness.dark ? _deriveDark(seed) : _deriveLight(seed);
  }

  /// The accent used for focus fills and rings: the seed's **tone-40 primary**.
  ///
  /// `fromSeed` gives a light scheme a tone-40 primary (saturated, mid-dark)
  /// and a dark scheme a tone-80 primary (pastel). The app's house style draws
  /// white ink on the focus fill, which sinks into a pastel — so both modes
  /// take the tone-40 variant. It is vivid enough to read as the accent,
  /// dark enough for white text (≈4.5:1), and light enough to ring clearly on
  /// a dark page.
  static Color _focusFillOf(Color seed) {
    return ColorScheme.fromSeed(seedColor: seed, brightness: Brightness.light).primary;
  }

  /// A light sibling of a dark preset, derived from Material 3 tonal palettes.
  ///
  /// Every role comes from `fromSeed(seed, light)` so background, cards, focus
  /// surfaces and inks are hues of the same ladder — they cannot clash. The
  /// one deliberate swap is [TvThemeData.focusColor]: it always takes the
  /// tone-40 primary (see [_focusFillOf]) so white button ink and the focus
  /// ring behave identically in both modes.
  TvThemeData _deriveLight(Color accent) {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.light);
    return copyWith(
      focusColor: _focusFillOf(accent),
      backgroundColor: scheme.surface,
      cardColor: scheme.surfaceContainerHigh,
      primaryTextColor: scheme.onSurface,
      secondaryTextColor: scheme.onSurfaceVariant,
      focusedCardColor: scheme.primaryContainer,
    );
  }

  /// A dark sibling of a light preset, derived from Material 3 tonal palettes.
  ///
  /// Same rule as [_deriveLight]: the roles come from `fromSeed(seed, dark)`.
  /// The focus *fill* stays tone-40 (white ink on it, per house style) while
  /// the rest of the scheme uses the ladder's dark tones; a focused row fills
  /// with `primaryContainer` (tone 30, tinted dark) rather than flashing white.
  TvThemeData _deriveDark(Color accent) {
    final ColorScheme scheme = ColorScheme.fromSeed(seedColor: accent, brightness: Brightness.dark);
    return copyWith(
      focusColor: _focusFillOf(accent),
      backgroundColor: scheme.surface,
      cardColor: scheme.surfaceContainerHigh,
      primaryTextColor: scheme.onSurface,
      secondaryTextColor: scheme.onSurfaceVariant,
      focusedCardColor: scheme.primaryContainer,
    );
  }
}
