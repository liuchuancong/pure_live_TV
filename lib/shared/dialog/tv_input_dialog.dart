import 'package:pure_live/exports/exports.dart';
import 'package:tv_textfield/tv_textfield.dart';

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
      if (!mounted) return;
      _focusNode.requestFocus();
      // A dialog exists to be typed into, so the field goes straight into
      // editing instead of waiting for another OK. `TvTextField` enters editing
      // from its own key handler, which is also what the remote's OK reaches,
      // so the dialog calls exactly that handler.
      final FocusOnKeyEventCallback? onKey = _focusNode.onKeyEvent;
      onKey?.call(
        _focusNode,
        const KeyDownEvent(
          physicalKey: PhysicalKeyboardKey.select,
          logicalKey: LogicalKeyboardKey.select,
          timeStamp: Duration.zero,
        ),
      );
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
      confirmText: i18n('exit_yes'),
      cancelText: i18n('cancel'),
      onConfirm: _submit,
      onCancel: () => Navigator.of(context).pop(),
      child: TvTextField(
        controller: _controller,
        focusNode: _focusNode,
        maxLength: widget.maxLength,
        style: TextStyle(color: tvTheme.primaryTextColor, fontSize: 26.sp),
        // Same choice as TvInputField: the Flutter backend, so the dialog keeps
        // the app's palette instead of a native EditText platform view.
        implementation: TvTextFieldImplementation.flutter,
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
