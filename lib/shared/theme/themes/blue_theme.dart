import '../tv_theme_data.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

final blueTvTheme = TvThemeData(
  id: 'blue',

  name: i18n('ui_tech_blue'),

  backgroundType: TvBackgroundType.image,

  backgroundImage: 'assets/backgrounds/blue.jpg',

  backgroundColor: Colors.black,

  focusColor: Color(0xff00D4FF),

  primaryTextColor: Colors.white,

  secondaryTextColor: Color(0xffD9F7FF),

  cardColor: Color(0x991A1A1A),

  focusedCardColor: Colors.white,
);
