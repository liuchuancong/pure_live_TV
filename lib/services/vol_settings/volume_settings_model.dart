import 'package:freezed_annotation/freezed_annotation.dart';
// volume_settings_model.dart

part 'volume_settings_model.freezed.dart';
part 'volume_settings_model.g.dart';

@freezed
abstract class VolumeSettingsModel with _$VolumeSettingsModel {
  const factory VolumeSettingsModel({
    @Default(0.5) double defaultMobileVolume,
    @Default(1.0) double defaultDesktopVolume,
    @Default(false) bool globalVolumeMute,
    @Default({}) Map<String, double> roomVolumes,
  }) = _VolumeSettingsModel;

  factory VolumeSettingsModel.fromJson(Map<String, dynamic> json) => _$VolumeSettingsModelFromJson(json);
}
