import 'package:pure_live/core/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'video_settings_model.dart';

part 'video_settings_controller.g.dart';

/// opens at (quality, speed, detail-first) and which section the mode lands on.
/// Music is deliberately untouched — this controller is only read from the
/// video surfaces.
@riverpod
class VideoSettingsController extends _$VideoSettingsController {
  static VideoSettingsController get to => SettingsService.to.video;

  /// The speed choices the video player itself cycles; [defaultSpeed] stays
  /// inside this set.
  static const List<double> speedOptions = [1.0, 1.25, 1.5, 2.0];

  static const List<int> qualityOptions = [0, 16, 32, 64, 74, 80, 112, 116, 120];

  @override
  VideoSettingsModel build() {
    return VideoSettingsModel(
      preferredQuality: HivePrefUtil.getInt('videoPreferredQuality') ?? 0,
      defaultSpeed: HivePrefUtil.getDouble('videoDefaultSpeed') ?? 1.0,
      showVideoDetail: HivePrefUtil.getBool('videoShowDetail') ?? true,
      persistentProgress: HivePrefUtil.getBool('videoPersistentProgress') ?? true,
      startSection: HivePrefUtil.getInt('videoStartSection') ?? 0,
      homeTabIndex: HivePrefUtil.getInt('videoHomeTab') ?? 1,
      personalTabIndex: HivePrefUtil.getInt('videoPersonalTab') ?? 0,
    );
  }

  void updateSettings(VideoSettingsModel newModel) {
    final speed = speedOptions.contains(newModel.defaultSpeed) ? newModel.defaultSpeed : 1.0;
    state = newModel.copyWith(defaultSpeed: speed);
    HivePrefUtil.setInt('videoPreferredQuality', state.preferredQuality);
    HivePrefUtil.setDouble('videoDefaultSpeed', state.defaultSpeed);
    HivePrefUtil.setBool('videoShowDetail', state.showVideoDetail);
    HivePrefUtil.setBool('videoPersistentProgress', state.persistentProgress);
    HivePrefUtil.setInt('videoStartSection', state.startSection);
    HivePrefUtil.setInt('videoHomeTab', state.homeTabIndex);
    HivePrefUtil.setInt('videoPersonalTab', state.personalTabIndex);
  }
}
