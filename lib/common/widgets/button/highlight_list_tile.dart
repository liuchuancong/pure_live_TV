import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/app/app_focus_node.dart';
import 'package:pure_live/common/style/index.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:pure_live/common/widgets/highlight_widget.dart';

class HighlightListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final AppFocusNode focusNode;
  final Function()? onTap;
  final bool autofocus;
  final bool selected;
  final bool useFocus;
  const HighlightListTile({
    this.subtitle,
    required this.title,
    this.leading,
    this.onTap,
    required this.focusNode,
    this.autofocus = false,
    this.useFocus = true,
    this.selected = false,
    this.trailing,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => IconTheme(
        data: IconThemeData(
          color: focusNode.isFoucsed.value ? Colors.black : Colors.white,
        ),
        child: useFocus
            ? HighlightWidget(
                onTap: onTap,
                autofocus: autofocus,
                focusNode: focusNode,
                useFocus: useFocus,
                selected: selected,
                borderRadius: AppStyle.radius16,
                child: Padding(
                  padding: AppStyle.edgeInsetsA24,
                  child: Row(
                    children: [
                      if (leading != null) leading!,
                      if (leading != null) AppStyle.hGap32,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: focusNode.isFoucsed.value ? AppStyle.textStyleBlack : AppStyle.textStyleWhite,
                              maxLines: 2,
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: focusNode.isFoucsed.value
                                    ? AppStyle.textStyleBlack.copyWith(fontSize: 24.w)
                                    : AppStyle.textStyleWhite.copyWith(fontSize: 24.w),
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                      AppStyle.hGap12,
                      if (onTap != null && focusNode.isFoucsed.value && trailing == null)
                        Icon(
                          Icons.chevron_right,
                          size: 40.w,
                          color: focusNode.isFoucsed.value ? Colors.black : Colors.white,
                        ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
              )
            : HighlightWidget(
                onTap: onTap,
                autofocus: false,
                focusNode: focusNode,
                useFocus: useFocus,
                selected: selected,
                borderRadius: AppStyle.radius16,
                child: Padding(
                  padding: AppStyle.edgeInsetsA24,
                  child: Row(
                    children: [
                      if (leading != null) leading!,
                      if (leading != null) AppStyle.hGap32,
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              title,
                              style: selected ? AppStyle.textStyleBlack : AppStyle.textStyleWhite,
                              maxLines: 2,
                            ),
                            if (subtitle != null)
                              Text(
                                subtitle!,
                                style: selected
                                    ? AppStyle.textStyleBlack.copyWith(fontSize: 24.w)
                                    : AppStyle.textStyleWhite.copyWith(fontSize: 24.w),
                                maxLines: 1,
                              ),
                          ],
                        ),
                      ),
                      AppStyle.hGap12,
                      if (onTap != null && selected && trailing == null)
                        Icon(
                          Icons.chevron_right,
                          size: 40.w,
                          color: selected ? Colors.black : Colors.white,
                        ),
                      if (trailing != null) trailing!,
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
