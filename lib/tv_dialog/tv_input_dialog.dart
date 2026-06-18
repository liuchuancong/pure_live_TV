import 'tv_dialog.dart';
import 'package:dpad/dpad.dart';
import 'package:pure_live/common/index.dart';
import 'package:pure_live/widgets/tv_button.dart';

class TvInputDialog extends StatefulWidget {
  final String title;
  final String? hintText;
  final String? initialValue;
  final int? maxLength;

  const TvInputDialog({super.key, required this.title, this.hintText, this.initialValue, this.maxLength});

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
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit() {
    Get.back(result: _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: widget.title,
      child: SizedBox(
        width: 700,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              focusNode: _focusNode,
              maxLength: widget.maxLength,
              autofocus: true,
              decoration: InputDecoration(hintText: widget.hintText),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 32),
            DpadRegion(
              horizontalEdge: DpadEdgeBehavior.stop,
              verticalEdge: DpadEdgeBehavior.stop,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  SizedBox(
                    width: 140,
                    child: TvButton(title: '取消', onTap: () => Get.back()),
                  ),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 140,
                    child: TvButton(title: '确定', onTap: _submit),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
