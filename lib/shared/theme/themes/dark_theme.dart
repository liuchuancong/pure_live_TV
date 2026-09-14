import '../tv_theme_data.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

final darkTvTheme = TvThemeData(
  id: 'dark',

  name: i18n('ui_dark_by_default'),

  backgroundType: TvBackgroundType.color,

  backgroundColor: Color(0xff121212),

  focusColor: Color(0xff00A1FF),

  primaryTextColor: Colors.white,

  secondaryTextColor: Color(0xffBDBDBD),

  cardColor: Color(0xff1F1F1F),

  focusedCardColor: Colors.white,
);
