import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_settings_model.freezed.dart';
part 'player_settings_model.g.dart';

/// 与 pure_live 的播放器设置字段全量对齐：
/// windowsPipAlwaysOnTop / enableRtxVsr / portrait*（竖屏适配）为
/// Windows 或竖屏场景独占，TV 无 UI 也不消费，
/// 仅保留在模型中使备份导出/导入与 pure_live 双向兼容。
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
