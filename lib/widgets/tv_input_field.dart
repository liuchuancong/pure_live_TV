import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:native_textfield_tv/native_textfield_tv.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvInputField extends StatefulWidget {
  final FocusNode focusNode;
  final NativeTextFieldController controller;
  final double? height;
  final bool obscureText;
  final String? hint;
  final int? maxLines;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? focuesedBorderColor;
  final Color? unFocuesedBorderColor;
  final bool showPasswordToggle;
  final ValueChanged<String>? onSubmitted;
  final Widget? postFixWidget;
  final Widget Function(Widget child)? builder;

  const TvInputField({
    super.key,
    required this.focusNode,
    required this.controller,
    this.height,
    this.obscureText = false,
    this.hint,
    this.maxLines = 1,
    this.showPasswordToggle = false,
    this.backgroundColor,
    this.textColor,
    this.focuesedBorderColor,
    this.unFocuesedBorderColor,
    this.postFixWidget,
    this.builder,
    this.onSubmitted,
  });

  @override
  State<TvInputField> createState() => _TvInputFieldState();
}

class _TvInputFieldState extends State<TvInputField> {
  final GlobalKey<State<StatefulWidget>> _nativeTextFieldKey = GlobalKey<State<StatefulWidget>>();
  late bool _isObscure;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
    widget.focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        if (widget.focusNode.hasFocus) {
          dynamic nativeState = _nativeTextFieldKey.currentState;
          nativeState?.requestFocus();
        } else {
          dynamic nativeState = _nativeTextFieldKey.currentState;
          nativeState?.clearFocus();
        }
      });
    }
  }

  @override
  void dispose() {
    widget.focusNode.removeListener(_handleFocusChange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final isFocused = widget.focusNode.hasFocus;

    final resolvedHeight = widget.height ?? 60.sp;
    final resolvedBgColor =
        widget.backgroundColor ?? (isFocused ? currentTvTheme.focusedCardColor : currentTvTheme.cardColor);
    final resolvedTextColor = widget.textColor ?? currentTvTheme.primaryTextColor;
    final resolvedFocusedBorder = widget.focuesedBorderColor ?? currentTvTheme.focusColor;
    final resolvedUnfocusedBorder = widget.unFocuesedBorderColor ?? Colors.transparent;

    Widget content = Row(
      children: [
        Expanded(
          child: NativeTextField(
            key: _nativeTextFieldKey,
            controller: widget.controller,
            height: resolvedHeight,
            obscureText: _isObscure,
            hint: widget.hint,
            maxLines: widget.maxLines,
            backgroundColor: resolvedBgColor,
            textColor: resolvedTextColor,
            onSubmitted: widget.onSubmitted,
          ),
        ),
        if (widget.showPasswordToggle) ...[
          SizedBox(width: 10.sp),
          IconButton(
            icon: Icon(
              _isObscure ? Icons.visibility_off : Icons.visibility,
              color: resolvedTextColor.withValues(alpha: 0.6),
            ),
            onPressed: () {
              setState(() {
                _isObscure = !_isObscure;
              });
            },
          ),
        ],
        if (widget.postFixWidget != null) ...[SizedBox(width: 10.sp), widget.postFixWidget!],
      ],
    );

    Widget innerWidget;
    if (widget.builder != null) {
      innerWidget = widget.builder!(content);
    } else {
      innerWidget = AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        height: resolvedHeight,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.sp),
          color: resolvedBgColor,
          border: Border.all(color: isFocused ? resolvedFocusedBorder : resolvedUnfocusedBorder, width: 2.sp),
        ),
        padding: EdgeInsets.symmetric(horizontal: 16.sp, vertical: 4.sp),
        child: content,
      );
    }

    return KeyboardListener(
      focusNode: widget.focusNode,
      onKeyEvent: (event) {
        if (event is KeyUpEvent) {
          dynamic nativeState = _nativeTextFieldKey.currentState;
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            nativeState?.moveCursorLeft();
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            nativeState?.moveCursorRight();
          }
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.sp),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: resolvedFocusedBorder.withAlpha(isFocused ? (0.55.clamp(0.0, 1.0) * 255).round() : 0),
              blurRadius: 18.0.sp,
              spreadRadius: 2.0.sp,
            ),
          ],
        ),
        child: innerWidget,
      ),
    );
  }
}
