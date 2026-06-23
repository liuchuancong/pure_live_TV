import 'package:flutter/material.dart';
import 'package:pure_live/utils/color_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_settings_model.freezed.dart';
part 'theme_settings_model.g.dart';

@freezed
abstract class ThemeSettingsModel with _$ThemeSettingsModel {
  const factory ThemeSettingsModel({
    @Default("System") String themeModeName,
    @Default(false) bool enableDynamicTheme,

    // 使用你定义的 HexColorConverter
    @HexColorConverter() @Default(Colors.blue) Color themeColor,

    @Default("简体中文") String languageName,
    @Default(6.0) double crossAxisSpacing,
    @Default(6.0) double mainAxisSpacing,
    @Default("default") String loadingStyle,
    @HexColorConverter() Color? loadingStyleColor,
  }) = _ThemeSettingsModel;

  factory ThemeSettingsModel.fromJson(Map<String, dynamic> json) => _$ThemeSettingsModelFromJson(json);
}
