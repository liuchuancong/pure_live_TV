import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'startup_controller.g.dart';

@riverpod
class StartupController extends _$StartupController {
  @override
  bool build() {
    return HivePrefUtil.getBool('isFirstInApp') ?? true;
  }

  void setIsFirstInApp(bool value) {
    HivePrefUtil.setBool('isFirstInApp', value);
    state = value;
  }

  void importFromJson(Map<String, dynamic> json) {
    final isFirst = json['isFirstInApp'] ?? true;
    setIsFirstInApp(isFirst);
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
