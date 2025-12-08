import 'package:get/get.dart';
import 'package:pure_live/plugins/update.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/utils/version_util.dart';
import 'package:pure_live/common/base/base_controller.dart';

class VersionController extends BaseController {
  final hasNewVersion = false.obs;
  final apkUrl = ''.obs;
  final apkUrl2 = ''.obs;
  List<AppFocusNode> appFocusNodes = [];
  List<AppFocusNode> appFocus2Nodes = [];
  @override
  void onInit() {
    super.onInit();
    checkNewVersion();
  }

  Future<void> checkNewVersion() async {
    await VersionUtil().checkUpdate();
    hasNewVersion.value = VersionUtil.hasNewVersion();
    appFocusNodes = getMirrorUrls(apkUrl.value).map((e) => AppFocusNode()).toList();
    appFocusNodes = getMirrorUrls(apkUrl2.value).map((e) => AppFocusNode()).toList();
    if (hasNewVersion.value) {
      apkUrl.value =
          '${VersionUtil.projectUrl}/releases/download/v${VersionUtil.latestVersion}/app-armeabi-v7a-release.apk';
      apkUrl2.value =
          '${VersionUtil.projectUrl}/releases/download/v${VersionUtil.latestVersion}/app-arm64-v8a-release.apk';
    }
  }
}
