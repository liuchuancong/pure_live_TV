import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/player_settings/player_settings_model.dart';

part 'player_settings_controller.g.dart';

@riverpod
class PlayerSettingsController extends _$PlayerSettingsController {
  static PlayerSettingsController get to => SettingsService.to.player;
  @override
  PlayerSettingsModel build() {
    return PlayerSettingsModel(
      videoFitIndex: HivePrefUtil.getInt('videoFitIndex') ?? 0,
      videoPlayerKey: HivePrefUtil.getString('videoPlayerKey') ?? 'mpv',
      preferResolution: HivePrefUtil.getString('preferResolution') ?? PlayerConsts.resolutions.first,
      preferResolutionCellular: HivePrefUtil.getString('preferResolutionCellular') ?? PlayerConsts.resolutions.first,
      enableCodec: HivePrefUtil.getBool('enableCodec') ?? true,
      playerCompatMode: HivePrefUtil.getBool('playerCompatMode') ?? false,
      customPlayerOutput: HivePrefUtil.getBool('customPlayerOutput') ?? false,
      videoOutputDriver: HivePrefUtil.getString('videoOutputDriver') ?? 'gpu',
      audioOutputDriver: HivePrefUtil.getString('audioOutputDriver') ?? 'auto',
      videoHardwareDecoder: HivePrefUtil.getString('videoHardwareDecoder') ?? 'auto',
      floatPlay: HivePrefUtil.getBool('floatPlay') ?? false,
      audioOnly: HivePrefUtil.getBool('audioOnly') ?? false,
      useHardStopOnExit: HivePrefUtil.getBool('useHardStopOnExit') ?? false,
      windowsPipAlwaysOnTop: HivePrefUtil.getBool('windowsPipAlwaysOnTop') ?? false,
      enableRtxVsr: HivePrefUtil.getBool('enableRtxVsr') ?? false,
      enablePortraitStreamAdaptation: HivePrefUtil.getBool('enablePortraitStreamAdaptation') ?? true,
      portraitAdaptiveHeight: HivePrefUtil.getBool('portraitAdaptiveHeight') ?? true,
      portraitLayoutModeName: HivePrefUtil.getString('portraitLayoutMode') ?? 'balanced',
      portraitFullscreenPolicyName: HivePrefUtil.getString('portraitFullscreenPolicy') ?? '',
      portraitFullscreenDisplayModeName: HivePrefUtil.getString('portraitFullscreenDisplayMode') ?? '',
      portraitPipFollowSource: HivePrefUtil.getBool('portraitPipFollowSource') ?? true,
      portraitDanmakuModeName: HivePrefUtil.getString('portraitDanmakuMode') ?? 'followGlobal',
      rememberPortraitRoomOverride: HivePrefUtil.getBool('rememberPortraitRoomOverride') ?? true,
      showPortraitDiagnostics: HivePrefUtil.getBool('showPortraitDiagnostics') ?? false,
      portraitRoomOverrides: HivePrefUtil.getObject('portraitRoomOverrides', (json) => (json as Map).map((k, v) => MapEntry(k.toString(), v.toString()))) ?? {},
    );
  }

  void updateSettings(PlayerSettingsModel newModel) {
    state = newModel;
    HivePrefUtil.setInt('videoFitIndex', newModel.videoFitIndex);
    HivePrefUtil.setString('videoPlayerKey', newModel.videoPlayerKey);
    HivePrefUtil.setString('preferResolution', newModel.preferResolution);
    HivePrefUtil.setString('preferResolutionCellular', newModel.preferResolutionCellular);
    HivePrefUtil.setBool('enableCodec', newModel.enableCodec);
    HivePrefUtil.setBool('playerCompatMode', newModel.playerCompatMode);
    HivePrefUtil.setBool('customPlayerOutput', newModel.customPlayerOutput);
    HivePrefUtil.setString('videoOutputDriver', newModel.videoOutputDriver);
    HivePrefUtil.setString('audioOutputDriver', newModel.audioOutputDriver);
    HivePrefUtil.setString('videoHardwareDecoder', newModel.videoHardwareDecoder);
    HivePrefUtil.setBool('floatPlay', newModel.floatPlay);
    HivePrefUtil.setBool('audioOnly', newModel.audioOnly);
    HivePrefUtil.setBool('useHardStopOnExit', newModel.useHardStopOnExit);
    HivePrefUtil.setBool('windowsPipAlwaysOnTop', newModel.windowsPipAlwaysOnTop);
    HivePrefUtil.setBool('enableRtxVsr', newModel.enableRtxVsr);
    HivePrefUtil.setBool('enablePortraitStreamAdaptation', newModel.enablePortraitStreamAdaptation);
    HivePrefUtil.setBool('portraitAdaptiveHeight', newModel.portraitAdaptiveHeight);
    HivePrefUtil.setString('portraitLayoutMode', newModel.portraitLayoutModeName);
    HivePrefUtil.setString('portraitFullscreenPolicy', newModel.portraitFullscreenPolicyName);
    HivePrefUtil.setString('portraitFullscreenDisplayMode', newModel.portraitFullscreenDisplayModeName);
    HivePrefUtil.setBool('portraitPipFollowSource', newModel.portraitPipFollowSource);
    HivePrefUtil.setString('portraitDanmakuMode', newModel.portraitDanmakuModeName);
    HivePrefUtil.setBool('rememberPortraitRoomOverride', newModel.rememberPortraitRoomOverride);
    HivePrefUtil.setBool('showPortraitDiagnostics', newModel.showPortraitDiagnostics);
    HivePrefUtil.setObject('portraitRoomOverrides', newModel.portraitRoomOverrides);
  }

  void changePreferResolution(String resolution) {
    if (PlayerConsts.resolutions.contains(resolution)) {
      updateSettings(state.copyWith(preferResolution: resolution));
    }
  }

  void changePreferResolutionCellular(String resolution) {
    if (PlayerConsts.resolutions.contains(resolution)) {
      updateSettings(state.copyWith(preferResolutionCellular: resolution));
    }
  }

  void resetMpvPlayerSettings() {
    updateSettings(
      state.copyWith(
        enableCodec: true,
        playerCompatMode: false,
        customPlayerOutput: false,
        videoOutputDriver: 'gpu',
        audioOutputDriver: 'auto',
        videoHardwareDecoder: 'auto',
        preferResolution: PlayerConsts.resolutions.first,
        preferResolutionCellular: PlayerConsts.resolutions.first,
        useHardStopOnExit: false,
      ),
    );
  }

  void importFromJson(Map<String, dynamic> json) {
    updateSettings(PlayerSettingsModel.fromJson(json));
  }

  Map<String, dynamic> toJson() {
    return state.toJson();
  }
}
