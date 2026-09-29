import '../tv_theme_data.dart';
import 'package:flutter/material.dart';

/// Additional presets, designed as whole palettes rather than accent swaps:
/// every one carries its own base surface, card tone and accent, so switching
/// themes visibly restyles the app (the theme supplies the page background
/// whenever no background is configured in the background settings).
///
/// Colour families first, then three light presets for a bright room.

// ---------------------------------------------------------------------------
// Deep, tinted dark palettes
// ---------------------------------------------------------------------------

const TvThemeData oceanTvTheme = TvThemeData(
  id: 'ocean',
  nameKey: 'tv_theme_ocean',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff06121C),
  focusColor: Color(0xff38BDF8),
  primaryTextColor: Colors.white,
  secondaryTextColor: Colors.white,
  cardColor: Color(0xff0E2233),
  focusedCardColor: Colors.white,
);

const TvThemeData lavenderTvTheme = TvThemeData(
  id: 'lavender',
  nameKey: 'tv_theme_lavender',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff131024),
  focusColor: Color(0xff818CF8),
  primaryTextColor: Colors.white,
  secondaryTextColor: Colors.white,
  cardColor: Color(0xff1F1B38),
  focusedCardColor: Colors.white,
);

const TvThemeData coffeeTvTheme = TvThemeData(
  id: 'coffee',
  nameKey: 'tv_theme_coffee',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff17110D),
  focusColor: Color(0xffC08457),
  primaryTextColor: Color(0xffF5EDE4),
  secondaryTextColor: Colors.white,
  cardColor: Color(0xff271C14),
  focusedCardColor: Color(0xff1B120C),
);

const TvThemeData amberTvTheme = TvThemeData(
  id: 'amber',
  nameKey: 'tv_theme_amber',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff1A1408),
  focusColor: Color(0xffFFB300),
  primaryTextColor: Color(0xffFDF6E7),
  secondaryTextColor: Colors.white,
  cardColor: Color(0xff2A2110),
  focusedCardColor: Color(0xff1F1706),
);

const TvThemeData violetTvTheme = TvThemeData(
  id: 'violet',
  nameKey: 'tv_theme_violet',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff140F1F),
  focusColor: Color(0xffA855F7),
  primaryTextColor: Colors.white,
  secondaryTextColor: Colors.white,
  cardColor: Color(0xff221A33),
  focusedCardColor: Colors.white,
);

const TvThemeData cherryTvTheme = TvThemeData(
  id: 'cherry',
  nameKey: 'tv_theme_cherry',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff1A0F14),
  focusColor: Color(0xffFF4D6D),
  primaryTextColor: Color(0xffFDF2F4),
  secondaryTextColor: Colors.white,
  cardColor: Color(0xff2C1820),
  focusedCardColor: Color(0xff1F0D12),
);

const TvThemeData mintTvTheme = TvThemeData(
  id: 'mint',
  nameKey: 'tv_theme_mint',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff0C1717),
  focusColor: Color(0xff2DD4BF),
  primaryTextColor: Color(0xffF0FBFA),
  secondaryTextColor: Colors.white,
  cardColor: Color(0xff142625),
  focusedCardColor: Color(0xff082020),
);

const TvThemeData sunsetTvTheme = TvThemeData(
  id: 'sunset',
  nameKey: 'tv_theme_sunset',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff1A1008),
  focusColor: Color(0xffFF7A45),
  primaryTextColor: Color(0xffFDF3EC),
  secondaryTextColor: Colors.white,
  cardColor: Color(0xff2C1C12),
  focusedCardColor: Color(0xff1F1109),
);

const TvThemeData forestTvTheme = TvThemeData(
  id: 'forest',
  nameKey: 'tv_theme_forest',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff0E160C),
  focusColor: Color(0xff4CAF50),
  primaryTextColor: Color(0xffF2F8F0),
  secondaryTextColor: Colors.white,
  cardColor: Color(0xff182514),
  focusedCardColor: Color(0xff0B1B0B),
);

const TvThemeData roseTvTheme = TvThemeData(
  id: 'rose',
  nameKey: 'tv_theme_rose',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff1A0F16),
  focusColor: Color(0xffF472B6),
  primaryTextColor: Color(0xffFDF2F8),
  secondaryTextColor: Colors.white,
  cardColor: Color(0xff2A1822),
  focusedCardColor: Color(0xff1F0E18),
);

const TvThemeData graphiteTvTheme = TvThemeData(
  id: 'graphite',
  nameKey: 'tv_theme_graphite',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff0E0E0E),
  focusColor: Color(0xff90A4AE),
  primaryTextColor: Color(0xffF2F4F5),
  secondaryTextColor: Colors.white,
  cardColor: Color(0xff1C1C1C),
  focusedCardColor: Color(0xff0A0A0A),
);

const TvThemeData warmLightTvTheme = TvThemeData(
  id: 'warm_light',
  nameKey: 'tv_theme_warm_light',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xffF8F4ED),
  focusColor: Color(0xffC2703A),
  primaryTextColor: Color(0xff241E17),
  secondaryTextColor: Colors.white,
  cardColor: Color(0xffFFFFFF),
  focusedCardColor: Color(0xffFFFFFF),
);

const TvThemeData mintLightTvTheme = TvThemeData(
  id: 'mint_light',
  nameKey: 'tv_theme_mint_light',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xffEDF7F5),
  focusColor: Color(0xff0E9F8C),
  primaryTextColor: Color(0xff16211F),
  secondaryTextColor: Colors.white,
  cardColor: Color(0xffFFFFFF),
  focusedCardColor: Color(0xffFFFFFF),
);

/// Presets appended after the original four.
const List<TvThemeData> extraTvThemes = <TvThemeData>[
  oceanTvTheme,
  lavenderTvTheme,
  coffeeTvTheme,
  amberTvTheme,
  violetTvTheme,
  cherryTvTheme,
  mintTvTheme,
  sunsetTvTheme,
  forestTvTheme,
  roseTvTheme,
  graphiteTvTheme,
  warmLightTvTheme,
  mintLightTvTheme,
];
