import 'package:get/get.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/common/index.dart';

class WallpaperPreviewController extends GetxController {
  final SettingsService settingsService = Get.find<SettingsService>();
  final isLoading = false.obs;
  DateTime _lastRequestTime = DateTime.now();

  // 刷新图片逻辑
  Future<void> getImage() async {
    if (DateTime.now().difference(_lastRequestTime).inMilliseconds < 800) return;
    _lastRequestTime = DateTime.now();
    try {
      isLoading.value = true;
      SmartDialog.showLoading();
      await settingsService.getImage();
    } finally {
      isLoading.value = false;
      SmartDialog.dismiss();
    }
  }

  // 处理物理按键
  KeyEventResult handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.arrowUp || event.logicalKey == LogicalKeyboardKey.arrowDown) {
        getImage();
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }
}
