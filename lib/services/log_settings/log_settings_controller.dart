import 'log_settings_model.dart';
import 'package:pure_live/utils/log.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'log_settings_controller.g.dart';

@riverpod
class LogSettingsController extends _$LogSettingsController {
  static LogSettingsController get to => SettingsService.to.log;

  @override
  LogSettingsModel build() {
    return LogSettingsModel(
      serverAddress: HivePrefUtil.getString('user_log_address') ?? '',
      serverPort: HivePrefUtil.getInt('user_log_port') ?? 0,
      storedEnableLog: false,
    );
  }

  void updateServerInfo(String address, int port) {
    state = state.copyWith(serverAddress: address, serverPort: port);
    _persist();
  }

  void setEnableLog(bool enabled) async {
    state = state.copyWith(storedEnableLog: enabled);
    await Log.toggleLogEnable(enabled);
  }

  void _persist() {
    HivePrefUtil.setString('user_log_address', state.serverAddress);
    HivePrefUtil.setInt('user_log_port', state.serverPort);
  }

  void dispose() {
    Log.dispose();
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = LogSettingsModel.fromJson(json);
    _persist();
  }
}
