import 'tv_dialog.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/routes/extensions.dart';
import 'package:pure_live/widgets/tv_button.dart';

class TvSelectItem<T> {
  final String title;
  final T value;
  final Widget? leading;

  const TvSelectItem({required this.title, required this.value, this.leading});
}

class TvSelectDialog<T> extends StatefulWidget {
  final String title;
  final List<TvSelectItem<T>> items;
  final T? selectedValue;

  const TvSelectDialog({super.key, required this.title, required this.items, this.selectedValue});

  @override
  State<TvSelectDialog<T>> createState() => _TvSelectDialogState<T>();
}

class _TvSelectDialogState<T> extends State<TvSelectDialog<T>> {
  late final ScrollController _scrollController;
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    selectedIndex = widget.items.indexWhere((e) => e.value == widget.selectedValue);
    if (selectedIndex < 0) {
      selectedIndex = 0;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelected();
    });
  }

  void _scrollToSelected() {
    if (!_scrollController.hasClients) return;
    final offset = selectedIndex * 72.0;
    _scrollController.jumpTo(offset.clamp(0, _scrollController.position.maxScrollExtent));
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: widget.title,
      child: SizedBox(
        width: 520,
        height: 500,
        child: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.stop,
          verticalEdge: DpadEdgeBehavior.stop,
          child: ListView.separated(
            controller: _scrollController,
            itemCount: widget.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final item = widget.items[index];
              final isSelected = index == selectedIndex;

              return TvButton(
                autofocus: isSelected,
                title: item.title,
                icon: isSelected ? const Icon(Icons.check_rounded) : item.leading,
                iconPosition: isSelected ? TvIconPosition.right : TvIconPosition.left,
                onTap: () {
                  context.closeDialog(item.value);
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
