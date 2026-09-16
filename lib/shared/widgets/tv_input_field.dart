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
///
/// It also used to wrap itself in a [DpadRegion] to detect "the d-pad reached
/// the field" — but a nested region is invisible to the dpad traversal policy's
/// region-first search (nested-region items are only considered once the
/// enclosing region has no candidate in that direction), so arrow navigation
/// always skipped straight past the field. The field is now a plain focus
/// target: dpad lands directly on the [TextField]'s own focus node, dpad's
/// caret-aware `_directionAllowed` handles moving the caret with Left/Right and
/// leaving the field with Up/Down, and the visual focus state is tracked with a
/// simple [Focus.onFocusChange] listener.
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
  final ValueChanged<String>? onChanged;
  final Widget? postFixWidget;

  /// Custom frame around the input core.
  ///
  /// The second argument is the field's real focus state. Wrapping the content
  /// in a bare [Focus] widget to track it from the caller is a trap: a plain
  /// Focus is itself focusable and traversal-visible, so the d-pad lands on
  /// the wrapper instead of the TextField and OK never opens the keyboard.
  final Widget Function(Widget content, bool isFocused)? builder;

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
    this.onChanged,
  });

  @override
  State<TvInputField> createState() => _TvInputFieldState();
}

class _TvInputFieldState extends State<TvInputField> {
  late bool _isObscure;
  late final FocusNode _focusNode;
  bool _ownsFocusNode = false;
  bool _isFocused = false;

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
    _focusNode.addListener(_handleFocusChanged);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChanged);
    if (_ownsFocusNode) _focusNode.dispose();
    super.dispose();
  }

  /// The field is highlighted as soon as its focus node holds (or contains)
  /// primary focus — no separate d-pad region state needed.
  void _handleFocusChanged() {
    if (mounted) setState(() => _isFocused = _focusNode.hasFocus);
  }

  @override
  Widget build(BuildContext context) {
    final currentTvTheme = context.tvTheme;
    final resolvedHeight = widget.height ?? 60.sp;

    final resolvedBgColor = widget.builder != null
        ? Colors.transparent
        : (widget.backgroundColor ??
              (_isFocused
                  ? currentTvTheme.focusedCardColor
                  : currentTvTheme.cardColor));

    // Several presets use a near-white focusedCardColor, so when the field is
    // focused the background can turn light while primaryTextColor stays
    // white — white text on a white field. Pick the text color from the
    // effective background's luminance instead of the theme's text color.
    final Color fallbackTextColor =
        (widget.backgroundColor ?? (_isFocused ? currentTvTheme.focusedCardColor : currentTvTheme.cardColor))
                .computeLuminance() >
            0.5
        ? const Color(0xff1B1B1F)
        : currentTvTheme.primaryTextColor;
    final resolvedTextColor = widget.textColor ?? fallbackTextColor;
    final resolvedFocusedBorder =
        widget.focuesedBorderColor ?? currentTvTheme.focusColor;
    final resolvedUnfocusedBorder =
        widget.unFocuesedBorderColor ?? Colors.transparent;

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
        style: TextStyle(
          color: resolvedTextColor,
          fontSize: 28.sp,
          textBaseline: TextBaseline.alphabetic,
        ),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: resolvedTextColor.withValues(alpha: 0.4),
            fontSize: 24.sp,
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(vertical: 2.sp),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
      ),
    );

    final Widget content = Stack(
      alignment: Alignment.centerRight,
      children: [
        Container(
          width: double.infinity,
          padding: EdgeInsets.only(
            left: 12.sp,
            right: widget.postFixWidget == null && !widget.showPasswordToggle
                ? 12.sp
                : 50.sp,
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
      innerWidget = widget.builder!(content, _isFocused);
    } else {
      innerWidget = AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.sp),
          color: resolvedBgColor,
          border: Border.all(
            color: _isFocused ? resolvedFocusedBorder : resolvedUnfocusedBorder,
            width: 2.sp,
          ),
        ),
        child: content,
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12.sp),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: resolvedFocusedBorder.withAlpha(
              _isFocused ? (0.55.clamp(0.0, 1.0) * 255).round() : 0,
            ),
            blurRadius: 18.0.sp,
            spreadRadius: 2.0.sp,
          ),
        ],
      ),
      child: innerWidget,
    );
  }
}
