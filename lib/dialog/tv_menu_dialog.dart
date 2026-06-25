import 'tv_dialog.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/widgets/tv_button.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';

class TvMenuItem<T> {
  final String title;
  final T value;
  final Widget? leading;
  final Widget? trailing;

  const TvMenuItem({required this.title, required this.value, this.leading, this.trailing});
}

class TvMenuDialog<T> extends StatelessWidget {
  final String title;
  final List<TvMenuItem<T>> items;
  final T? selectedValue;
  final ValueChanged<T>? onSelected;

  const TvMenuDialog({super.key, required this.title, required this.items, this.selectedValue, this.onSelected});

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: title,
      child: Container(
        constraints: BoxConstraints(maxHeight: 500.sp),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: items.length,
          separatorBuilder: (_, _) => SizedBox(height: 12.sp),
          itemBuilder: (_, index) {
            final item = items[index];
            final selected = item.value == selectedValue;

            return TvButton(
              autofocus: selected,
              isSecondary: !selected,
              title: item.title,
              icon: selected ? const Icon(Icons.check_circle_rounded) : (item.leading ?? item.trailing),
              iconPosition: (selected || item.trailing != null) ? TvIconPosition.right : TvIconPosition.left,
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
