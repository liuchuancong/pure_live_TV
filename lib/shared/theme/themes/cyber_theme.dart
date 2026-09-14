import '../tv_theme_data.dart';
import 'package:flutter/material.dart';

const cyberTvTheme = TvThemeData(
  id: 'cyber',

  name: '赛博朋克',

  backgroundType: TvBackgroundType.image,

  backgroundImage: 'assets/backgrounds/cyber.jpg',

  backgroundColor: Colors.black,

  focusColor: Color.fromARGB(255, 42, 211, 154),

  primaryTextColor: Colors.white,

  secondaryTextColor: Color(0xffAAFFE8),

  cardColor: Color(0x99202020),

  focusedCardColor: Colors.white,
);
