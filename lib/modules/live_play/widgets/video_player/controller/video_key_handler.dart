import 'dart:async';
import 'dart:developer';
import 'package:get/get.dart';
import '../video_controller.dart';
import '../models/video_enums.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/controller/video_danmaku.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/controller/video_constants.dart';

/// 键盘事件处理扩展
extension VideoKeyHandler on VideoController {
  /// 处理键盘事件入口
  void handleKeyEventExternal(KeyEvent key) {
    if (key is KeyUpEvent) return;
    throttle(() => handleKeyEventInternal(key), VideoConstants.keyThrottleDelay);
  }

  /// 键盘事件核心处理
  void handleKeyEventInternal(KeyEvent key) {
    log(key.logicalKey.toString(), name: 'handleKeyEventInternal');
    // Menu键打开设置面板
    if (key.logicalKey == LogicalKeyboardKey.keyM || key.logicalKey == LogicalKeyboardKey.contextMenu) {
      showPlayListPanel.value = false;
      showController.value = false;
      showSettting.value = true;
      return;
    }

    // 根据控制器显示状态分支处理
    if (!showController.value) {
      handleKeyHiddenState(key);
    } else {
      handleKeyShownState(key);
    }
  }

  /// 控制器隐藏时的键盘事件
  void handleKeyHiddenState(KeyEvent key) {
    // 无任何面板显示
    if (!showSettting.value &&
        !showPlayListPanel.value &&
        !showQualityPanel.value &&
        !showLinePanel.value &&
        !showQrCodePanel.value) {
      handleKeyNoPanel(key);
    }
    // 播放列表面板显示
    else if (showPlayListPanel.value) {
      handleKeyPlaylistPanel(key);
    }
    // 画质面板显示
    else if (showQualityPanel.value) {
      handleKeyQualityPanel(key);
    }
    // 线路面板显示
    else if (showLinePanel.value) {
      handleKeyLinePanel(key);
    } else if (showQrCodePanel.value) {
      handlekeyPanelQrCode(key);
    } else {
      handleKeySettingsPanel(key);
    }
  }

  void handlekeyPanelQrCode(KeyEvent key) {
    if (key.logicalKey == LogicalKeyboardKey.escape || key.logicalKey == LogicalKeyboardKey.goBack) {
      showQrCodePanel.value = false;
      return;
    }
    log('KeyEvent in QrCode: ${key.logicalKey}', name: 'VideoKeyHandler');
  }

