import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/style/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pure_live/common/widgets/highlight_widget.dart';

class HighlightButton extends StatelessWidget {
  final String text;
  final IconData? iconData;
  final Widget? icon;
  final AppFocusNode focusNode;
  final Function()? onTap;
  final bool autofocus;
  final bool selected;
  final bool useFocus;
  const HighlightButton({
    this.iconData,
    required this.text,
    this.icon,
    this.onTap,
    required this.focusNode,
    this.autofocus = false,
    this.selected = false,
    this.useFocus = true,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => HighlightWidget(
        focusNode: focusNode,
        borderRadius: AppStyle.radius32,
        color: Colors.white10,
        onTap: onTap,
        autofocus: autofocus,
        selected: selected,
        useFocus: useFocus,
        child: Container(
          height: 64.w,
          //width: 64.w,
          padding: AppStyle.edgeInsetsH24,
          decoration: BoxDecoration(
            borderRadius: AppStyle.radius32,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              buildIcon(),
              Text(
                text,
                style: TextStyle(
                  fontSize: 28.w,
                  color: useFocus
                      ? (focusNode.isFoucsed.value || selected ? Colors.black : Colors.white)
                      : selected
                          ? Colors.black
                          : Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildIcon() {
    if (icon != null || iconData != null) {
      return Padding(
        padding: AppStyle.edgeInsetsR12,
        child: icon ??
            Icon(
              iconData,
              size: 40.w,
              color: (focusNode.isFoucsed.value || selected) ? Colors.black : Colors.white,
            ),
      );
    }
    return const SizedBox();
  }
}
