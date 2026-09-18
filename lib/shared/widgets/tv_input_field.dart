import 'package:flutter/material.dart';
import 'package:tv_textfield/tv_textfield.dart';
import 'package:pure_live/shared/theme/tv_theme_data.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// The TV text field: [TvTextField] from `tv_textfield` wearing the app's
/// palette.
///
/// The field used to be a plain Flutter [TextField]. On a TV that is the wrong
/// control: while focused it consumes the arrow keys for caret movement, so a
/// remote could never leave the field — and after the soft keyboard was
/// dismissed the focus was stuck, which left pages where only a mouse could
/// press anything (flutter#147772). [TvTextField] shows a read-only display
/// while it merely has focus, keeps the arrows for focus traversal, and only
/// raises the keyboard once OK is pressed.
///
/// It used to wrap the `native_textfield_tv` package behind a
/// `useNativeTextField` flag that defaulted to true — but every caller passes a
/// plain [TextEditingController], and the widget cast it to the package's own
/// controller type, so each field threw as soon as it was built. Text entry now
/// goes through [TvTextField], and that dependency is gone.
///
/// It also used to wrap itself in a [DpadRegion] to detect "the d-pad reached
/// the field" — but a nested region is invisible to the dpad traversal policy's
/// region-first search (nested-region items are only considered once the
/// enclosing region has no candidate in that direction), so arrow navigation
/// always skipped straight past the field. The field is now a plain focus
/// target, and the visual focus state is tracked with a simple
/// [Focus.onFocusChange] listener.
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

    // The focused fill can be the accent (light palettes focus onto it) and the
    // unfocused one is a card, so the text colour is picked from the *effective*
    // background by contrast rather than from the palette's default text colour —
    // the old luminance threshold left dark palettes with white-on-blue at 2.8:1 and
    // light ones with white text on a white field.
    final Color fallbackTextColor = TvThemeData.readableOn(
      widget.backgroundColor ?? (_isFocused ? currentTvTheme.focusedCardColor : currentTvTheme.cardColor),
    );
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
      child: TvTextField(
        focusNode: _focusNode,
        controller: widget.controller,
        obscureText: _isObscure,
        minLines: lines > 1 ? 2 : null,
        maxLines: lines,
        // The Flutter backend, not the package's default. On Android `auto`
        // picks the native EditText platform view, which would drop this app's
        // palette (font, colours, hint) and its focus frame; the behaviour that
        // was broken on TV — arrows being eaten by a focused field — is fixed by
        // the Flutter backend too, and it still raises the platform keyboard
        // once the field is activated.
        implementation: TvTextFieldImplementation.flutter,
        // The focus ring is drawn by the frame around the field, so the field
        // itself only reports focus; the package's own decoration is disabled
        // to keep one look for focused and unfocused states.
        focusDecoration: const BoxDecoration(),
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
        // On light palettes an 18px blur is a grey smear around the focused
        // field; a hard accent ring reads as a crisp focus indicator.
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: resolvedFocusedBorder.withAlpha(
              _isFocused ? (0.55.clamp(0.0, 1.0) * 255).round() : 0,
            ),
            blurRadius: currentTvTheme.isLight ? 0 : 18.0.sp,
            spreadRadius: currentTvTheme.isLight ? 2.0.sp : 2.0.sp,
          ),
        ],
      ),
      child: innerWidget,
    );
  }
}
