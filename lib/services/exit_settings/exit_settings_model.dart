import 'package:freezed_annotation/freezed_annotation.dart';
part 'exit_settings_model.freezed.dart';
part 'exit_settings_model.g.dart';

@freezed
abstract class ExitSettingsModel with _$ExitSettingsModel {
  const factory ExitSettingsModel({
    @Default(false) bool dontAskExit,
    @Default('') String exitChoose,
    @Default(120) int autoShutDownTime,
    @Default(false) bool enableAutoShutDownTime,
  }) = _ExitSettingsModel;

  factory ExitSettingsModel.fromJson(Map<String, dynamic> json) => _$ExitSettingsModelFromJson(json);
}
