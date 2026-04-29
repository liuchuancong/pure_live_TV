import 'dart:developer';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/plugins/update.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/utils/version_util.dart';
import 'package:pure_live/common/base/base_controller.dart';

class VersionController extends BaseController {
  final hasNewVersion = false.obs;
  final isLoading = true.obs; // 1. Added loading state
  final apkUrl = ''.obs;
  final apkUrl2 = ''.obs;
  final ScrollController scrollController = ScrollController();
  // Use RxList to ensure the UI reacts to changes
  final appFocusNodes = <AppFocusNode>[].obs;
  final appFocus2Nodes = <AppFocusNode>[].obs;
  final updateNotes = ''.obs;
  @override
  void onInit() {
    super.onInit();
    checkNewVersion();
  }

  Future<void> checkNewVersion() async {
    isLoading.value = true;
    try {
      await VersionUtil().checkUpdate();
      hasNewVersion.value = VersionUtil.hasNewVersion();

      final version = VersionUtil.latestVersion;
      final project = VersionUtil.projectUrl;
      updateNotes.value = VersionUtil.latestUpdateLog;
      log("Latest version: $version, Update notes: ${VersionUtil.latestUpdateLog}");
      apkUrl.value = '$project/releases/download/v$version/app-armeabi-v7a-release.apk';
      apkUrl2.value = '$project/releases/download/v$version/app-arm64-v8a-release.apk';

      // 2. Generate nodes only after URLs are ready
      appFocusNodes.assignAll(getMirrorUrls(apkUrl.value).map((e) => AppFocusNode()).toList());
      appFocus2Nodes.assignAll(getMirrorUrls(apkUrl2.value).map((e) => AppFocusNode()).toList());
    } finally {
      isLoading.value = false; // 3. Stop loading
    }
  }
}
