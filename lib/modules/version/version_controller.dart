import 'dart:developer';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/plugins/update.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/utils/version_util.dart';
import 'package:pure_live/common/base/base_controller.dart';

class VersionController extends BaseController {
  final hasNewVersion = false.obs;
  final isLoading = true.obs;

  // 1. 定义标准版和精简版的 URL 响应变量
  final apkUrlv7 = ''.obs;
  final apkUrlv8 = ''.obs;
  final apkUrlv7Exo = ''.obs; // without-exo 版本
  final apkUrlv8Exo = ''.obs; // without-exo 版本

  final ScrollController scrollController = ScrollController();

  // 2. 为不同版本分配 FocusNodes
  final appFocusNodesV7 = <AppFocusNode>[].obs;
  final appFocusNodesV8 = <AppFocusNode>[].obs;
  final appFocusNodesV7Exo = <AppFocusNode>[].obs;
  final appFocusNodesV8Exo = <AppFocusNode>[].obs;

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
      String rawVersion = VersionUtil.latestVersion.trim();
      String cleanVersion = rawVersion.startsWith(RegExp(r'[vV]')) ? rawVersion.substring(1) : rawVersion;
      final String tag = 'v$cleanVersion';
      final project = VersionUtil.projectUrl;
      updateNotes.value = VersionUtil.latestUpdateLog;
      apkUrlv7.value = '$project/releases/download/$tag/app-armeabi-v7a-release.apk';
      apkUrlv8.value = '$project/releases/download/$tag/app-arm64-v8a-release.apk';
      apkUrlv7Exo.value = '$project/releases/download/$tag/app-armeabi-v7a-without-exo.apk';
      apkUrlv8Exo.value = '$project/releases/download/$tag/app-arm64-v8a-without-exo.apk';

      _generateNodes();
    } catch (e) {
      log("Version check failed: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void _generateNodes() {
    appFocusNodesV7.assignAll(getMirrorUrls(apkUrlv7.value).map((e) => AppFocusNode()).toList());
    appFocusNodesV8.assignAll(getMirrorUrls(apkUrlv8.value).map((e) => AppFocusNode()).toList());
    appFocusNodesV7Exo.assignAll(getMirrorUrls(apkUrlv7Exo.value).map((e) => AppFocusNode()).toList());
    appFocusNodesV8Exo.assignAll(getMirrorUrls(apkUrlv8Exo.value).map((e) => AppFocusNode()).toList());
  }
}
