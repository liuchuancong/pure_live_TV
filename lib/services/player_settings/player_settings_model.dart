import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_settings_model.freezed.dart';
part 'player_settings_model.g.dart';

/// Player settings model.
///
/// Windows-only and portrait-only fields have no UI here and are kept only so
/// backup export/import stays compatible with older backups.
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
    // Windows/竖屏独占（TV 不消费，仅同步保留）
    @Default(false) bool windowsPipAlwaysOnTop,
    @Default(false) bool enableRtxVsr,
    @Default(true) bool enablePortraitStreamAdaptation,
    @Default(true) bool portraitAdaptiveHeight,
    @Default('balanced') String portraitLayoutModeName,
    @Default('') String portraitFullscreenPolicyName,
    @Default('') String portraitFullscreenDisplayModeName,
    @Default(true) bool portraitPipFollowSource,
    @Default('followGlobal') String portraitDanmakuModeName,
    @Default(true) bool rememberPortraitRoomOverride,
    @Default(false) bool showPortraitDiagnostics,
    @Default({}) Map<String, String> portraitRoomOverrides,
  }) = _PlayerSettingsModel;

  factory PlayerSettingsModel.fromJson(Map<String, dynamic> json) => _$PlayerSettingsModelFromJson(json);
}
