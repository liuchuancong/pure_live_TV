import '../tv_theme_data.dart';
import 'package:flutter/material.dart';

const blueTvTheme = TvThemeData(
  id: 'blue',

  nameKey: 'ui_tech_blue',

  // The palette carries its own surface: the theme supplies the page background
  // whenever no background is configured, so the base colour is what makes this
  // theme look different from the others.
  backgroundType: TvBackgroundType.color,

  backgroundColor: Color(0xff0A1526),

  focusColor: Color(0xff00D4FF),

  primaryTextColor: Colors.white,

  secondaryTextColor: Color(0xffA8D8F0),

  cardColor: Color(0xff10233D),

  focusedCardColor: Colors.white,
);
