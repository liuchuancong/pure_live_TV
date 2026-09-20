import 'package:flutter/material.dart';
import 'package:pure_live/shared/utils/color_converter.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'theme_settings_model.freezed.dart';
part 'theme_settings_model.g.dart';

@freezed
abstract class ThemeSettingsModel with _$ThemeSettingsModel {
  const factory ThemeSettingsModel({
    @Default("System") String themeModeName,
    @Default(false) bool enableDynamicTheme,

    // Uses the shared HexColorConverter.
    @HexColorConverter() @Default(Colors.blue) Color themeColor,

    @Default("简体中文") String languageName,
    // Grid gaps are stored directly in design pixels (32 = the historical
    // default look); `spacingDirectV2` marks a value already migrated from the
    // old offset semantics (stored 6 + a hidden 26 base).
    @Default(6.0) double crossAxisSpacing,
    @Default(6.0) double mainAxisSpacing,
    @Default(false) bool spacingDirectV2,
    @Default("default") String loadingStyle,
    @HexColorConverter() Color? loadingStyleColor,

    // Dense room layout: how many room-card grid columns the landscape layout
    // shows — 4 = standard, 6 = dense, 8 = extra dense.
    @Default(4) int denseRoomLayout,
  }) = _ThemeSettingsModel;

  factory ThemeSettingsModel.fromJson(Map<String, dynamic> json) => _$ThemeSettingsModelFromJson(json);
}
