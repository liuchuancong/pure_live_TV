import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/theme/tv_theme_x.dart';
import 'package:native_textfield_tv/native_textfield_tv.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvInputField extends StatefulWidget {
  final TextEditingController controller;
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
  final bool useNativeTextField;

  const TvInputField({
    super.key,
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
    this.useNativeTextField = true,
  });

  @override
  State<TvInputField> createState() => _TvInputFieldState();
}

class _TvInputFieldState extends State<TvInputField> {
  final GlobalKey<State<StatefulWidget>> _nativeTextFieldKey = GlobalKey<State<StatefulWidget>>();
  late bool _isObscure;
  late final FocusNode _flutterInputFocusNode;
  bool _isRegionFocused = false;
  bool _isInputActive = false;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
    _flutterInputFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _flutterInputFocusNode.dispose();
    super.dispose();
  }

  void _callNativeMethod(void Function(dynamic state) action) {
    final state = _nativeTextFieldKey.currentState;
    if (state != null) action(state);
  }

  void _deactivateInput() {
    _isInputActive = false;
    if (widget.useNativeTextField) {
      _callNativeMethod((s) => s.clearFocus());
    } else {
      _flutterInputFocusNode.unfocus();
    }
    setState(() {});
  }

  void _handleFocusChange(bool hasFocus) {
    if (!mounted) return;
    setState(() {
      _isRegionFocused = hasFocus;
      if (!hasFocus) {
        _deactivateInput();
      }
    });
  }

  void _onEdge(TraversalDirection dir) {
    if (!_isInputActive) return;
    if (dir == TraversalDirection.up || dir == TraversalDirection.down) {
      _deactivateInput();
    }
  }

  @override
  void didUpdateWidget(covariant TvInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.obscureText != oldWidget.obscureText) {
      setState(() {
        _isObscure = widget.obscureText;
        if (widget.useNativeTextField) {
          _callNativeMethod((s) => s.setObscureText(_isObscure));
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final resolvedHeight = widget.height ?? 60.sp;

    final resolvedBgColor = widget.builder != null
        ? Colors.transparent
        : (widget.backgroundColor ?? (_isRegionFocused ? currentTvTheme.focusedCardColor : currentTvTheme.cardColor));

    final resolvedTextColor = widget.textColor ?? currentTvTheme.primaryTextColor;
    final resolvedFocusedBorder = widget.focuesedBorderColor ?? currentTvTheme.focusColor;
    final resolvedUnfocusedBorder = widget.unFocuesedBorderColor ?? Colors.transparent;

    Widget inputCore;
    if (widget.useNativeTextField) {
      inputCore = NativeTextField(
        key: _nativeTextFieldKey,
        controller: widget.controller as NativeTextFieldController,
        height: resolvedHeight,
        obscureText: _isObscure,
        hint: widget.hint,
        maxLines: widget.maxLines,
        backgroundColor: resolvedBgColor,
        textColor: resolvedTextColor,
        onSubmitted: widget.onSubmitted,
      );
    } else {
      inputCore = Container(
        height: resolvedHeight,
        color: resolvedBgColor,
        alignment: Alignment.centerLeft,
        child: TextField(
          focusNode: _flutterInputFocusNode,
          controller: widget.controller,
          obscureText: _isObscure,
          maxLines: widget.maxLines,
          cursorColor: resolvedFocusedBorder,
          style: TextStyle(color: resolvedTextColor, fontSize: 28.sp, textBaseline: TextBaseline.alphabetic),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(color: resolvedTextColor.withValues(alpha: 0.4), fontSize: 24.sp),
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 2.sp),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onSubmitted: widget.onSubmitted,
        ),
      );
    }

    Widget content = Stack(
      alignment: Alignment.centerRight,
      children: [
        Container(
          width: double.infinity,
          height: resolvedHeight,
          padding: EdgeInsets.only(
            left: 12.sp,
            right: widget.postFixWidget == null && !widget.showPasswordToggle ? 12.sp : 50.sp,
          ),
          child: Row(children: [Expanded(child: inputCore)]),
        ),
        Positioned(
          right: 12.sp,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showPasswordToggle) ...[
                IconButton(
                  icon: Icon(
                    _isObscure ? Icons.visibility_off : Icons.visibility,
                    color: resolvedTextColor.withValues(alpha: 0.6),
                  ),
                  onPressed: () {
                    setState(() {
                      _isObscure = !_isObscure;
                      if (widget.useNativeTextField) {
                        _callNativeMethod((s) => s.setObscureText(_isObscure));
                      }
                    });
                  },
                ),
                SizedBox(width: 4.sp),
              ],
              if (widget.postFixWidget != null) widget.postFixWidget!,
            ],
          ),
        ),
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
          border: Border.all(color: _isRegionFocused ? resolvedFocusedBorder : resolvedUnfocusedBorder, width: 2.sp),
        ),
        child: content,
      );
    }

    return DpadRegion(
      horizontalEdge: DpadEdgeBehavior.leave,
      verticalEdge: DpadEdgeBehavior.leave,
      onEdge: _onEdge,
      onFocusChange: _handleFocusChange,
      child: widget.builder != null
          ? innerWidget
          : AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.sp),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: resolvedFocusedBorder.withAlpha(_isRegionFocused ? (0.55.clamp(0.0, 1.0) * 255).round() : 0),
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
