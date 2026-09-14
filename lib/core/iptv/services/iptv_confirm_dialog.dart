import 'package:flutter/material.dart';
import 'package:pure_live/global/app_navigator.dart';
import 'package:pure_live/plugins/locale_helper.dart';

/// 服务层的“同名覆盖”确认框（替代已移除的 GetX `Get.dialog`）。
///
/// 没有可用导航上下文时返回 false：宁可保留用户已有的源，也不静默覆盖。
Future<bool> confirmReplaceIptvSource({required String title, required String message}) async {
  final context = appNavigatorContext;
  if (context == null) return false;
  final confirmed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      scrollable: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: Text(i18n('cancel'))),
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: Text(i18n('confirm'))),
      ],
    ),
  );
  return confirmed == true;
}
