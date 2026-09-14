import '../tv_theme_data.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

final animeTvTheme = TvThemeData(
  id: 'anime',

  name: i18n('ui_anime'),

  backgroundType: TvBackgroundType.image,

  backgroundImage: 'assets/backgrounds/anime.jpg',

  backgroundColor: Colors.black,

  focusColor: Color(0xffFF66CC),

  primaryTextColor: Colors.white,

  secondaryTextColor: Color(0xffFFD6F2),

  cardColor: Color(0x88222222),

  focusedCardColor: Colors.white,
);
