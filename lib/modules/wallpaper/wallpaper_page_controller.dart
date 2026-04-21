import 'dart:async';
import 'package:get/get.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/consts/app_consts.dart';

class WallpaperPageController extends GetxController {
  final SettingsService settingsService = Get.find<SettingsService>();

  final isFullScreen = false.obs;
  final isLoading = false.obs;
  DateTime _lastRequestTime = DateTime.now();

  // TV 焦点管理
  final AppFocusNode backNode = AppFocusNode();
  final AppFocusNode sourceNode = AppFocusNode(); // 壁纸源选择 Node
  final AppFocusNode refreshNode = AppFocusNode(); // 手动换图 Node
  final AppFocusNode previewNode = AppFocusNode(); // 全屏预览 Node
  final AppFocusNode fitNode = AppFocusNode();

  @override
  void onReady() {
    super.onReady();
    // 默认焦点落在预览按钮上
    previewNode.requestFocus();
  }

  Map<dynamic, String> getBoxImageItemsMap() {
    Map<dynamic, String> map = {};
    for (var element in AppConsts.currentBoxImageSources) {
      String key = element.keys.first;
      map[key] = key;
    }
    return map;
  }

  void enterFullScreen() {
    isFullScreen.value = true;
    FocusManager.instance.primaryFocus?.unfocus(); // 清除按钮焦点
  }

  void exitFullScreen() {
    isFullScreen.value = false;
    // 延迟恢复焦点，确保 UI 已显示
    Future.delayed(const Duration(milliseconds: 150), () {
      previewNode.requestFocus();
    });
  }

  Future<void> getImage() async {
    if (DateTime.now().difference(_lastRequestTime).inMilliseconds < 800) return;
    _lastRequestTime = DateTime.now();
    try {
      isLoading.value = true;
      await settingsService.getImage();
    } finally {
      isLoading.value = false;
    }
  }

  Map<dynamic, String> getFitItems() {
    return AppConsts().getFitItems();
  }

  RxInt get currentBoxImageIndex => settingsService.currentBoxImageIndex;
}
