import 'tv_dialog.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvInputDialog extends StatefulWidget {
  final String title;
  final String? hintText;
  final String? initialValue;
  final int? maxLength;
  final ValueChanged<String>? onConfirm;

  const TvInputDialog({
    super.key,
    required this.title,
    this.hintText,
    this.initialValue,
    this.maxLength,
    this.onConfirm,
  });

  @override
  State<TvInputDialog> createState() => _TvInputDialogState();
}

class _TvInputDialogState extends State<TvInputDialog> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
    _focusNode = FocusNode();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _controller.text.trim();
    Navigator.of(context).pop(text);
    widget.onConfirm?.call(text);
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;

    return TvDialog(
      title: widget.title,
      confirmText: '确定',
      cancelText: '取消',
      onConfirm: _submit,
      onCancel: () => Navigator.of(context).pop(),
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLength: widget.maxLength,
        style: TextStyle(color: tvTheme.primaryTextColor, fontSize: 26.sp),
        cursorColor: tvTheme.focusColor,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: tvTheme.secondaryTextColor.withAlpha(120), fontSize: 24.sp),
          filled: true,
          fillColor: tvTheme.backgroundColor.withAlpha(100),
          contentPadding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.w),
          counterStyle: TextStyle(color: tvTheme.secondaryTextColor, fontSize: 18.sp),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16.sp), borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16.sp),
            borderSide: BorderSide(color: tvTheme.focusColor, width: 2.sp),
          ),
        ),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
