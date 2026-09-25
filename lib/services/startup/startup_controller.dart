import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'startup_controller.g.dart';

@riverpod
class StartupController extends _$StartupController {
  static StartupController get to => SettingsService.to.startup;
  @override
  bool build() {
    // One verification pass per launch: the followed rooms were last checked
    // whenever the viewer last looked, so the first visit to the favourites page
    // re-asks the platforms. An import arms the same pending flag.
    FavoriteRoomController.requestStatusRefresh();

    return HivePrefUtil.getBool('isFirstInApp') ?? true;
  }

  void setIsFirstInApp(bool value) {
    HivePrefUtil.setBool('isFirstInApp', value);
    state = value;
  }

  void importFromJson(Map<String, dynamic> json) {
    // The agreement gate is device-local onboarding state, not a syncable
    // setting. An import that lacks the key — or a peer reporting "fresh
    // install" — must never bounce this TV back to the agreement page, which
    // is exactly what happened on every remote settings import.
    final isFirst = json['isFirstInApp'];
    if (isFirst != false) return;
    setIsFirstInApp(false);
  }

  Map<String, dynamic> toJson() {
    return {'isFirstInApp': state};
  }

  static Map<String, dynamic> extractConfig(Map<String, dynamic>? rootConfig) {
    final startup = rootConfig?['startup'] as Map<String, dynamic>? ?? {};
    return {'isFirstInApp': startup['isFirstInApp'] ?? true};
  }

  static Map<String, dynamic> mergeConfig(Map<String, dynamic> rootConfig, Map<String, dynamic> updateFields) {
    final startup = Map<String, dynamic>.from(rootConfig['startup'] ?? {});
    updateFields.forEach((k, v) => startup[k] = v);
    rootConfig['startup'] = startup;
    return rootConfig;
  }
}
