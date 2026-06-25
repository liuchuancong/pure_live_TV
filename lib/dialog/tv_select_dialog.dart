import 'tv_dialog.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

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
  final ValueChanged<T>? onSelected;

  const TvSelectDialog({super.key, required this.title, required this.items, this.selectedValue, this.onSelected});

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
    final itemHeight = 64.w + 12.sp;
    final offset = selectedIndex * itemHeight;
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
      child: Container(
        constraints: BoxConstraints(maxHeight: 500.sp),
        child: ListView.separated(
          controller: _scrollController,
          shrinkWrap: true,
          itemCount: widget.items.length,
          separatorBuilder: (_, _) => SizedBox(height: 12.sp),
          itemBuilder: (_, index) {
            final item = widget.items[index];
            final isSelected = index == selectedIndex;

            return TvButton(
              autofocus: isSelected,
              isSecondary: !isSelected,
              title: item.title,
              icon: isSelected ? const Icon(Icons.check_rounded) : item.leading,
              iconPosition: isSelected ? TvIconPosition.right : TvIconPosition.left,
              onTap: () {
                Navigator.of(context).pop(item.value);
                widget.onSelected?.call(item.value);
              },
            );
          },
        ),
      ),
    );
  }
}