  /// 无面板时的键盘事件
  void handleKeyNoPanel(KeyEvent key) {
    // 确认键显示控制器
    log('KeyEvent in NoPanel: ${key.logicalKey}', name: 'VideoKeyHandler');
    if (isConfirmKey(key.logicalKey)) {
      enableController();
      return;
    }

    // 上下键切换播放频道
    if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
      prevPlayChannel();
    } else if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
      nextPlayChannel();
    }

    // 左键双击关注/取消关注
    if (key.logicalKey == LogicalKeyboardKey.arrowLeft) {
      handleDoubleFavoriteAction();
    }
    // 右键打开播放列表
    else if (key.logicalKey == LogicalKeyboardKey.arrowRight) {
      showPlayListPanel.value = true;
    }
  }

  /// 播放列表面板键盘事件
  void handleKeyPlaylistPanel(KeyEvent key) {
    // 上下键切换列表项
    int playIndex = beforePlayNodeIndex.value;
    if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
      playIndex++;
      if (playIndex >= settings.currentPlayList.length) {
        playIndex = 0;
      }
    } else if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
      playIndex--;
      if (playIndex < 0) {
        playIndex = settings.currentPlayList.length - 1;
      }
    }
    beforePlayNodeIndex.value = playIndex;

    // 左右键关注/取消关注
    if (key.logicalKey == LogicalKeyboardKey.arrowLeft || key.logicalKey == LogicalKeyboardKey.arrowRight) {
      toggleFavoriteAction(settings.currentPlayList[beforePlayNodeIndex.value]);
    }

    // 确认键播放选中频道
    if (isConfirmKey(key.logicalKey)) {
      settings.currentPlayListNodeIndex.value = beforePlayNodeIndex.value;
      livePlayController.playFavoriteChannel();
    }
  }

  /// 画质面板键盘事件
  void handleKeyQualityPanel(KeyEvent key) {
    // 上下键切换画质
    int qualityIndex = qualityCurrentIndex.value;
    if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
      qualityIndex++;
      if (qualityIndex >= qualites.length) {
        qualityIndex = 0;
      }
    } else if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
      qualityIndex--;
      if (qualityIndex < 0) {
        qualityIndex = qualites.length - 1;
      }
    }
    qualityCurrentIndex.value = qualityIndex;

    // 确认键切换画质
    if (isConfirmKey(key.logicalKey)) {
      changeQuality(qualityIndex);
    }
  }

  /// 线路面板键盘事件
  void handleKeyLinePanel(KeyEvent key) {
    // 上下键切换线路
    int lineIndex = lineCurrentIndex.value;
    if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
      lineIndex++;
      if (lineIndex >= playUrls.length) {
        lineIndex = 0;
      }
    } else if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
      lineIndex--;
      if (lineIndex < 0) {
        lineIndex = playUrls.length - 1;
      }
    }
    lineCurrentIndex.value = lineIndex;
    // 确认键切换线路
    if (isConfirmKey(key.logicalKey)) {
      changeLineIndex(lineCurrentIndex.value);
    }
  }

  /// 设置面板键盘事件（弹幕）
  void handleKeySettingsPanel(KeyEvent key) {
    // 上下键切换弹幕设置项
    int danmakuIndex = danmukuNodeIndex.value;
    if (key.logicalKey == LogicalKeyboardKey.arrowDown) {
      danmakuIndex++;
      if (danmakuIndex >= DanmakuSettingClickType.values.length) {
        danmakuIndex = 0;
      }
    } else if (key.logicalKey == LogicalKeyboardKey.arrowUp) {
      danmakuIndex--;
      if (danmakuIndex < 0) {
        danmakuIndex = DanmakuSettingClickType.values.length - 1;
      }
    }
    danmukuNodeIndex.value = danmakuIndex;

    // 左右键调整弹幕参数
    if (key.logicalKey == LogicalKeyboardKey.arrowLeft) {
      handleDanmuKeyLeftEvent();
    } else if (key.logicalKey == LogicalKeyboardKey.arrowRight) {
      handleDanmuKeyRightEvent();
    }
  }

  /// 控制器显示时的键盘事件
  void handleKeyShownState(KeyEvent event) {
    // 必须加上这一行！只处理按下，忽略抬起
    if (event is! KeyDownEvent) return;

    final key = event.logicalKey;
    final List<BottomButtonClickType> buttonTypes = BottomButtonClickType.values;
    final int totalCount = buttonTypes.length;

    // 延长显示时间
    enableController();
    int currentIndex = currentNodeIndex.value;
    int nextIndex = currentIndex;

    if (key == LogicalKeyboardKey.arrowRight || key == LogicalKeyboardKey.arrowDown) {
      nextIndex = (currentIndex + 1) % totalCount;
    } else if (key == LogicalKeyboardKey.arrowLeft || key == LogicalKeyboardKey.arrowUp) {
      nextIndex = (currentIndex - 1 + totalCount) % totalCount;
    }

    // 仅当索引变化时更新，避免重复赋值
    if (nextIndex != currentIndex) {
      currentNodeIndex.value = nextIndex;
      log("Key: ${key.debugName}, Old Index: $currentIndex, New Index: $nextIndex, Type: ${buttonTypes[nextIndex]}");
    }

    if (isConfirmKey(key)) {
      handleBottomButtonActionInternal(buttonTypes[nextIndex]);
    }
  }

  /// 处理双击关注/取消关注
  void handleDoubleFavoriteAction() {
    if (doubleClickTimeStamp == 0) {
      // 首次点击
      final tip = settings.isFavorite(room) ? "双击取消关注" : "双击关注";
      SmartDialog.showToast(tip);
      doubleClickTimeStamp = DateTime.now().millisecondsSinceEpoch;

      // 设置双击超时
      doubleClickTimer?.cancel();
      doubleClickTimer = Timer(VideoConstants.doubleClickDuration, () {
        doubleClickTimeStamp = 0;
        doubleClickTimer?.cancel();
      });
    } else {
      // 第二次点击（双击）
      final now = DateTime.now().millisecondsSinceEpoch;
      if (now - doubleClickTimeStamp < VideoConstants.doubleClickDuration.inMilliseconds) {
        toggleFavoriteAction(room);
        doubleClickTimeStamp = 0;
        doubleClickTimer?.cancel();
      }
    }
  }

  /// 切换收藏状态
  void toggleFavoriteAction(dynamic room) {
    if (settings.isFavorite(room)) {
      settings.removeRoom(room);
      SmartDialog.showToast("已取消关注");
    } else {
      settings.addRoom(room);
      SmartDialog.showToast("已关注");
    }
  }

  /// 处理底部按钮点击事件
  void handleBottomButtonActionInternal(BottomButtonClickType type) {
    switch (type) {
      case BottomButtonClickType.playPause:
        togglePlayPause();
        break;
      case BottomButtonClickType.favorite:
        toggleFavoriteAction(room);
        break;
      case BottomButtonClickType.refresh:
        refresh();
        break;
      case BottomButtonClickType.danmaku:
        hideDanmaku.toggle();
        break;
      case BottomButtonClickType.settings:
        showSettting.value = true;
        break;
      case BottomButtonClickType.qualityName:
        showQualityPanel.value = true;
        break;
      case BottomButtonClickType.changeLine:
        showLinePanel.value = true;
        break;
      case BottomButtonClickType.shieldSetting:
        showQrCodePanel.value = true;
        break;
      case BottomButtonClickType.boxFit:
        setVideoFit();
        break;
    }
  }

  /// 弹幕参数左调
  void handleDanmuKeyLeftEvent() {
    _handleDanmuKeyAdjust(currentDanmakuClickType.value, isRight: false);
  }

  /// 弹幕参数右调
  void handleDanmuKeyRightEvent() {
    _handleDanmuKeyAdjust(currentDanmakuClickType.value, isRight: true);
  }

  /// 通用弹幕参数调整（核心修复：直接调用扩展方法）
  void _handleDanmuKeyAdjust(DanmakuSettingClickType type, {required bool isRight}) {
    // 直接调用扩展方法（扩展方法已添加到 VideoController 类）
    final handler = isRight ? handleDanmuKeyRight : handleDanmuKeyLeft;

    switch (type) {
      case DanmakuSettingClickType.danmakuAble:
        final items = {0: "关", 1: "开"};
        hideDanmaku.value = handler(items, hideDanmaku.value ? 0 : 1) == 0;
        break;
      case DanmakuSettingClickType.danmakuSize:
        danmakuFontSize.value = handler(DanmakuConstants.sizeMap, danmakuFontSize.value);
        break;
      case DanmakuSettingClickType.danmakuSpeed:
        danmakuSpeed.value = handler(DanmakuConstants.speedMap, danmakuSpeed.value);
        break;
      case DanmakuSettingClickType.danmakuArea:
        danmakuArea.value = handler(DanmakuConstants.areaMap, danmakuArea.value);
        break;
      case DanmakuSettingClickType.danmakuTopArea:
        danmakuTopArea.value = handler(DanmakuConstants.distanceMap, danmakuTopArea.value);
        break;
      case DanmakuSettingClickType.danmakuBottomArea:
        danmakuBottomArea.value = handler(DanmakuConstants.distanceMap, danmakuBottomArea.value);
        break;
      case DanmakuSettingClickType.danmakuOpacity:
        danmakuOpacity.value = handler(DanmakuConstants.areaMap, danmakuOpacity.value);
        break;
      case DanmakuSettingClickType.danmakuStorke:
        danmakuFontBorder.value = handler(DanmakuConstants.strokeMap, danmakuFontBorder.value);
        break;
    }
  }

  /// 判断是否为确认键
  bool isConfirmKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.controlLeft ||
        key == LogicalKeyboardKey.controlRight;
  }
}
