import 'package:flutter/material.dart';
import 'package:pure_live/shared/dialog/tv_dialog.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

class TvConfirmDialog extends StatefulWidget {
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
    this.confirmText,
    this.cancelText,
    this.onConfirm,
    this.onCancel,
  });

  @override
  State<TvConfirmDialog> createState() => _TvConfirmDialogState();
}

class _TvConfirmDialogState extends State<TvConfirmDialog> {
  int _initTime = 0;

  @override
  void initState() {
    super.initState();
    _initTime = DateTime.now().millisecondsSinceEpoch;
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return TvDialog(
      title: widget.title,
      confirmText: widget.confirmText ?? i18n('confirm'),
      cancelText: widget.cancelText ?? i18n('cancel'),
      onConfirm: () {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        if (currentTime - _initTime < 500) {
          return;
        }
        Navigator.of(context).pop();
        widget.onConfirm?.call();
      },
      onCancel: () {
        final currentTime = DateTime.now().millisecondsSinceEpoch;
        if (currentTime - _initTime < 500) {
          return;
        }
        if (widget.onCancel != null) {
          widget.onCancel?.call();
        } else {
          Navigator.of(context).pop();
        }
      },
      child: widget.message != null
          ? Text(
              widget.message!,
              style: TextStyle(color: tvTheme.secondaryTextColor, fontSize: 24.sp),
            )
          : const SizedBox.shrink(),
    );
  }
}
