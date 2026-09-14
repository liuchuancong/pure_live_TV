import 'tv_dialog.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/theme/tv_theme_x.dart';
import 'package:pure_live/shared/widgets/tv_button.dart';
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

  @override
  void initState() {
    super.initState();
    _selection = Set<T>.from(widget.initialSelection);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
      onConfirm: () => Navigator.of(context).pop(_selection),
      onCancel: () => Navigator.of(context).pop(),
      child: hasItems
          ? Container(
              constraints: BoxConstraints(maxHeight: 500.sp),
              child: ListView.separated(
                controller: _scrollController,
                shrinkWrap: true,
                itemCount: widget.items.length,
                separatorBuilder: (_, _) => SizedBox(height: 12.sp),
                itemBuilder: (_, index) {
                  final item = widget.items[index];
                  final selected = _selection.contains(item.value);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TvButton(
                        isSecondary: !selected,
                        title: item.title,
                        icon: Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined),
                        iconPosition: TvIconPosition.left,
                        onTap: () => _toggle(item.value),
                      ),
                      if (item.subtitle != null && item.subtitle!.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(left: 16.sp, top: 4.sp),
                          child: Text(
                            item.subtitle!,
                            style: TextStyle(color: tvTheme.secondaryTextColor, fontSize: 20.sp),
                          ),
                        ),
                    ],
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
