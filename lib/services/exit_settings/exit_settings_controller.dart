import 'dart:io';
import 'exit_settings_model.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:stop_watch_timer/stop_watch_timer.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'exit_settings_controller.g.dart';

@riverpod
class ExitSettingsController extends _$ExitSettingsController {
  late final StopWatchTimer _stopWatchTimer;
  static ExitSettingsController get to => SettingsService.to.exit;

  static const int defaultAutoShutdownMinutes = 120;
  static const int minAutoShutdownMinutes = 1;
  static const int maxAutoShutdownMinutes = 525600;

  /// Keeps a stored or imported duration inside a schedulable range: 0 would
  /// exit immediately and an unbounded value would keep the timer alive for
  /// years.
  static int normalizeAutoShutdownMinutes(int minutes) =>
      minutes.clamp(minAutoShutdownMinutes, maxAutoShutdownMinutes);

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
      autoShutDownTime: normalizeAutoShutdownMinutes(
        HivePrefUtil.getInt('autoShutDownTime') ?? defaultAutoShutdownMinutes,
      ),
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
    final minutes = normalizeAutoShutdownMinutes(newModel.autoShutDownTime);
    final changed =
        minutes != state.autoShutDownTime || newModel.enableAutoShutDownTime != state.enableAutoShutDownTime;
    state = newModel.copyWith(autoShutDownTime: minutes);
    HivePrefUtil.setBool('dontAskExit', state.dontAskExit);
    HivePrefUtil.setString('exitChoose', state.exitChoose);
    HivePrefUtil.setInt('autoShutDownTime', state.autoShutDownTime);
    HivePrefUtil.setBool('enableAutoShutDownTime', state.enableAutoShutDownTime);

    if (state.enableAutoShutDownTime) {
      // Restarting an unchanged running countdown would silently postpone the
      // exit every time another setting is saved.
      if (changed || !_stopWatchTimer.isRunning) _startTimer(state.autoShutDownTime);
    } else if (changed || _stopWatchTimer.isRunning) {
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
