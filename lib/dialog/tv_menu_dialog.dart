import 'tv_dialog.dart';
import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/routes/extensions.dart';
import 'package:pure_live/widgets/tv_button.dart';

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

  const TvMenuDialog({super.key, required this.title, required this.items, this.selectedValue});

  @override
  Widget build(BuildContext context) {
    return TvDialog(
      title: title,
      child: SizedBox(
        width: 600,
        height: 500,
        child: DpadRegion(
          horizontalEdge: DpadEdgeBehavior.stop,
          verticalEdge: DpadEdgeBehavior.stop,
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 12),
            itemBuilder: (_, index) {
              final item = items[index];
              final selected = item.value == selectedValue;

              return TvButton(
                autofocus: selected,
                title: item.title,
                icon: selected ? const Icon(Icons.check_circle) : item.leading ?? item.trailing,
                iconPosition: selected || item.trailing != null ? TvIconPosition.right : TvIconPosition.left,
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
