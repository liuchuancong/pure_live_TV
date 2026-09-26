import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/theme/tv_theme_data.dart';
import 'package:android_tv_text_field/native_textfield_tv.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// The TV text field: one look, two backends.
///
/// * **Android** — [AndroidTVTextField]: a native EditText platform view. The
///   soft keyboard comes straight from the platform, so it *opens* where
///   Flutter's `SystemChannels.textInput` does nothing on TV boxes, and the
///   platform owns caret movement and IME state (flutter#154924, #147772).
/// * **Everywhere else** — [_TvTextFieldFallback]: a read-only display while
///   the field merely has focus (arrows keep moving focus) and a real
///   `TextField` once OK or a tap activates it.
///
/// Both wear the same app palette: one frame draws the background, the radius
/// and the focus ring, and the inner field draws nothing of its own.
class TvInputField extends StatefulWidget {
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final double? height;
  final bool obscureText;
  final String? hint;
  final int? maxLines;

  /// Unbounded height when [maxLines] is null and this is set.
  final int? minLines;
  final int? maxLength;
  final TextAlign textAlign;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? focuesedBorderColor;
  final Color? unFocuesedBorderColor;
  final bool showPasswordToggle;

  /// Whether the field starts in editing state (its own page rather than a form).
  final bool autoEdit;
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
    this.minLines,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.showPasswordToggle = false,
    this.autoEdit = false,
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

  /// The Dart-to-platform half of the [_nativeController] bridge, removed on
  /// dispose.
  VoidCallback? _mirrorToNative;

  /// The flutter fallback's editing state: true once OK or a tap activated the
  /// field, false while it only holds focus (arrows keep walking the layout).
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _isObscure = widget.obscureText;
    _editing = widget.autoEdit;
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
    final mirror = _mirrorToNative;
    if (mirror != null) _controller.removeListener(mirror);
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
    final Color effectiveBackground =
        widget.backgroundColor ?? (_isFocused ? currentTvTheme.focusedCardColor : currentTvTheme.backgroundColor);
    final Color resolvedTextColor = widget.textColor ?? TvThemeData.readableOn(effectiveBackground);
    final resolvedFocusedBorder = widget.focuesedBorderColor ?? currentTvTheme.focusColor;
    final resolvedUnfocusedBorder =
        widget.unFocuesedBorderColor ?? currentTvTheme.secondaryTextColor.withValues(alpha: 0.25);
    // Blended against the fill instead of carrying alpha of its own.
    //
    // Two reasons. The native field is a platform view, so Flutter composites
    // its frames through a texture, and translucent text comes out of that
    // soft; blending first reaches the native side opaque. And 40% is simply
    // too faint to read at TV distance - the placeholder came across as
    // blurred rather than dimmed, which is what this weight fixes.
    final Color resolvedHintColor = Color.alphaBlend(resolvedTextColor.withValues(alpha: 0.7), effectiveBackground);

    final int? lines = widget.maxLines;

