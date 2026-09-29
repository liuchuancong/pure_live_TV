import 'package:pure_live/exports/exports.dart';

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
      // editing instead of waiting for another OK: the field's own key handler
      // is what the remote's OK reaches, so the dialog calls exactly that.
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
      // TvInputField, not a bare field: it brings the app palette and the
      // TV key handling (arrows walk the layout until OK starts editing).
      child: TvInputField(
        controller: _controller,
        focusNode: _focusNode,
        hint: widget.hintText,
        maxLength: widget.maxLength,
        height: 56.sp,
        textColor: tvTheme.primaryTextColor,
        backgroundColor: tvTheme.cardColor.withAlpha(120),
        onSubmitted: (_) => _submit(),
      ),
    );
  }
}
