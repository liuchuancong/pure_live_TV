import 'tv_dialog.dart';
import 'tv_dialog_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

/// One toggleable row of [TvMultiSelectDialog].
class TvMultiSelectItem<T> {
  const TvMultiSelectItem({required this.title, required this.value, this.subtitle});

  final String title;
  final T value;
  final String? subtitle;
}

/// Dialog that toggles several values and returns the confirmed selection.
///
/// The rows keep a local pending selection so a remote user can switch several
/// entries before confirming; closing with cancel returns null.
class TvMultiSelectDialog<T> extends StatefulWidget {
  const TvMultiSelectDialog({
    super.key,
    required this.title,
    required this.items,
    required this.initialSelection,
    this.emptyHint,
  });

  final String title;
  final List<TvMultiSelectItem<T>> items;
  final Set<T> initialSelection;

  /// Shown instead of the list when there is nothing to select.
  final String? emptyHint;

  @override
  State<TvMultiSelectDialog<T>> createState() => _TvMultiSelectDialogState<T>();
}

class _TvMultiSelectDialogState<T> extends State<TvMultiSelectDialog<T>> {
  late final Set<T> _selection;
  final ScrollController _scrollController = ScrollController();

  /// The row the dialog opens on.
  ///
  /// Handed the focus explicitly, like [TvSelectDialog] does: without it the
  /// remote lands on the dialog's own close button, and the list has no visible
  /// highlight until the viewer finds it.
  final FocusNode _firstNode = FocusNode(debugLabel: 'tv-multi-select/first');

  @override
  void initState() {
    super.initState();
    _selection = Set<T>.from(widget.initialSelection);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _firstNode.dispose();
    super.dispose();
  }

  void _toggle(T value) {
    setState(() {
      if (!_selection.remove(value)) _selection.add(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    final hasItems = widget.items.isNotEmpty;

    return TvDialog(
      title: widget.title,
      confirmText: i18n('done'),
      cancelText: i18n('cancel'),
      initialFocusNode: hasItems ? _firstNode : null,
      onConfirm: () => Navigator.of(context).pop(_selection),
      onCancel: () => Navigator.of(context).pop(),
      child: hasItems
          ? Container(
              constraints: BoxConstraints(maxHeight: 500.sp),
              child: ListView.separated(
                controller: _scrollController,
                shrinkWrap: true,
                padding: EdgeInsets.symmetric(vertical: 2.sp),
                itemCount: widget.items.length,
                separatorBuilder: (_, _) => SizedBox(height: 12.sp),
                itemBuilder: (_, index) {
                  final item = widget.items[index];
                  final selected = _selection.contains(item.value);

                  return TvDialogOptionTile(
                    title: item.title,
                    subtitle: item.subtitle,
                    // The tick is the row's own mark (the circle below), never
                    // `selected`: that flag paints the tile with the highlight of
                    // the value in force, so ticking several rows — the default
                    // here — filled the whole list with the same accent colour and
                    // the focus cursor had nothing left to stand out with.
                    selected: false,
                    icon: Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined),
                    // The circle above is this list's own state mark.
                    showCheck: false,
                    autofocus: index == 0,
                    focusNode: index == 0 ? _firstNode : null,
                    onTap: () => _toggle(item.value),
                  );
                },
              ),
            )
          : Text(
              widget.emptyHint ?? i18n('no_data'),
              style: TextStyle(color: tvTheme.secondaryTextColor, fontSize: 24.sp),
            ),
    );
  }
}
