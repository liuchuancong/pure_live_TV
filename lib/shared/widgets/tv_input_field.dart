import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:tv_textfield/tv_textfield.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/theme/tv_theme_data.dart';
import 'package:android_tv_text_field/native_textfield_tv.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// The TV text field: one look, two backends.
///
/// * **Android** — `AndroidTVTextField` from `android_tv_text_field`: a native
///   EditText platform view. The soft keyboard comes straight from the
///   platform, so it *opens* where Flutter's `SystemChannels.textInput` route
///   does nothing on TV boxes, and the platform owns caret movement and IME
///   state — the two things that are broken in Flutter on Android TV
///   (flutter#154924, flutter#147772).
/// * **Everywhere else** — [TvTextField] with the flutter backend: a read-only
///   display while the field merely has focus (arrows keep moving focus) and a
///   real `TextField` once OK activates it.
///
/// Both wear the same app palette: one frame draws the background, the radius
/// and the focus ring, and the inner field draws nothing of its own — that is
/// also the fix for the doubled ("ghosted") border the old three-layer field
/// had.
///
/// The controller is the app's plain [TextEditingController] on both backends:
/// the native route wraps it through [NativeTextFieldController.adopt] instead
/// of demanding the package's own type (the trap the earlier
/// `native_textfield_tv` integration fell into).
class TvInputField extends StatefulWidget {
  final TextEditingController? controller;
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
  /// the wrapper instead of the field and OK never opens the keyboard.
  final Widget Function(Widget content, bool isFocused)? builder;

  const TvInputField({
    super.key,
    this.controller,
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
  bool _ownsController = false;
  late final TextEditingController _controller;
  bool _isFocused = false;

  /// The native route's controller wrapper over [_controller].
  NativeTextFieldController? _nativeController;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? TextEditingController();
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
    if (_ownsController) _controller.dispose();
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
        : (widget.backgroundColor ?? (_isFocused ? currentTvTheme.focusedCardColor : currentTvTheme.backgroundColor));

    // The focused fill can be the accent (light palettes focus onto it) and the
    // unfocused one can be a card, so the text colour is picked from the
    // *effective* background by contrast rather than from the palette's default
    // text colour.
    final Color fallbackTextColor = TvThemeData.readableOn(
      widget.backgroundColor ?? (_isFocused ? currentTvTheme.focusedCardColor : currentTvTheme.backgroundColor),
    );
    final resolvedTextColor = widget.textColor ?? fallbackTextColor;
    final resolvedFocusedBorder = widget.focuesedBorderColor ?? currentTvTheme.focusColor;
    final resolvedUnfocusedBorder =
        widget.unFocuesedBorderColor ?? currentTvTheme.secondaryTextColor.withValues(alpha: 0.25);

    final int lines = widget.maxLines ?? 1;

    // -- the input core, per platform -------------------------------------
    final Widget inputCore;
    if (_useNativeAndroidField) {
      inputCore = AndroidTVTextField(
        focusNode: _focusNode,
        controller: _nativeControllerOf(),
        height: resolvedHeight,
        obscureText: _isObscure,
        hint: widget.hint,
        maxLines: lines,
        // The frame below is the only decoration: the native view gets the
        // same fill and text colours so it melts into it.
        backgroundColor: resolvedBgColor,
        textColor: resolvedTextColor,
        onSubmitted: widget.onSubmitted,
      );
    } else {
      inputCore = TvTextField(
        focusNode: _focusNode,
        controller: _controller,
        obscureText: _isObscure,
        minLines: lines > 1 ? 2 : null,
        maxLines: lines,
        // The Flutter backend, not the package's default: `auto` would pick
        // `tv_textfield`'s own native EditText view on Android, a second native
        // route to what `android_tv_text_field` already does here.
        implementation: TvTextFieldImplementation.flutter,
        // The focus ring is drawn by the frame around the field, so the field
        // itself only reports focus; the package's own decoration is disabled
        // to keep one look for focused and unfocused states.
        focusDecoration: const BoxDecoration(),
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
        onChanged: widget.onChanged,
      );
    }

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
      innerWidget = widget.builder!(content, _isFocused);
    } else {
      // One frame, exactly one: background, radius and focus ring all live
      // here, and both backends draw nothing of their own. The old stack
      // (frame → filled InputDecorator → another container) painted three
      // boxes and read as a doubled field.
      innerWidget = AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.sp),
          color: resolvedBgColor,
          border: Border.all(color: _isFocused ? resolvedFocusedBorder : resolvedUnfocusedBorder, width: 2.sp),
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
            color: resolvedFocusedBorder.withAlpha(_isFocused ? (0.55.clamp(0.0, 1.0) * 255).round() : 0),
            blurRadius: currentTvTheme.isLight ? 0 : 18.0.sp,
            spreadRadius: currentTvTheme.isLight ? 2.0.sp : 2.0.sp,
          ),
        ],
      ),
      child: innerWidget,
    );
  }

  /// The native route's controller, adopted once and kept alive for the field's
  /// lifetime so text typed on the native side reaches [_controller] (and every
  /// listener bound to it) in both directions.
  NativeTextFieldController _nativeControllerOf() {
    return _nativeController ??= NativeTextFieldController();
  }
}

/// The native Android route pays off on real TV boxes; everywhere else (tests,
/// desktop, web, iOS) the flutter backend is the sane default.
bool get _useNativeAndroidField {
  if (kIsWeb) return false;
  return Platform.isAndroid;
}
