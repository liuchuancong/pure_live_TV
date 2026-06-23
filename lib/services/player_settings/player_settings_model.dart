import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_settings_model.freezed.dart';
part 'player_settings_model.g.dart';

@freezed
abstract class PlayerSettingsModel with _$PlayerSettingsModel {
  const factory PlayerSettingsModel({
    @Default(0) int videoFitIndex,
    @Default('mpv') String videoPlayerKey,
    @Default('') String preferResolution,
    @Default('') String preferResolutionCellular,
    @Default(true) bool enableCodec,
    @Default(false) bool playerCompatMode,
    @Default(false) bool customPlayerOutput,
    @Default('gpu') String videoOutputDriver,
    @Default('auto') String audioOutputDriver,
    @Default('auto') String videoHardwareDecoder,
    @Default(false) bool floatPlay,
    @Default(false) bool audioOnly,
    @Default(false) bool useHardStopOnExit,
  }) = _PlayerSettingsModel;

  factory PlayerSettingsModel.fromJson(Map<String, dynamic> json) => _$PlayerSettingsModelFromJson(json);
}
