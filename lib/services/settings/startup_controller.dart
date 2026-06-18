import 'package:pure_live/get/get.dart';
import 'package:pure_live/core/site/huya_site.dart';
import 'package:pure_live/services/utils/hive_rx.dart';

class StartupController extends GetxController {
  final RxBool isFirstInApp = hiveBool('isFirstInApp', true);

  @override
  void onInit() {
    super.onInit();
    loadHuyaUa();
  }

  Future<void> loadHuyaUa() async {
    HuyaSite().getHuYaUA();
  }

  void setFirstInApp() {
    isFirstInApp.v = true;
  }

  void finishFirstInApp() {
    isFirstInApp.v = false;
  }

  Map<String, dynamic> toJson() {
    return {'isFirstInApp': isFirstInApp.v};
  }

  void fromJson(Map<String, dynamic> json) {
    isFirstInApp.v = json['isFirstInApp'] ?? true;
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
