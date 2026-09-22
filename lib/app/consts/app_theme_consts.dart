import 'package:flutter/material.dart';

class AppThemeConsts {
  AppThemeConsts._();

  // theme mode mapping
  static const Map<String, ThemeMode> themeModes = {
    "System": ThemeMode.system,
    "Dark": ThemeMode.dark,
    "Light": ThemeMode.light,
  };
  static const Map<String, String> themeModeI18n = {
    "System": "theme_mode_system",
    "Dark": "theme_mode_dark",
    "Light": "theme_mode_light",
  };

  // language mapping
  static const Map<String, Locale> languages = {"English": Locale('en'), "简体中文": Locale('zh')};

  // video fit modes
  static const List<BoxFit> videoFitList = [
    BoxFit.contain,
    BoxFit.cover,
    BoxFit.fill,
    BoxFit.fitHeight,
    BoxFit.fitWidth,
    BoxFit.scaleDown,
  ];

  /// key replaces the old desc field
  static const List<Map<String, dynamic>> videoFitType = [
    {'attr': BoxFit.contain, 'desc': 'video_fit_default'},
    {'attr': BoxFit.cover, 'desc': 'video_fit_crop_center'},
    {'attr': BoxFit.fill, 'desc': 'video_fit_fill_screen'},
    {'attr': BoxFit.fitHeight, 'desc': 'video_fit_fit_height'},
    {'attr': BoxFit.fitWidth, 'desc': 'video_fit_fit_width'},
    {'attr': BoxFit.scaleDown, 'desc': 'video_fit_scale_down'},
  ];

  static const Map<String, Color> themeColors = {
    "Crimson": Color.fromARGB(255, 220, 20, 60),
    "Orange": Colors.orange,
    "Chrome": Color.fromARGB(255, 230, 184, 0),
    "Grass": Colors.lightGreen,
    "Teal": Colors.teal,
    "SeaFoam": Color.fromARGB(255, 112, 193, 207),
    "Ice": Color.fromARGB(255, 115, 155, 208),
    "Blue": Colors.blue,
    "Indigo": Colors.indigo,
    "Violet": Colors.deepPurple,
    "Primary": Color(0xFF6200EE),
    "Orchid": Color.fromARGB(255, 218, 112, 214),
    "Variant": Color(0xFF3700B3),
    "Secondary": Color(0xFF03DAC6),
  };
}
