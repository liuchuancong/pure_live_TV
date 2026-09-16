import 'tv_dialog.dart';
import 'tv_dialog_option_tile.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvMenuItem<T> {
  final String title;
  final T value;
  final Widget? leading;
  final Widget? trailing;

  /// Second line of the row.
  final String? subtitle;

  const TvMenuItem({required this.title, required this.value, this.leading, this.trailing, this.subtitle});
}

/// Dialog that runs an action for the chosen entry and returns its value.
///
/// Like [TvSelectDialog] the rows are rounded [TvDialogOptionTile]s and the
/// dialog has its own 关闭 button.
class TvMenuDialog<T> extends StatelessWidget {
  final String title;
  final List<TvMenuItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T>? onSelected;

  const TvMenuDialog({
    super.key,
    required this.title,
    required this.items,
    this.selectedValue,
    this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: title,
      cancelText: i18n('close'),
      onCancel: () => Navigator.of(context).pop(),
      child: Container(
        constraints: BoxConstraints(maxHeight: 500.sp),
        child: ListView.separated(
          shrinkWrap: true,
          padding: EdgeInsets.symmetric(vertical: 2.sp),
          itemCount: items.length,
          separatorBuilder: (_, _) => SizedBox(height: 12.sp),
          itemBuilder: (_, index) {
            final item = items[index];
            final selected = item.value == selectedValue;

            return TvDialogOptionTile(
              title: item.title,
              subtitle: item.subtitle,
              icon: item.leading,
              trailing: item.trailing,
              selected: selected,
              autofocus: selected || (selectedValue == null && index == 0),
              onTap: () {
                Navigator.of(context).pop(item.value);
                onSelected?.call(item.value);
              },
            );
          },
        ),
      ),
    );
  }
}
