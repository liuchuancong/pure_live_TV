import 'dart:async';
import './video_constants.dart';
import '../video_controller.dart';
import '../models/video_enums.dart';
import 'package:flutter/material.dart';

/// 面板控制扩展
extension VideoPanel on VideoController {
  /// 隐藏所有面板，只保留指定类型的面板
  void hideAllPanelsExcept(PanelType type) {
    showControllerTimer?.cancel();
    showController.value = false;

    if (type != PanelType.playlist) showPlayListPanel.value = false;
    if (type != PanelType.quality) showQualityPanel.value = false;
    if (type != PanelType.settings) showSettting.value = false;
    if (type != PanelType.lines) showLinePanel.value = false;
    if (type != PanelType.qrCode) showQrCodePanel.value = false;
    danmukuNodeIndex.value = 0;
    currentNodeIndex.value = 0;
    cancelFocusInternal();
  }

  /// 滚动到指定索引（内部方法）
  void scrollToIndexInternal(int index) {
    scrollController.animateTo(
      index * VideoConstants.scrollItemHeight,
      duration: VideoConstants.scrollAnimationDuration,
      curve: Curves.easeOut,
    );
  }

  /// 显示控制器（5秒后自动隐藏）
  void enableControllerInternal() {
    showControllerTimer?.cancel();
    showController.value = true;
    showControllerTimer = Timer(VideoConstants.controllerAutoHideDelay, () {
      showController.value = false;
      cancelFocusInternal();
      focusNode.requestFocus();
    });
  }

  /// 隐藏控制器
  void disableControllerInternal() {
    showControllerTimer?.cancel();
    showController.value = false;
    cancelFocusInternal();
    cancelDanmakuFocusInternal();
    focusNode.requestFocus();
    currentNodeIndex.value = 0;
    danmukuNodeIndex.value = 0;
  }

  /// 取消底部按钮焦点（内部）
  void cancelFocusInternal() => currentNodeIndex.value = 0;

  /// 取消弹幕设置焦点（内部）
  void cancelDanmakuFocusInternal() => danmukuNodeIndex.value = 0;
}
