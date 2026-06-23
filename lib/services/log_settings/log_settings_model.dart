import 'package:freezed_annotation/freezed_annotation.dart';

part 'log_settings_model.freezed.dart';
part 'log_settings_model.g.dart';

@freezed
abstract class LogSettingsModel with _$LogSettingsModel {
  const factory LogSettingsModel({
    @Default('') String serverAddress,
    @Default(7890) int serverPort,
    @Default(false) bool storedEnableLog,
  }) = _LogSettingsModel;

  factory LogSettingsModel.fromJson(Map<String, dynamic> json) => _$LogSettingsModelFromJson(json);
}
