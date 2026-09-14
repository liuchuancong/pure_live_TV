import 'dart:async';

import 'log_settings_model.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_settings_controller.g.dart';

@riverpod
class LogSettingsController extends _$LogSettingsController {
  static LogSettingsController get to => SettingsService.to.log;

  @override
  LogSettingsModel build() {
    // The log file lives for the whole process: this provider is auto-disposed
    // with the settings page, so it must not close the sink on dispose.
    return LogSettingsModel(storedEnableLog: HivePrefUtil.getBool('enableLog') ?? false);
  }

  bool get enableLog => state.storedEnableLog;

  /// Applies the requested state to the log file and keeps the switch in sync
  /// with what actually happened, so an unusable directory never looks enabled.
  Future<bool> setLoggingEnabled(bool enabled) async {
    final applied = await Log.setEnabled(enabled);
    if (!applied) return false;
    state = state.copyWith(storedEnableLog: enabled);
    HivePrefUtil.setBool('enableLog', enabled);
    return true;
  }

  void setEnableLog(bool enabled) => unawaited(setLoggingEnabled(enabled));

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = LogSettingsModel.fromJson(json);
    HivePrefUtil.setBool('enableLog', state.storedEnableLog);
    unawaited(Log.setEnabled(state.storedEnableLog));
  }
}
