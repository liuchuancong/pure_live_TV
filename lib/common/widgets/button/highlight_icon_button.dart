import 'package:flutter/material.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pure_live/common/widgets/highlight_widget.dart';

class HighlightIconButton extends StatelessWidget {
  final IconData? iconData;
  final Widget? icon;
  final AppFocusNode focusNode;
  final Function()? onTap;
  final bool autofocus;
  final bool selected;
  final bool useFocus;
  const HighlightIconButton({
    required this.iconData,
    this.icon,
    this.onTap,
    required this.focusNode,
    this.autofocus = false,
    this.selected = false,
    super.key,
    this.useFocus = true,
  });
  @override
  Widget build(BuildContext context) {
    return HighlightWidget(
      focusNode: focusNode,
      onTap: onTap,
      autofocus: autofocus,
      selected: selected,
      child: buildIcon(),
    );
  }

  Widget buildIcon() {
    if (icon != null || iconData != null) {
      return icon ??
          Icon(
            iconData,
            size: 60.w,
            color: useFocus
                ? (focusNode.isFoucsed.value || selected ? Colors.white : Colors.black)
                : selected
                    ? Colors.black
                    : Colors.white,
          );
    }
    return const SizedBox();
  }
}
