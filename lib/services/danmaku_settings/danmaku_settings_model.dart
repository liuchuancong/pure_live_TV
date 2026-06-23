import 'package:freezed_annotation/freezed_annotation.dart';

part 'danmaku_settings_model.freezed.dart';
part 'danmaku_settings_model.g.dart';

@freezed
abstract class DanmakuSettingsModel with _$DanmakuSettingsModel {
  const factory DanmakuSettingsModel({
    @Default(false) bool hideDanmaku,
    @Default(0.0) double danmakuTopArea,
    @Default(1.0) double danmakuArea,
    @Default(0.5) double danmakuBottomArea,
    @Default(8.0) double danmakuSpeed,
    @Default(16.0) double danmakuFontSize,
    @Default(4.0) double danmakuFontBorder,
    @Default(1.0) double danmakuOpacity,
    @Default(true) bool enableDanmakuDisplay,
    @Default(true) bool enableDanmakuStroke,
    @Default(60) int danmakuFps,
    @Default('Default') String danmakuFontFamilyName,
  }) = _DanmakuSettingsModel;

  factory DanmakuSettingsModel.fromJson(Map<String, dynamic> json) => _$DanmakuSettingsModelFromJson(json);
}
