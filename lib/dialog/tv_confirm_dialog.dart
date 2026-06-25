import 'package:flutter/material.dart';
import 'package:pure_live/dialog/tv_dialog.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvConfirmDialog extends StatelessWidget {
  final String title;
  final String? message;
  final String? confirmText;
  final String? cancelText;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;

  const TvConfirmDialog({
    super.key,
    required this.title,
    this.message,
    this.confirmText = "确定",
    this.cancelText = "取消",
    this.onConfirm,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return TvDialog(
      title: title,
      confirmText: confirmText,
      cancelText: cancelText,
      onConfirm: () {
        Navigator.of(context).pop();
        onConfirm?.call();
      },
      onCancel:
          onCancel ??
          () {
            Navigator.of(context).pop();
          },
      child: message != null
          ? Text(
              message!,
              style: TextStyle(color: tvTheme.secondaryTextColor, fontSize: 24.sp),
            )
          : const SizedBox.shrink(),
    );
  }
}