    // -- the input core, per platform -------------------------------------
    final Widget inputCore;
    if (_useNativeAndroidField) {
      inputCore = AndroidTVTextField(
        focusNode: _focusNode,
        controller: _nativeControllerOf(),
        height: resolvedHeight,
        obscureText: _isObscure,
        hint: widget.hint,
        maxLines: lines ?? 1,
        // The frame below is the only decoration, so the platform field draws
        // none of its own: a fill would also be frozen, since AndroidView reads
        // its creation params once while the frame recolours on focus.
        backgroundColor: Colors.transparent,
        textColor: resolvedTextColor,
        // Opaque on purpose - see resolvedHintColor.
        hintColor: resolvedHintColor,
        cursorColor: resolvedFocusedBorder,
        focuesedBorderColor: Colors.transparent,
        unFocuesedBorderColor: Colors.transparent,
        borderWidth: 0,
        // Matches the fallback backend, so the same field does not resize its
        // text when it lands on a platform that uses the native view.
        fontSize: 28.sp,
        textAlign: widget.textAlign,
        onSubmitted: widget.onSubmitted,
      );
    } else {
      inputCore = _TvTextFieldFallback(
        focusNode: _focusNode,
        controller: _controller,
        editing: _editing,
        onEditingChanged: (value) {
          if (mounted) setState(() => _editing = value);
        },
        obscureText: _isObscure,
        hint: widget.hint,
        minLines: widget.minLines,
        maxLines: lines,
        maxLength: widget.maxLength,
        textAlign: widget.textAlign,
        textColor: resolvedTextColor,
        // Same colour as the native route, so the placeholder does not change
        // weight when the field lands on a platform that uses the fallback.
        hintColor: resolvedHintColor,
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
      // here, and both backends draw nothing of their own.
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
        // Built only while focused.
        //
        // The list used to hold a BoxShadow at all times, with the idle state
        // expressed as a fully transparent colour - but a blurred shadow still
        // costs a blur pass at zero alpha, and that pass sits between the
        // platform view and the screen. Dropping it when idle changes nothing
        // visually (it was invisible) and removes the layer. On light palettes
        // an 18px blur was a grey smear anyway; a hard accent ring reads as a
        // crisper focus indicator.
        boxShadow: _isFocused && !currentTvTheme.isLight
            ? <BoxShadow>[
                BoxShadow(color: resolvedFocusedBorder.withValues(alpha: 0.55), blurRadius: 0.sp, spreadRadius: 2.0.sp),
              ]
            : const <BoxShadow>[],
      ),
      child: innerWidget,
    );
  }

  /// The native route's controller, adopted once and kept alive for the field's
  /// lifetime.
  ///
  /// The platform writes into this one, so its text is mirrored into
  /// [_controller] - the controller the caller passed in and reads back. Without
  /// the mirror anything typed on a TV keyboard stayed invisible to callers: the
  /// history page kept re-reading the value it had set itself.
  ///
  /// The other direction matters just as much and used to be missing: a value
  /// set in Dart (the phone pushing a cookie, a paste filling the renewal pair)
  /// only ever reached [_controller], so the platform field kept showing its own
  /// text while callers already read the new one — the box looked empty with the
  /// status and character count beside it already updated.
  NativeTextFieldController _nativeControllerOf() {
    final existing = _nativeController;
    if (existing != null) return existing;

    final native = NativeTextFieldController();
    native.addListener(() {
      if (!identical(_nativeController, native)) return;
      if (_controller.text == native.text) return;
      // A value copy, so the caret follows the mirrored text instead of staying
      // at whatever offset the previous value had.
      _controller.value = _controller.value.copyWith(
        text: native.text,
        selection: TextSelection.collapsed(offset: native.text.length),
        composing: TextRange.empty,
      );
    });

    // Writing the native controller pushes the text to the platform view (the
    // plugin's own listener forwards it), so a Dart-side set becomes visible
    // there. The guards above keep the two listeners from looping.
    void mirrorToNative() {
      if (!identical(_nativeController, native)) return;
      if (native.text == _controller.text) return;
      native.text = _controller.text;
    }

    _controller.addListener(mirrorToNative);
    _mirrorToNative = mirrorToNative;
    _nativeController = native;
    return native;
  }
}

/// The non-Android backend: a display line until OK (or a tap) turns it into a
/// real `TextField`.
///
/// Two subtrees on purpose. A read-only `TextField` still consumes the arrow
/// keys to move its selection, so a focused-but-not-editing field swallowed the
/// d-pad and the remote could not leave it; here the display line owns the
/// traversal and only editing hands the keys to a `TextField`.
class _TvTextFieldFallback extends StatefulWidget {
  const _TvTextFieldFallback({
    required this.focusNode,
    required this.controller,
    required this.editing,
    required this.onEditingChanged,
    required this.obscureText,
    required this.textColor,
    required this.hintColor,
    required this.textAlign,
    this.hint,
    this.minLines,
    this.maxLines,
    this.maxLength,
    this.onSubmitted,
    this.onChanged,
  });

