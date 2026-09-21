import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'native_textfield_tv_platform_interface.dart';

/// NativeTextfieldTv plugin
class NativeTextfieldTv {
  Future<String?> getPlatformVersion() {
    return NativeTextfieldTvPlatform.instance.getPlatformVersion();
  }
}

/// Controller for NativeTextField
class NativeTextFieldController extends TextEditingController {
  ValueChanged<bool>? onFocusChanged;
  bool _isUpdatingFromNative = false;

  NativeTextFieldController({String? text}) {
    if (text != null) {
      super.text = text;
    }
  }

  void _setTextFromNative(String text) {
    _isUpdatingFromNative = true;
    if (this.text != text) this.text = text;
    _isUpdatingFromNative = false;
  }

  bool get isUpdatingFromNative => _isUpdatingFromNative;

  Future<void> setText(String text) async {
    this.text = text;
  }
}

/// NativeTextField Widget
class NativeTextField extends StatefulWidget {
  final NativeTextFieldController? controller;
  final String? hint;
  final String? initialText;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final ValueChanged<bool>? onFocusChanged;
  final ValueChanged<String>? onSubmitted;
  final bool enabled;
  final double? width;
  final double? height;
  final bool obscureText;
  final int? maxLines;
  final Color backgroundColor;
  final Color textColor;

  const NativeTextField({
    super.key,
    this.controller,
    this.hint,
    this.initialText,
    this.focusNode,
    this.onChanged,
    this.onFocusChanged,
    this.onSubmitted,
    this.enabled = true,
    this.width,
    this.height,
    this.obscureText = false,
    this.maxLines = 1,
    this.backgroundColor = Colors.black,
    this.textColor = Colors.white,
  });

  @override
  State<NativeTextField> createState() => _NativeTextFieldState();
}

class _NativeTextFieldState extends State<NativeTextField> {
  late NativeTextFieldController _controller;
  bool _isControllerCreated = false;
  late int _instanceId;
  static int _nextInstanceId = 0;
  static const MethodChannel _channel = MethodChannel('native_textfield_tv');
  static final Map<int, _NativeTextFieldState> _instances = {};

  @override
  void initState() {
    super.initState();
    _instanceId = _nextInstanceId++;
    _instances[_instanceId] = this;

    _controller = widget.controller ?? NativeTextFieldController();
    _isControllerCreated = widget.controller == null;

    // Listen to controller changes
    _controller.addListener(_onControllerTextChanged);
    if (widget.onChanged != null) {
      _controller.addListener(() {
        if (!_controller.isUpdatingFromNative)
          widget.onChanged!(_controller.text);
      });
    }
    _controller.onFocusChanged = widget.onFocusChanged;

    _initializeChannel();
  }

  void _onControllerTextChanged() {
    if (!_controller.isUpdatingFromNative) _syncToNative();
  }

  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    final instanceId = call.arguments['instanceId'] as int?;
    final instance = _instances[instanceId];
    if (instance == null) return;

    switch (call.method) {
      case 'onTextChanged':
        final text = call.arguments['text'] as String? ?? '';
        instance._controller._setTextFromNative(text);
        break;
      case 'onFocusChanged':
        final hasFocus = call.arguments['hasFocus'] as bool? ?? false;
        instance._controller.onFocusChanged?.call(hasFocus);
        break;
      case 'onSubmitted':
        final text = call.arguments['text'] as String? ?? '';
        instance.widget.onSubmitted?.call(text);
        break;
    }
  }

  static void _initializeChannel() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  void _syncToNative() {
    _channel.invokeMethod(
        'setText', {'instanceId': _instanceId, 'text': _controller.text});
  }

  Future<void> requestFocus() async {
    await _channel.invokeMethod('requestFocus', {'instanceId': _instanceId});
  }

  Future<void> clearFocus() async {
    await _channel.invokeMethod('clearFocus', {'instanceId': _instanceId});
  }

  Future<void> moveCursorLeft() async {
    await _channel.invokeMethod(
        'moveCursor', {'instanceId': _instanceId, 'direction': 'left'});
  }

  Future<void> moveCursorRight() async {
    await _channel.invokeMethod(
        'moveCursor', {'instanceId': _instanceId, 'direction': 'right'});
  }

  Future<void> setObscureText(bool obscure) async {
    // Update internal state
    setState(() {
      // We don't actually store obscureText here, just forward to native
    });

    // Call native method
    await _channel.invokeMethod('setObscureText', {
      'instanceId': _instanceId,
      'obscureText': obscure,
    });
  }

  @override
  void dispose() {
    _instances.remove(_instanceId);
    if (_instances.isEmpty) _channel.setMethodCallHandler(null);
    _controller.removeListener(_onControllerTextChanged);
    if (_isControllerCreated) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic> creationParams = {
      'instanceId': _instanceId,
      'hint': widget.hint,
      'initialText': widget.initialText,
      'obscureText': widget.obscureText,
      'maxLines': widget.maxLines,
      'backgroundColor': widget.backgroundColor.value,
      'textColor': widget.textColor.value,
    };

    Widget child = AndroidView(
      viewType: 'native_textfield_tv',
      onPlatformViewCreated: _onPlatformViewCreated,
      creationParams: creationParams,
      creationParamsCodec: const StandardMessageCodec(),
    );

    if (widget.width != null || widget.height != null) {
      return SizedBox(width: widget.width, height: widget.height, child: child);
    }
    return child;
  }

  void _onPlatformViewCreated(int id) {
    if (_controller.text.isNotEmpty && _controller.text != widget.initialText)
      _syncToNative();
  }
}

