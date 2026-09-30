import 'package:freezed_annotation/freezed_annotation.dart';

part 'font_settings_model.freezed.dart';
part 'font_settings_model.g.dart';

@freezed
abstract class FontSettingsModel with _$FontSettingsModel {
  const factory FontSettingsModel({@Default(1.0) double textScaleFactor, @Default('Default') String fontFamilyName}) =
      _FontSettingsModel;

  factory FontSettingsModel.fromJson(Map<String, dynamic> json) => _$FontSettingsModelFromJson(json);
}