  final FocusNode focusNode;
  final TextEditingController controller;
  final bool editing;
  final ValueChanged<bool> onEditingChanged;
  final bool obscureText;
  final Color textColor;
  final Color hintColor;
  final TextAlign textAlign;
  final String? hint;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;

  @override
  State<_TvTextFieldFallback> createState() => _TvTextFieldFallbackState();
}

class _TvTextFieldFallbackState extends State<_TvTextFieldFallback> {
  /// The editing node, alive only while the field is being typed into.
  FocusNode? _editNode;

  static bool _isConfirm(LogicalKeyboardKey key) =>
      key == LogicalKeyboardKey.select ||
      key == LogicalKeyboardKey.enter ||
      key == LogicalKeyboardKey.space ||
      key == LogicalKeyboardKey.controlLeft ||
      key == LogicalKeyboardKey.controlRight ||
      key == LogicalKeyboardKey.numpadEnter ||
      key == LogicalKeyboardKey.gameButtonA;

  void _startEditing() {
    _editNode ??= FocusNode(debugLabel: 'tv_input_edit');
    widget.onEditingChanged(true);
    // The node must exist before the next frame builds the TextField; focusing
    // it here is what opens the soft keyboard on mobile/desktop.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.editing) _editNode?.requestFocus();
    });
  }

  void _stopEditing() {
    widget.onEditingChanged(false);
    if (mounted) widget.focusNode.requestFocus();
  }

  @override
  void dispose() {
    _editNode?.dispose();
    super.dispose();
  }

  KeyEventResult _onDisplayKey(FocusNode node, KeyEvent event) {
    if (event is KeyUpEvent) return KeyEventResult.ignored;
    if (!_isConfirm(event.logicalKey)) return KeyEventResult.ignored;
    _startEditing();
    return KeyEventResult.handled;
  }

  KeyEventResult _onEditKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack || key == LogicalKeyboardKey.browserBack) {
      _stopEditing();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.editing) {
      final String text = widget.controller.text;
      return Focus(
        focusNode: widget.focusNode,
        onKeyEvent: _onDisplayKey,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _startEditing,
          child: Align(
            alignment: widget.textAlign == TextAlign.center ? Alignment.center : Alignment.centerLeft,
            child: Text(
              widget.obscureText ? '•' * text.length : text,
              maxLines: widget.maxLines ?? 100,
              overflow: TextOverflow.ellipsis,
              textAlign: widget.textAlign,
              style: TextStyle(color: text.isEmpty ? widget.hintColor : widget.textColor, fontSize: 28.sp),
            ),
          ),
        ),
      );
    }

    return Focus(
      onKeyEvent: _onEditKey,
      child: TextField(
        controller: widget.controller,
        focusNode: _editNode,
        autofocus: true,
        obscureText: widget.obscureText,
        textAlign: widget.textAlign,
        minLines: widget.minLines,
        maxLines: widget.maxLines,
        maxLength: widget.maxLength,
        style: TextStyle(color: widget.textColor, fontSize: 28.sp),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: TextStyle(color: widget.hintColor, fontSize: 24.sp),
          isDense: true,
          counterStyle: TextStyle(color: widget.hintColor, fontSize: 16.sp),
          contentPadding: EdgeInsets.symmetric(vertical: 2.sp),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        onSubmitted: widget.onSubmitted,
        onChanged: widget.onChanged,
      ),
    );
  }
}

/// The native Android route pays off on real TV boxes; everywhere else (tests,
/// desktop, web, iOS) the flutter fallback is the sane default.
bool get _useNativeAndroidField {
  if (kIsWeb) return false;
  return Platform.isAndroid;
}