/// DPAD constants
const String keyUp = 'Arrow Up';
const String keyDown = 'Arrow Down';
const String keyLeft = 'Arrow Left';
const String keyRight = 'Arrow Right';
const String keyCenter = 'Select';
const String goBack = 'Go Back';

/// DPAD NativeTextField with eye toggle
class AndroidTVTextField extends StatefulWidget {
  final FocusNode focusNode;
  final NativeTextFieldController controller;
  final double height;
  final bool obscureText;
  final String? hint;
  final int? maxLines;
  final Color backgroundColor;
  final Color textColor;
  final Color focuesedBorderColor;
  final Color unFocuesedBorderColor;

  final bool showPasswordToggle;
  final ValueChanged<String>? onSubmitted;
  final Widget? postFixWidget;

  const AndroidTVTextField(
      {super.key,
      required this.focusNode,
      required this.controller,
      this.height = 60,
      this.obscureText = false,
      this.hint,
      this.maxLines = 1,
      this.showPasswordToggle = false,
      this.backgroundColor = Colors.black,
      this.textColor = Colors.white,
      this.onSubmitted,
      this.focuesedBorderColor = Colors.transparent,
      this.unFocuesedBorderColor = Colors.transparent,
      this.postFixWidget});

  @override
  State<AndroidTVTextField> createState() => _DpadNativeTextFieldState();
}

class _DpadNativeTextFieldState extends State<AndroidTVTextField> {
  final GlobalKey<_NativeTextFieldState> _nativeTextFieldKey =
      GlobalKey<_NativeTextFieldState>();

  @override
  void initState() {
    super.initState();

    widget.focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (mounted) {
      setState(() {
        if (widget.focusNode.hasFocus) {
          _nativeTextFieldKey.currentState?.requestFocus();
        } else {
          _nativeTextFieldKey.currentState?.clearFocus();
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
    return KeyboardListener(
      focusNode: widget.focusNode,
      onKeyEvent: (event) {
        if (event is KeyUpEvent) {
          switch (event.logicalKey.keyLabel) {
            case keyLeft:
              _nativeTextFieldKey.currentState?.moveCursorLeft();
              break;
            case keyRight:
              _nativeTextFieldKey.currentState?.moveCursorRight();
              break;
          }
        }
      },
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Builder(builder: (context) {
            return Container(
              height: widget.height,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: widget.backgroundColor,
                border: Border.all(
                  color:
                      widget.focusNode.hasFocus ? Colors.green : Colors.amber,
                  width: 1,
                ),
              ),
              padding: EdgeInsets.only(
                  left: 5,
                  right: widget.postFixWidget == null ? 5 : 50,
                  top: 5,
                  bottom: 5),
              child: NativeTextField(
                key: _nativeTextFieldKey,
                controller: widget.controller,
                width: double.infinity,
                height: widget.height,
                obscureText: widget.obscureText,
                hint: widget.hint,
                maxLines: widget.maxLines,
                backgroundColor: widget.backgroundColor,
                textColor: widget.textColor,
                onSubmitted: widget.onSubmitted,
              ),
            );
          }),
          Positioned(right: 10, child: widget.postFixWidget ?? SizedBox()),
        ],
      ),
    );
  }
}
