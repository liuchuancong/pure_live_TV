import '../tv_theme_data.dart';
import 'package:flutter/material.dart';

/// Additional colour presets.
///
/// These are background-colour themes: the app renders the page background from
/// the background settings, and no per-theme background artwork is shipped, so
/// a preset only has to supply a coherent accent plus readable text colours.
const TvThemeData amberTvTheme = TvThemeData(
  id: 'amber',
  nameKey: 'tv_theme_amber',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff121212),
  focusColor: Color(0xffFFB300),
  primaryTextColor: Colors.white,
  secondaryTextColor: Color(0xffE0C89A),
  cardColor: Color(0xff231C10),
  focusedCardColor: Colors.white,
);

const TvThemeData violetTvTheme = TvThemeData(
  id: 'violet',
  nameKey: 'tv_theme_violet',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff121016),
  focusColor: Color(0xffA855F7),
  primaryTextColor: Colors.white,
  secondaryTextColor: Color(0xffD8C7F0),
  cardColor: Color(0xff1E1830),
  focusedCardColor: Colors.white,
);

const TvThemeData cherryTvTheme = TvThemeData(
  id: 'cherry',
  nameKey: 'tv_theme_cherry',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff140F12),
  focusColor: Color(0xffFF4D6D),
  primaryTextColor: Colors.white,
  secondaryTextColor: Color(0xffF3C2CC),
  cardColor: Color(0xff2A151C),
  focusedCardColor: Colors.white,
);

const TvThemeData mintTvTheme = TvThemeData(
  id: 'mint',
  nameKey: 'tv_theme_mint',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff0F1414),
  focusColor: Color(0xff2DD4BF),
  primaryTextColor: Colors.white,
  secondaryTextColor: Color(0xffB6E8E0),
  cardColor: Color(0xff13211F),
  focusedCardColor: Colors.white,
);

const TvThemeData sunsetTvTheme = TvThemeData(
  id: 'sunset',
  nameKey: 'tv_theme_sunset',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff14100E),
  focusColor: Color(0xffFF7A45),
  primaryTextColor: Colors.white,
  secondaryTextColor: Color(0xffF0C6AE),
  cardColor: Color(0xff271812),
  focusedCardColor: Colors.white,
);

const TvThemeData forestTvTheme = TvThemeData(
  id: 'forest',
  nameKey: 'tv_theme_forest',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff101410),
  focusColor: Color(0xff4CAF50),
  primaryTextColor: Colors.white,
  secondaryTextColor: Color(0xffC2E0C4),
  cardColor: Color(0xff16210F),
  focusedCardColor: Colors.white,
);

const TvThemeData roseTvTheme = TvThemeData(
  id: 'rose',
  nameKey: 'tv_theme_rose',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff141013),
  focusColor: Color(0xffF472B6),
  primaryTextColor: Colors.white,
  secondaryTextColor: Color(0xffEBC4DA),
  cardColor: Color(0xff251823),
  focusedCardColor: Colors.white,
);

const TvThemeData graphiteTvTheme = TvThemeData(
  id: 'graphite',
  nameKey: 'tv_theme_graphite',
  backgroundType: TvBackgroundType.color,
  backgroundColor: Color(0xff0E0E0E),
  focusColor: Color(0xff90A4AE),
  primaryTextColor: Colors.white,
  secondaryTextColor: Color(0xffC7CDD1),
  cardColor: Color(0xff1C1C1C),
  focusedCardColor: Colors.white,
);

/// Presets appended after the original four.
const List<TvThemeData> extraTvThemes = <TvThemeData>[
  amberTvTheme,
  violetTvTheme,
  cherryTvTheme,
  mintTvTheme,
  sunsetTvTheme,
  forestTvTheme,
  roseTvTheme,
  graphiteTvTheme,
];
