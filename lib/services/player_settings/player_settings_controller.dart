import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/player/utils/player_consts.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/player_settings/player_settings_model.dart';

part 'player_settings_controller.g.dart';

@riverpod
class PlayerSettingsController extends _$PlayerSettingsController {
  static PlayerSettingsController get to => SettingsService.to.player;

  /// First video fit option; used when a stored index no longer exists.
  static const int defaultVideoFitIndex = 0;

  @override
  PlayerSettingsModel build() {
    return _normalize(
      PlayerSettingsModel(
        videoFitIndex: HivePrefUtil.getInt('videoFitIndex') ?? defaultVideoFitIndex,
        videoPlayerKey: HivePrefUtil.getString('videoPlayerKey') ?? PlayerConsts.defaultKey,
        preferResolution: HivePrefUtil.getString('preferResolution') ?? PlayerConsts.resolutionKeys.first,
        preferResolutionCellular:
            HivePrefUtil.getString('preferResolutionCellular') ?? PlayerConsts.resolutionKeys.first,
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
        portraitRoomOverrides:
            HivePrefUtil.getObject(
              'portraitRoomOverrides',
              (json) => (json as Map).map((k, v) => MapEntry(k.toString(), v.toString())),
            ) ??
            {},
      ),
    );
  }

  /// Repairs values that must stay inside their option lists.
  ///
  /// A stored video fit index from another build would throw while the settings
  /// page maps it to a label, and a resolution stored as a localized label
  /// would stop matching the qualities a site returns after a language change.
  static PlayerSettingsModel _normalize(PlayerSettingsModel model) {
    return model.copyWith(
      videoFitIndex: normalizeVideoFitIndex(model.videoFitIndex),
      preferResolution: PlayerConsts.normalizeResolutionKey(model.preferResolution),
      preferResolutionCellular: PlayerConsts.normalizeResolutionKey(model.preferResolutionCellular),
    );
  }

  static int normalizeVideoFitIndex(int value) {
    final optionCount = AppConsts().videoFitType.length;
    if (optionCount == 0 || value < 0 || value >= optionCount) return defaultVideoFitIndex;
    return value;
  }

  void updateSettings(PlayerSettingsModel newModel) {
    final normalized = _normalize(newModel);
    state = normalized;
    HivePrefUtil.setInt('videoFitIndex', normalized.videoFitIndex);
    HivePrefUtil.setString('videoPlayerKey', normalized.videoPlayerKey);
    HivePrefUtil.setString('preferResolution', normalized.preferResolution);
    HivePrefUtil.setString('preferResolutionCellular', normalized.preferResolutionCellular);
    HivePrefUtil.setBool('enableCodec', normalized.enableCodec);
    HivePrefUtil.setBool('playerCompatMode', normalized.playerCompatMode);
    HivePrefUtil.setBool('customPlayerOutput', normalized.customPlayerOutput);
    HivePrefUtil.setString('videoOutputDriver', normalized.videoOutputDriver);
    HivePrefUtil.setString('audioOutputDriver', normalized.audioOutputDriver);
    HivePrefUtil.setString('videoHardwareDecoder', normalized.videoHardwareDecoder);
    HivePrefUtil.setBool('floatPlay', normalized.floatPlay);
    HivePrefUtil.setBool('audioOnly', normalized.audioOnly);
    HivePrefUtil.setBool('useHardStopOnExit', normalized.useHardStopOnExit);
    HivePrefUtil.setBool('windowsPipAlwaysOnTop', normalized.windowsPipAlwaysOnTop);
    HivePrefUtil.setBool('enableRtxVsr', normalized.enableRtxVsr);
    HivePrefUtil.setBool('enablePortraitStreamAdaptation', normalized.enablePortraitStreamAdaptation);
    HivePrefUtil.setBool('portraitAdaptiveHeight', normalized.portraitAdaptiveHeight);
    HivePrefUtil.setString('portraitLayoutMode', normalized.portraitLayoutModeName);
    HivePrefUtil.setString('portraitFullscreenPolicy', normalized.portraitFullscreenPolicyName);
    HivePrefUtil.setString('portraitFullscreenDisplayMode', normalized.portraitFullscreenDisplayModeName);
    HivePrefUtil.setBool('portraitPipFollowSource', normalized.portraitPipFollowSource);
    HivePrefUtil.setString('portraitDanmakuMode', normalized.portraitDanmakuModeName);
    HivePrefUtil.setBool('rememberPortraitRoomOverride', normalized.rememberPortraitRoomOverride);
    HivePrefUtil.setBool('showPortraitDiagnostics', normalized.showPortraitDiagnostics);
    HivePrefUtil.setObject('portraitRoomOverrides', normalized.portraitRoomOverrides);
  }

  /// Advances the video fit option and returns the new index.
  int? advanceVideoFitIndex() {
    final optionCount = AppConsts().videoFitType.length;
    if (optionCount == 0) return null;
    final next = (normalizeVideoFitIndex(state.videoFitIndex) + 1) % optionCount;
    updateSettings(state.copyWith(videoFitIndex: next));
    return next;
  }

  void changePreferResolution(String resolution) {
    if (PlayerConsts.resolutionKeys.contains(resolution)) {
      updateSettings(state.copyWith(preferResolution: resolution));
    }
  }

  void changePreferResolutionCellular(String resolution) {
    if (PlayerConsts.resolutionKeys.contains(resolution)) {
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
        preferResolution: PlayerConsts.resolutionKeys.first,
        preferResolutionCellular: PlayerConsts.resolutionKeys.first,
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
