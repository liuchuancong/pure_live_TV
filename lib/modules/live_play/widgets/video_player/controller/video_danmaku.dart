import 'package:get/get.dart';
import '../video_controller.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/common/models/live_message.dart';
import 'package:pure_live/common/utils/hive_pref_util.dart';
import 'package:pure_live/pkg/canvas_danmaku/models/danmaku_option.dart';
import 'package:pure_live/pkg/canvas_danmaku/models/danmaku_content_item.dart';

/// 弹幕逻辑扩展
extension VideoDanmaku on VideoController {
  /// 初始化弹幕持久化配置
  void initDanmakuPersistence() {
    // 弹幕隐藏状态
    _listenBool(
      'hideDanmaku',
      hideDanmaku,
      settings.hideDanmaku,
      false,
      onChanged: (v) {
        if (v) danmakuController.clear();
      },
    );

    // 弹幕显示区域
    _listenDouble('danmakuArea', danmakuArea, settings.danmakuArea, 1.0);
    // 弹幕顶部留白
    _listenDouble('danmakuTopArea', danmakuTopArea, settings.danmakuTopArea, 0.0);
    // 弹幕底部留白
    _listenDouble('danmakuBottomArea', danmakuBottomArea, settings.danmakuBottomArea, 0.0);
    // 弹幕速度
    _listenDouble('danmakuSpeed', danmakuSpeed, settings.danmakuSpeed, 8.0);
    // 弹幕字体大小
    _listenDouble('danmakuFontSize', danmakuFontSize, settings.danmakuFontSize, 16.0);
    // 弹幕描边
    _listenDouble('danmakuFontBorder', danmakuFontBorder, settings.danmakuFontBorder, 4.0);
    // 弹幕透明度
    _listenDouble('danmakuOpacity', danmakuOpacity, settings.danmakuOpacity, 1.0);
  }

  /// 更新弹幕配置
  void updateDanmakuConfig() {
    danmakuController.updateOption(
      DanmakuOption(
        fontSize: danmakuFontSize.value,
        area: danmakuArea.value,
        topAreaDistance: danmakuTopArea.value,
        bottomAreaDistance: danmakuBottomArea.value,
        duration: danmakuSpeed.value.toInt(),
        opacity: danmakuOpacity.value,
        fontWeight: danmakuFontBorder.value.toInt(),
      ),
    );
  }

  /// 发送弹幕
  void sendDanmakuMessage(LiveMessage msg) {
    if (hideDanmaku.value) return;
    danmakuController.addDanmaku(
      DanmakuContentItem(msg.message, color: Color.fromARGB(255, msg.color.r, msg.color.g, msg.color.b)),
    );
  }

  /// 布尔值持久化监听
  void _listenBool(String key, RxBool rx, RxBool settingRx, bool def, {Function(bool)? onChanged}) {
    rx.value = HivePrefUtil.getBool(key) ?? def;
    rx.listen((v) {
      HivePrefUtil.setBool(key, v);
      settingRx.value = v;
      onChanged?.call(v);
    });
  }

  /// 浮点值持久化监听
  void _listenDouble(String key, RxDouble rx, RxDouble settingRx, double def, {Function(double)? onChanged}) {
    rx.value = HivePrefUtil.getDouble(key) ?? def;
    rx.listen((v) {
      HivePrefUtil.setDouble(key, v);
      settingRx.value = v;
      onChanged?.call(v);
      updateDanmakuConfig();
    });
  }

  /// 弹幕参数左调
  dynamic handleDanmuKeyLeft(Map items, value) {
    final keys = items.keys.toList();
    final i = keys.indexOf(value);
    return keys[(i - 1 + keys.length) % keys.length];
  }

  /// 弹幕参数右调
  dynamic handleDanmuKeyRight(Map items, value) {
    final keys = items.keys.toList();
    final i = keys.indexOf(value);
    return keys[(i + 1) % keys.length];
  }
}
