import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:pure_live/get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/plugins/update.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/utils/version_util.dart';
import 'package:pure_live/common/base/base_controller.dart';

class VersionController extends BaseController {
  final hasNewVersion = false.obs;
  final isLoading = true.obs;

  final apkUrlv7 = ''.obs;
  final apkUrlv8 = ''.obs;
  final apkUrlX86_64 = ''.obs;
  final apkUrlv7Exo = ''.obs;
  final apkUrlv8Exo = ''.obs;
  final apkUrlX86_64Exo = ''.obs;

  final ScrollController scrollController = ScrollController();

  final appFocusNodesV7 = <AppFocusNode>[].obs;
  final appFocusNodesV8 = <AppFocusNode>[].obs;
  final appFocusNodesX86_64 = <AppFocusNode>[].obs;
  final appFocusNodesV7Exo = <AppFocusNode>[].obs;
  final appFocusNodesV8Exo = <AppFocusNode>[].obs;
  final appFocusNodesX86_64Exo = <AppFocusNode>[].obs;

  final backButtonFocusNode = AppFocusNode();

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
      apkUrlX86_64.value = '$project/releases/download/$tag/app-x86_64-release.apk';

      apkUrlv7Exo.value = '$project/releases/download/$tag/app-armeabi-v7a-without-exo.apk';
      apkUrlv8Exo.value = '$project/releases/download/$tag/app-arm64-v8a-without-exo.apk';
      apkUrlX86_64Exo.value = '$project/releases/download/$tag/app-x86_64-without-exo.apk';

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
    appFocusNodesX86_64.assignAll(getMirrorUrls(apkUrlX86_64.value).map((e) => AppFocusNode()).toList());

    appFocusNodesV7Exo.assignAll(getMirrorUrls(apkUrlv7Exo.value).map((e) => AppFocusNode()).toList());
    appFocusNodesV8Exo.assignAll(getMirrorUrls(apkUrlv8Exo.value).map((e) => AppFocusNode()).toList());
    appFocusNodesX86_64Exo.assignAll(getMirrorUrls(apkUrlX86_64Exo.value).map((e) => AppFocusNode()).toList());
  }

  AppFocusNode getOrCreateFocusNode(List<AppFocusNode> nodes, int index) {
    while (nodes.length <= index) {
      nodes.add(AppFocusNode());
    }
    return nodes[index];
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}
