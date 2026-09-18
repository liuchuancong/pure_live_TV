import 'tv_dialog.dart';
import 'tv_dialog_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvSelectItem<T> {
  final String title;
  final T value;
  final Widget? leading;

  /// Second line of the row, for entries whose label alone is not enough.
  final String? subtitle;

  const TvSelectItem({required this.title, required this.value, this.leading, this.subtitle});
}

/// Dialog that returns the chosen value, or null when it is closed.
///
/// The rows are [TvDialogOptionTile]s (rounded rectangles), the value in force is
/// marked, and the dialog carries its own close button — every dialog in the app
/// has a visible way out, so closing one never depends on knowing that the
/// remote's Back button works.
class TvSelectDialog<T> extends StatefulWidget {
  final String title;
  final List<TvSelectItem<T>> items;
  final T? selectedValue;

  /// Called with the chosen value as well as returning it from the dialog.
  final ValueChanged<T>? onSelected;

  const TvSelectDialog({super.key, required this.title, required this.items, this.selectedValue, this.onSelected});

  @override
  State<TvSelectDialog<T>> createState() => _TvSelectDialogState<T>();
}

class _TvSelectDialogState<T> extends State<TvSelectDialog<T>> {
  late final ScrollController _scrollController;

  /// The row holding the value in force. Handed focus explicitly once the list
  /// has scrolled to it, so opening the dialog can never leave the highlight on
  /// the dialog's close button (which is where every option-row dialog used to
  /// land on a real remote).
  final FocusNode _selectedNode = FocusNode(debugLabel: 'tv-select/selected');

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
    final itemHeight = 72.sp;
    final offset = selectedIndex * itemHeight;
    _scrollController.jumpTo(offset.clamp(0, _scrollController.position.maxScrollExtent));
    if (_selectedNode.canRequestFocus) _selectedNode.requestFocus();
    // After a jump the selected row may only be built one frame later (lazy
    // list); the guard's initialFocusNode retry covers that window, and this
    // extra attempt shortens it for the common case.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_selectedNode.hasFocus && _selectedNode.context?.mounted == true) {
        _selectedNode.requestFocus();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _selectedNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: widget.title,
      cancelText: i18n('close'),
      onCancel: () => Navigator.of(context).pop(),
      initialFocusNode: _selectedNode,
      child: Container(
        constraints: BoxConstraints(maxHeight: 500.sp),
        child: ListView.separated(
          controller: _scrollController,
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(vertical: 2.sp),
          itemCount: widget.items.length,
          separatorBuilder: (_, _) => SizedBox(height: 12.sp),
          itemBuilder: (_, index) {
            final item = widget.items[index];
            final isSelected = index == selectedIndex;

            return TvDialogOptionTile(
              title: item.title,
              subtitle: item.subtitle,
              icon: item.leading,
              selected: isSelected,
              autofocus: isSelected,
              focusNode: isSelected ? _selectedNode : null,
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
