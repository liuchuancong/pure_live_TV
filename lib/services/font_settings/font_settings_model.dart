import 'package:freezed_annotation/freezed_annotation.dart';

part 'font_settings_model.freezed.dart';
part 'font_settings_model.g.dart';

@freezed
abstract class FontSettingsModel with _$FontSettingsModel {
  const factory FontSettingsModel({
    @Default(1.0) double textScaleFactor,
    @Default(12.0) double fontSizeBodySmall,
    @Default(13.0) double fontSizeBodyMedium,
    @Default(14.0) double fontSizeBodyLarge,
    @Default(15.0) double fontSizeTitleMedium,
    @Default(20.0) double fontSizeTitleLarge,
    @Default('Default') String fontFamilyName,
  }) = _FontSettingsModel;

  factory FontSettingsModel.fromJson(Map<String, dynamic> json) => _$FontSettingsModelFromJson(json);
}
