import 'package:flutter/material.dart';
import 'package:pure_live/get/get.dart';

/// 拓展FocusNode
class AppFocusNode extends FocusNode {
  var isFoucsed = false.obs;

  AppFocusNode() {
    isFoucsed.value = hasFocus;
    addListener(updateFoucs);
  }

  void updateFoucs() {
    isFoucsed.value = hasFocus;
  }

  @override
  void dispose() {
    removeListener(updateFoucs);
    super.dispose();
  }
}
