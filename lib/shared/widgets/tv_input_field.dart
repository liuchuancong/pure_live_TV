import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// The TV text field: a plain Flutter [TextField] with the app's palette.
///
/// It used to wrap the `native_textfield_tv` package (a TV soft keyboard) behind
/// a `useNativeTextField` flag that defaulted to true — but every caller passes a
/// plain [TextEditingController], and the widget cast it to the package's own
/// controller type, so each field threw as soon as it was built. Text entry now
/// goes through the platform IME (which every Android TV build ships) like any
/// other Flutter field, and the package dependency is gone.
class TvInputField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
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
    required this.controller,
    this.focusNode,
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
  late bool _isObscure;
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _isRegionFocused = false;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
    if (widget.focusNode == null) {
      _focusNode = FocusNode();
      _ownsFocusNode = true;
    } else {
      _focusNode = widget.focusNode!;
    }
  }

  @override
  void dispose() {
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  /// The d-pad region decides when the field is "active": focusing the row opens
  /// the keyboard, leaving it closes the keyboard again.
  void _handleFocusChange(bool hasFocus) {
    if (!mounted) return;
    setState(() => _isRegionFocused = hasFocus);
    if (hasFocus) {
      _focusNode.requestFocus();
    } else {
      _focusNode.unfocus();
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

    final int lines = widget.maxLines ?? 1;
    final Widget inputCore = Container(
      height: lines > 1 ? null : resolvedHeight,
      constraints: lines > 1 ? BoxConstraints(minHeight: resolvedHeight) : null,
      color: resolvedBgColor,
      alignment: Alignment.centerLeft,
      child: TextField(
        focusNode: _focusNode,
        controller: widget.controller,
        obscureText: _isObscure,
        minLines: lines > 1 ? 2 : null,
        maxLines: lines,
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

    final Widget content = Stack(
      alignment: Alignment.centerRight,
      children: [
        Container(
          width: double.infinity,
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
                  onPressed: () => setState(() => _isObscure = !_isObscure),
                ),
                SizedBox(width: 4.sp),
              ],
              if (widget.postFixWidget != null) widget.postFixWidget!,
            ],
          ),
        ),
      ],
    );

    final Widget innerWidget;
    if (widget.builder != null) {
      innerWidget = widget.builder!(content);
    } else {
      innerWidget = AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.sp),
          color: resolvedBgColor,
          border: Border.all(color: _isRegionFocused ? resolvedFocusedBorder : resolvedUnfocusedBorder, width: 2.sp),
        ),
        child: content,
      );
    }

    return DpadRegion(
      // Focus leaving the field (up/down included) deactivates the input
      // through `onFocusChange`; the field needs no edge handler of its own.
      horizontalEdge: DpadEdgeBehavior.leave,
      verticalEdge: DpadEdgeBehavior.leave,
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
