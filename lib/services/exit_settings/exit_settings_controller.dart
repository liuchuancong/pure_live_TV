import 'dart:io';
import 'exit_settings_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exit_settings_controller.g.dart';

@riverpod
class ExitSettingsController extends _$ExitSettingsController {
  late final StopWatchTimer _stopWatchTimer;
  static ExitSettingsController get to => SettingsService.to.exit;

  @override
  ExitSettingsModel build() {
    _stopWatchTimer = StopWatchTimer(mode: StopWatchMode.countDown);
    ref.onDispose(() => _stopWatchTimer.dispose());

    _stopWatchTimer.fetchEnded.listen((_) {
      _stopWatchTimer.onStopTimer();
      exit(0);
    });

    final model = ExitSettingsModel(
      dontAskExit: HivePrefUtil.getBool('dontAskExit') ?? false,
      exitChoose: HivePrefUtil.getString('exitChoose') ?? '',
      autoShutDownTime: HivePrefUtil.getInt('autoShutDownTime') ?? 120,
      enableAutoShutDownTime: HivePrefUtil.getBool('enableAutoShutDownTime') ?? false,
    );

    if (model.enableAutoShutDownTime) _startTimer(model.autoShutDownTime);

    return model;
  }

  void _startTimer(int minutes) {
    _stopWatchTimer.onStopTimer();
    _stopWatchTimer.onResetTimer();
    _stopWatchTimer.setPresetMinuteTime(minutes, add: false);
    _stopWatchTimer.onStartTimer();
  }

  void updateConfig(ExitSettingsModel newModel) {
    state = newModel;
    HivePrefUtil.setBool('dontAskExit', newModel.dontAskExit);
    HivePrefUtil.setString('exitChoose', newModel.exitChoose);
    HivePrefUtil.setInt('autoShutDownTime', newModel.autoShutDownTime);
    HivePrefUtil.setBool('enableAutoShutDownTime', newModel.enableAutoShutDownTime);

    if (newModel.enableAutoShutDownTime) {
      _startTimer(newModel.autoShutDownTime);
    } else {
      _stopWatchTimer.onStopTimer();
      _stopWatchTimer.onResetTimer();
    }
  }

  void importFromJson(Map<String, dynamic> json) {
    _updateState(ExitSettingsModel.fromJson(json));
  }

  Map<String, dynamic> toJson() {
    return state.toJson();
  }

  void _updateState(ExitSettingsModel newModel) => updateConfig(newModel);
  void setDontAskExit(bool value) => updateConfig(state.copyWith(dontAskExit: value));
}
