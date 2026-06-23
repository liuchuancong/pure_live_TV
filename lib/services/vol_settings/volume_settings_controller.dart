import 'dart:io';
import 'volume_settings_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'volume_settings_controller.g.dart';

@riverpod
class VolumeSettingsController extends _$VolumeSettingsController {
  static VolumeSettingsController get to => SettingsService.to.volume;
  @override
  VolumeSettingsModel build() {
    return VolumeSettingsModel(
      defaultMobileVolume: HivePrefUtil.getDouble('defaultMobileVolume') ?? 0.5,
      defaultDesktopVolume: HivePrefUtil.getDouble('defaultDesktopVolume') ?? 1.0,
      globalVolumeMute: HivePrefUtil.getBool('globalVolumeMute') ?? false,
      roomVolumes:
          HivePrefUtil.getObject(
            'roomVolumes',
            (json) => (json as Map).map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
          ) ??
          {},
    );
  }

  void setRoomVolume(String roomId, double volume) {
    final volumes = Map<String, double>.from(state.roomVolumes);
    volumes[roomId] = volume.clamp(0.0, 1.0);
    state = state.copyWith(roomVolumes: volumes);
    _persist();
  }

  double get currentPlatformDefaultVolume =>
      (Platform.isAndroid || Platform.isIOS) ? state.defaultMobileVolume : state.defaultDesktopVolume;

  void setCurrentPlatformDefaultVolume(double volume) {
    final v = volume.clamp(0.0, 1.0);
    state = (Platform.isAndroid || Platform.isIOS)
        ? state.copyWith(defaultMobileVolume: v)
        : state.copyWith(defaultDesktopVolume: v);
    _persist();
  }

  void resetVolumeToDefault() {
    state = const VolumeSettingsModel();
    _persist();
  }

  void _persist() {
    HivePrefUtil.setDouble('defaultMobileVolume', state.defaultMobileVolume);
    HivePrefUtil.setDouble('defaultDesktopVolume', state.defaultDesktopVolume);
    HivePrefUtil.setBool('globalVolumeMute', state.globalVolumeMute);
    HivePrefUtil.setObject('roomVolumes', state.roomVolumes);
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = VolumeSettingsModel.fromJson(json);
    _persist();
  }
}
